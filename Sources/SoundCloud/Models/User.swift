//
//  User.swift
//  Nuage
//
//  Created by Laurin Brandner on 25.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

struct NoUserError: Error { }

public struct User: SoundCloudIdentifiable {
    
    public var id: Int
    public var name: String
    public var username: String
    public var followerCount: Int?
    public var followingCount: Int?
    public var avatarURL: URL
    
    public var playlists: [Playlist]?
    
}

extension User: Encodable, Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case name = "full_name"
        case username = "permalink"
        case followerCount = "followers_count"
        case followingCount = "followings_count"
        case avatarURL = "avatar_url"
    }
    
}

extension User: Filterable {
    
    func contains(_ text: String) -> Bool {
        return name.contains(text) || username.contains(text)
    }
    
}
