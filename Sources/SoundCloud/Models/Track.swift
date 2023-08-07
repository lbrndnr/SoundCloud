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
        
        let rawID = try container.decode(Int.self, forKey: .id)
        id = String(rawID)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        waveformURL = try container.decode(URL.self, forKey: .waveformURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        
        let media: [String: [[String: Any]]] = try container.decode([String: Any].self, forKey: .media) as! [String : [[String : Any]]]
        let transcodings = media["transcodings"]!
        if let file = audioFile(from: transcodings) {
            streamURL = URL(string: file["url"] as! String)!
            duration = Float(file["duration"]! as! Int)/1000
        }
        else {
            duration = 0
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
        try container.encode(streamURL, forKey: .streamURL)
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
    func isFormatProgressive(from trasncoding: [String: Any]) -> Bool {
        guard let formatProtocol = trasncoding["format"] as? [String: String] else { return false }
        
        return formatProtocol["protocol"] == "progressive"
    }
    
    let hqFileProgressive = transcodings.filter { ($0["quality"] as! String) == "hq" && isFormatProgressive(from: $0) }
        .first
    let sqFileProgressive = transcodings.filter { ($0["quality"] as! String) == "sq" && isFormatProgressive(from: $0) }
        .first

    let hqFile = transcodings.filter { ($0["quality"] as! String) == "hq" }
        .first
    let sqFile = transcodings.filter { ($0["quality"] as! String) == "sq" }
        .first
    
    return hqFileProgressive ?? sqFileProgressive ?? hqFile ?? sqFile
}
