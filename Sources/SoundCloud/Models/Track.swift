//
//  Track.swift
//  Nuage
//
//  Created by Laurin Brandner on 22.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation
import Combine

public struct Track: SoundCloudIdentifiable, Encodable, Decodable {
    
    public var id: String
    public var urn: String { "soundcloud:tracks:\(id)" }
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var waveformURL: URL
    public var streamURL: URL?
    public var permalinkURL: URL
    public var duration: Float
    public var playbackCount: Int
    public var likeCount: Int
    public var repostCount: Int
    public var date: Date
    public var user: User
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case waveformURL = "waveform_url"
        case streamURL = "stream_url"
        case permalinkURL = "permalink_url"
        case media
        case duration
        case playbackCount = "playback_count"
        case likeCount = "likes_count"
        case repostCount = "reposts_count"
        case date = "created_at"
        case user
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // SoundCloud's API uses Int, Nuage encodes a String
        if let rawID = try? container.decode(Int.self, forKey: .id) {
            id = String(rawID)
        }
        else {
            id = try container.decode(String.self, forKey: .id)
        }
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        waveformURL = try container.decode(URL.self, forKey: .waveformURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        
        if container.contains(.media) {
            // API format: the stream is one of the transcodings, durations are in milliseconds
            let media = try container.decode([String: Any].self, forKey: .media)
            let transcodings = media["transcodings"] as? [[String: Any]] ?? []
            if let file = audioFile(from: transcodings) {
                streamURL = (file["url"] as? String).flatMap(URL.init(string:))
                duration = Float(file["duration"] as? Int ?? 0)/1000
            }
            else {
                duration = 0
            }
        }
        else {
            // Format written by `encode(to:)`: the stream URL is stored directly, the duration is in seconds
            streamURL = try container.decodeIfPresent(URL.self, forKey: .streamURL)
            duration = try container.decode(Float.self, forKey: .duration)
        }
        playbackCount = try container.decodeIfPresent(Int.self, forKey: .playbackCount) ?? 0
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        repostCount = try container.decodeIfPresent(Int.self, forKey: .repostCount) ?? 0
        date = try container.decode(Date.self, forKey: .date)
        user = try container.decode(User.self, forKey: .user)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encode(waveformURL, forKey: .waveformURL)
        try container.encodeIfPresent(streamURL, forKey: .streamURL)
        try container.encode(permalinkURL, forKey: .permalinkURL)
        try container.encode(duration, forKey: .duration)
        try container.encode(playbackCount, forKey: .playbackCount)
        try container.encode(likeCount, forKey: .likeCount)
        try container.encode(repostCount, forKey: .repostCount)
        try container.encode(date, forKey: .date)
        try container.encode(user, forKey: .user)
    }
    
}

private func audioFile(from transcodings: [[String: Any]]) -> [String: Any]? {
    func isFormatProgressive(from transcoding: [String: Any]) -> Bool {
        guard let format = transcoding["format"] as? [String: Any] else { return false }
        
        return format["protocol"] as? String == "progressive"
    }
    
    func quality(of transcoding: [String: Any]) -> String? {
        return transcoding["quality"] as? String
    }
    
    let hqFileProgressive = transcodings.first { quality(of: $0) == "hq" && isFormatProgressive(from: $0) }
    let sqFileProgressive = transcodings.first { quality(of: $0) == "sq" && isFormatProgressive(from: $0) }

    let hqFile = transcodings.first { quality(of: $0) == "hq" }
    let sqFile = transcodings.first { quality(of: $0) == "sq" }
    
    return hqFileProgressive ?? sqFileProgressive ?? hqFile ?? sqFile
}
