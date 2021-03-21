//
//  UserPlaylist.swift
//  Nuage
//
//  Created by Laurin Brandner on 02.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public class UserPlaylist: Playlist {
    
    public var secretToken: String?
    public var isAlbum: Bool
    public var date: Date

    enum CodingKeys: String, CodingKey {
        case secretToken = "secret_token"
        case isAlbum = "is_album"
        case date = "created_at"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        isAlbum = try container.decode(Bool.self, forKey: .isAlbum)
        secretToken = try container.decodeIfPresent(String.self, forKey: .secretToken)
        date = try container.decode(Date.self, forKey: .date)
        
        try super.init(from: decoder)
    }
    
}
