//
//  Playlist.swift
//  Nuage
//
//  Created by Laurin Brandner on 02.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public struct Playlist: SoundCloudIdentifiable {
    
    public var id: Int
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var permalinkURL: URL
    public var isPublic: Bool
    public var secretToken: String?
    public var isAlbum: Bool
    public var date: Date
    
    /// For some requests, 5 full tracks are sent along.
    /// Their ids are a prefix of `trackIDs`
    public var tracks: [Track]?
    public var trackIDs: [Int]?
    
}

extension Playlist: Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case permalinkURL = "permalink_url"
        case isPublic = "public"
        case secretToken = "secret_token"
        case tracks
        case isAlbum = "is_album"
        case date = "created_at"
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
        date = try container.decode(Date.self, forKey: .date)
        secretToken = try container.decodeIfPresent(String.self, forKey: .secretToken)
        
        if container.contains(.tracks) {
            do {
                let tracks = try container.decode([Track].self, forKey: .tracks)
                self.tracks = tracks
                self.trackIDs = tracks.map { $0.id }
            }
            catch {
                if let tracks = try container.decode([Any].self, forKey: .tracks) as? [[String : Any]] {
                    let ids = tracks.map { $0["id"] as! Int }
                    self.trackIDs = ids
                }
            }
        }
    }
    
}
