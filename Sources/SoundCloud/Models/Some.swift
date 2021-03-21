//
//  Some.swift
//  
//
//  Created by Laurin Brandner on 24.12.20.
//

import Foundation

public struct UnknownKindError: Error {
    
    var kind: String
    
}

public enum Some: SoundCloudIdentifiable {
    case user(User)
    case track(Track)
    case userPlaylist(UserPlaylist)
    case systemPlaylist(SystemPlaylist)
    
    public var id: String {
        switch self {
        case .user(let user): return user.id
        case .track(let track): return track.id
        case .userPlaylist(let playlist): return playlist.id
        case .systemPlaylist(let playlist): return playlist.id
        }
    }
    
}

extension Some: Decodable {

    enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        
        if kind == "user" {
            let user = try User(from: decoder)
            self = .user(user)
        }
        else if kind == "track" {
            let track = try Track(from: decoder)
            self = .track(track)
        }
        else if kind == "playlist" {
            let playlist = try UserPlaylist(from: decoder)
            self = .userPlaylist(playlist)
        }
        else if kind == "system-playlist" {
            let playlist = try SystemPlaylist(from: decoder)
            self = .systemPlaylist(playlist)
        }
        else {
            throw UnknownKindError(kind: kind)
        }
    }
    
}
