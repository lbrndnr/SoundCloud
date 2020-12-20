//
//  Like.swift
//  Nuage
//
//  Created by Laurin Brandner on 25.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct Like<T: SoundCloudIdentifiable & Decodable>: SoundCloudIdentifiable {
    
    public var id: Int {
        return item.id
    }
    
    public var date: Date
    public var item: T
    
}

extension Like: Decodable {

    enum CodingKeys: String, CodingKey {
        case date = "created_at"
        case track
        case playlist
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        date = try container.decode(Date.self, forKey: .date)
        let track = try container.decodeIfPresent(T.self, forKey: .track)
        let playlist = try container.decodeIfPresent(T.self, forKey: .playlist)
        item = (track ?? playlist)!
    }
    
}
