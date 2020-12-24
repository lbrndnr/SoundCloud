//
//  Track.swift
//  Nuage
//
//  Created by Laurin Brandner on 22.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct Track: SoundCloudIdentifiable {
    
    public var id: Int
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var streamURL: URL
    public var permalinkURL: URL
    public var duration: Float
    public var playbackCount: Int
    public var likeCount: Int
    public var repostCount: Int
    
}

private func audioFile(from transcodings: [[String: Any]]) -> [String: Any] {
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
    
    return (hqFileProgressive ?? sqFileProgressive ?? hqFile ?? sqFile)!
}

extension Track: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case permalinkURL = "permalink_url"
        case media
        case playbackCount = "playback_count"
        case likeCount = "likes_count"
        case repostCount = "reposts_count"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        
        let media: [String: [[String: Any]]] = try container.decode([String: Any].self, forKey: .media) as! [String : [[String : Any]]]
        let transcodings = media["transcodings"]!
        let file = audioFile(from: transcodings)
        
        streamURL = URL(string: file["url"] as! String)!
        duration = Float(file["duration"]! as! Int)/1000
        playbackCount = try container.decodeIfPresent(Int.self, forKey: .playbackCount) ?? 0
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        repostCount = try container.decodeIfPresent(Int.self, forKey: .repostCount) ?? 0
    }
    
}

extension Track: Filterable {
    
    func contains(_ text: String) -> Bool {
        return title.contains(text) || (description?.contains(text) ?? false)
    }
    
}
