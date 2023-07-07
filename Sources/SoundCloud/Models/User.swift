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
    
    public var playlists: [Playlist]?

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
        playlists = try container.decodeIfPresent([Playlist].self, forKey: .playlists)
    }
    
    
}
