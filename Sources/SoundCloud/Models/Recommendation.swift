//
//  Recommendation.swift
//  Nuage
//
//  Created by Laurin Brandner on 27.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct Recommendation: SoundCloudIdentifiable {
    
    public var id: Int {
        return user.id
    }
    
    public var user: User
    
}

extension Recommendation: Decodable {

    enum CodingKeys: String, CodingKey {
        case user
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(User.self, forKey: .user)
    }
    
}
