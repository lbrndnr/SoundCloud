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
    case playlist(Playlist)
    
    public var id: Int {
        switch self {
        case .user(let user): return user.id
        case .track(let track): return track.id
        case .playlist(let playlist): return playlist.id
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
            let playlist = try Playlist(from: decoder)
            self = .playlist(playlist)
        }
        else {
            throw UnknownKindError(kind: kind)
        }
    }
    
}
