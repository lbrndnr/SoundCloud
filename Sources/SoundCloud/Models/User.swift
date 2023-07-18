//
//  User.swift
//  Nuage
//
//  Created by Laurin Brandner on 25.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct NoUserError: Error { }

public struct User: SoundCloudIdentifiable, Encodable, Decodable {
    
    public var id: String
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
    
    public var playlists: [AnyPlaylist]?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case name = "full_name"
        case description = "description"
        case city = "city"
        case countryCode = "country_code"
        case followerCount = "followers_count"
        case followingCount = "followings_count"
        case avatarURL = "avatar_url"
        case playlists = "playlists"
    }
    
    public init(id: String, username: String, firstName: String, lastName: String, avatarURL: URL) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.name = "\(firstName) \(lastName)"
        self.avatarURL = avatarURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // SoundCloud's API uses Int, Nuage uses String
        do {
            let rawID = try container.decode(Int.self, forKey: .id)
            id = String(rawID)
        }
        catch {
            id = try container.decode(String.self, forKey: .id)
        }
        
        username = try container.decode(String.self, forKey: .username)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount)
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
        avatarURL = try container.decode(URL.self, forKey: .avatarURL)
        
        playlists = try container.decodeIfPresent([AnyPlaylist].self, forKey: .playlists)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(countryCode, forKey: .countryCode)
        
        try container.encodeIfPresent(followerCount, forKey: .followerCount)
        try container.encodeIfPresent(followingCount, forKey: .followingCount)
        try container.encode(avatarURL, forKey: .avatarURL)
        
        try container.encode(playlists, forKey: .playlists)
    }
    
}
