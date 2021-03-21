//
//  SystemPlaylist.swift
//  
//
//  Created by Laurin Brandner on 18.03.21.
//

import Foundation

public class SystemPlaylist: Playlist {
    
    public var madeForUser: User

    enum CodingKeys: String, CodingKey {
        case madeForUser = "made_for"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        madeForUser = try container.decode(User.self, forKey: .madeForUser)
        
        try super.init(from: decoder)
    }
    
}
