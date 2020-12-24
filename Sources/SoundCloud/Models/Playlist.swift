//
//  Playlist.swift
//  Nuage
//
//  Created by Laurin Brandner on 02.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public enum Tracks {
    case id([Int])
    case full([Track])
}

public struct Playlist: SoundCloudIdentifiable {
    
    public var id: Int
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var permalinkURL: URL
    public var tracks: Tracks?
    public var isPublic: Bool
    public var isAlbum: Bool
    
    public var trackIDs: [Int]? {
        switch tracks {
        case .full(let tracks): return tracks.map { $0.id }
        case .id(let ids): return ids
        case .none: return nil
        }
    }
    
}

extension Playlist: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case permalinkURL = "permalink_url"
        case isPublic = "public"
        case tracks
        case isAlbum = "is_album"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        isPublic = try container.decode(Bool.self, forKey: .isPublic)
        isAlbum = try container.decode(Bool.self, forKey: .isAlbum)
        
        if container.contains(.tracks) {
            do {
                let tracks = try container.decode([Track].self, forKey: .tracks)
                self.tracks = .full(tracks)
            }
            catch {
                if let tracks = try container.decode([Any].self, forKey: .tracks) as? [[String : Any]] {
                    let ids = tracks.map { $0["id"] as! Int }
                    self.tracks = .id(ids)
                }
            }
        }
    }
    
}
