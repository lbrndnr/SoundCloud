//
//  Like.swift
//  Nuage
//
//  Created by Laurin Brandner on 25.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public class Like<T: SoundCloudIdentifiable & Decodable>: SoundCloudIdentifiable, Decodable {
    
    public var id: String {
        return item.id
    }
    
    public var date: Date
    public var item: T

    enum CodingKeys: String, CodingKey {
        case date = "created_at"
        case track
        case userPlaylist = "playlist"
        case systemPlaylist = "system_playlist"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        date = try container.decode(Date.self, forKey: .date)
        let track = try container.decodeIfPresent(T.self, forKey: .track)
        let userPlaylist = try container.decodeIfPresent(T.self, forKey: .userPlaylist)
        let systemPlaylist = try container.decodeIfPresent(T.self, forKey: .systemPlaylist)
        item = (track ?? userPlaylist ?? systemPlaylist)!
    }
    
}
