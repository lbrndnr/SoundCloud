//
//  File.swift
//  
//
//  Created by Laurin Brandner on 19.02.21.
//

import Foundation

public class Comment: SoundCloudIdentifiable, Decodable {
    
    public var id: String
    public var body: String
    public var date: Date
    public var timestamp: TimeInterval
    public var trackID: Int
    public var user: User

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case date = "created_at"
        case timestamp
        case trackID = "track_id"
        case user
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rawID = try container.decode(Int.self, forKey: .id)
        id = String(rawID)
        body = try container.decode(String.self, forKey: .body)
        date = try container.decode(Date.self, forKey: .date)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)/1000.0
        trackID = try container.decode(Int.self, forKey: .trackID)
        user = try container.decode(User.self, forKey: .user)
    }
    
}
