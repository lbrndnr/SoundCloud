//
//  Playlist.swift
//  
//
//  Created by Laurin Brandner on 20.03.21.
//

import Foundation

public class Playlist: SoundCloudIdentifiable, Decodable {
    
    public var id: String
    public var title: String
    public var description: String?
    public var artworkURL: URL?
    public var permalinkURL: URL
    public var isPublic: Bool
    public var user: User
    
    /// For some requests, 5 full tracks are sent along.
    /// Their ids are a prefix of `trackIDs`
    public var tracks: [Track]?
    public var trackIDs: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case artworkURL = "artwork_url"
        case permalinkURL = "permalink_url"
        case isPublic = "public"
        case isPublic2 = "is_public"
        case tracks
        case user
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let intID = try? container.decode(Int.self, forKey: .id)
        let stringID = try? container.decode(String.self, forKey: .id)
        id = (intID.map(String.init) ?? stringID)!
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        permalinkURL = try container.decode(URL.self, forKey: .permalinkURL)
        
        let rawIsPublic = try? container.decode(Bool.self, forKey: .isPublic)
        let rawIsPublic2 = try? container.decode(Bool.self, forKey: .isPublic2)
        isPublic = (rawIsPublic ?? rawIsPublic2)!
        
        user = try container.decode(User.self, forKey: .user)
        
        if container.contains(.tracks) {
            do {
                let tracks = try container.decode([Track].self, forKey: .tracks)
                self.tracks = tracks
                self.trackIDs = tracks.map { $0.id }
            }
            catch {
                if let tracks = try container.decode([Any].self, forKey: .tracks) as? [[String : Any]] {
                    let ids = tracks.map {"\(String(describing: $0["id"]))" }
                    self.trackIDs = ids
                }
            }
        }
    }
    
}
