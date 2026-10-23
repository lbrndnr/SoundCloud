//
//  UserPlaylist.swift
//  Nuage
//
//  Created by Laurin Brandner on 02.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public struct UserPlaylist: Playlist {
    
    public var id: String
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var permalinkURL: URL
    public var isPublic: Bool
    public var user: User
    
    public var tracks: [Track]?
    public var trackIDs: [String]?
    
    public var secretToken: String?
    public var isAlbum: Bool
    public var date: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case permalinkURL = "permalink_url"
        case isPublic = "public"
        case isPublic2 = "is_public"
        case tracks
        case user
        case secretToken = "secret_token"
        case isAlbum = "is_album"
        case date = "created_at"
        case kind
        case trackIDs = "track_ids"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let intID = try? container.decode(Int.self, forKey: .id)
        let stringID = try? container.decode(String.self, forKey: .id)
        id = (intID.map(String.init) ?? stringID)!
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        
        let rawIsPublic = try? container.decode(Bool.self, forKey: .isPublic)
        let rawIsPublic2 = try? container.decode(Bool.self, forKey: .isPublic2)
        isPublic = (rawIsPublic ?? rawIsPublic2)!
        
        user = try container.decode(User.self, forKey: .user)
        
        if container.contains(.tracks) {
            do {
                let tracks = try container.decode([Track].self, forKey: .tracks)
                self.tracks = tracks
                self.trackIDs = tracks.map { $0.id }
            }
            catch {
                // Only some of the tracks are complete, the others merely contain their id
                if let tracks = try container.decode([Any].self, forKey: .tracks) as? [[String : Any]] {
                    self.trackIDs = tracks.compactMap { $0["id"].map { "\($0)" } }
                }
            }
        }
        // Written by `encode(to:)`, takes precedence since `tracks` may only be a prefix
        if let trackIDs = try? container.decodeIfPresent([String].self, forKey: .trackIDs) {
            self.trackIDs = trackIDs
        }
        
        isAlbum = try container.decode(Bool.self, forKey: .isAlbum)
        secretToken = try container.decodeIfPresent(String.self, forKey: .secretToken)
        date = try container.decode(Date.self, forKey: .date)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode("playlist", forKey: .kind)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encode(permalinkURL, forKey: .permalinkURL)
        try container.encode(isPublic, forKey: .isPublic)
        try container.encode(user, forKey: .user)
        
        try container.encode(isAlbum, forKey: .isAlbum)
        try container.encode(secretToken, forKey: .secretToken)
        try container.encode(date, forKey: .date)
        
        try container.encodeIfPresent(tracks, forKey: .tracks)
        try container.encodeIfPresent(trackIDs, forKey: .trackIDs)
    }
    
    public func eraseToAnyPlaylist() -> AnyPlaylist {
        return .user(self)
    }
    
}
