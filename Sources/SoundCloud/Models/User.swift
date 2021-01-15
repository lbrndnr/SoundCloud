//
//  User.swift
//  Nuage
//
//  Created by Laurin Brandner on 25.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct NoUserError: Error { }

public struct User: SoundCloudIdentifiable {
    
    public var id: Int
    public var username: String
    public var firstName: String
    public var lastName: String
    public var name: String
    public var description: String?
    
    public var city: String?
    public var countryCode: String?
    
    public var followerCount: Int?
    public var followingCount: Int?
    public var avatarURL: URL
    
    public var playlists: [Playlist]?
    
    public init(id: Int, username: String, firstName: String, lastName: String, avatarURL: URL) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.name = "\(firstName) \(lastName)"
        self.avatarURL = avatarURL
    }
    
}

extension User: Encodable, Decodable {

    enum CodingKeys: String, CodingKey {
        case id
        case username = "permalink"
        case firstName = "first_name"
        case lastName = "last_name"
        case name = "full_name"
        case description = "description"
        case city = "city"
        case countryCode = "country_code"
        case followerCount = "followers_count"
        case followingCount = "followings_count"
        case avatarURL = "avatar_url"
    }
    
}
