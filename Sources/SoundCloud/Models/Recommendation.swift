//
//  Recommendation.swift
//  Nuage
//
//  Created by Laurin Brandner on 27.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public class Recommendation: SoundCloudIdentifiable, Decodable {
    
    public var id: String {
        return user.id
    }
    
    public var user: User

    enum CodingKeys: String, CodingKey {
        case user
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
    }
    
}
