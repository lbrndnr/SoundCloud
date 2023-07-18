//
//  Playlist.swift
//  
//
//  Created by Laurin Brandner on 20.03.21.
//

import Foundation

public protocol Playlist: SoundCloudIdentifiable, Encodable, Decodable {
    
    var id: String { get }
    var title: String { get }
    var description: String? { get }
    var artworkURL: URL? { get }
    var permalinkURL: URL { get }
    var isPublic: Bool { get }
    var user: User { get }
    
    /// For some requests, 5 full tracks are sent along.
    /// Their ids are a prefix of `trackIDs`
    var tracks: [Track]? { get }
    var trackIDs: [String]? { get }
    
}

public enum AnyPlaylist: Playlist {
    case user(UserPlaylist)
    case system(SystemPlaylist)
    
    private var playlist: any Playlist {
        switch self {
        case .user(let playlist): return playlist
        case .system(let playlist): return playlist
        }
    }
    
    public var userPlaylist: UserPlaylist? {
        switch self {
        case .user(let playlist): return playlist
        default: return nil
        }
    }
    
    public var systemPlaylist: SystemPlaylist? {
        switch self {
        case .system(let playlist): return playlist
        default: return nil
        }
    }
    
    public var id: String { return playlist.id }
    public var title: String { return playlist.title }
    public var description: String? { return playlist.description }
    public var artworkURL: URL? { return playlist.artworkURL }
    public var permalinkURL: URL { return playlist.permalinkURL }
    public var isPublic: Bool { return playlist.isPublic }
    public var user: User { return playlist.user }
    
    /// For some requests, 5 full tracks are sent along.
    /// Their ids are a prefix of `trackIDs`
    public var tracks: [Track]? { return playlist.tracks }
    public var trackIDs: [String]? { return playlist.trackIDs }
    
    private enum CodingKeys: String, CodingKey {
        case kind
        case userPlaylist = "playlist"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var isUserPlaylist = false
        if let kind = try? container.decodeIfPresent(String.self, forKey: .kind) {
            isUserPlaylist = (kind == "playlist")
        }
        else if let lastCodingPath = container.codingPath.last {
            isUserPlaylist = (lastCodingPath.stringValue == CodingKeys.userPlaylist.stringValue)
        }
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath + [CodingKeys.kind], debugDescription: "Could not resolve playlist type."))
        }
        
        if isUserPlaylist {
            self = .user(try UserPlaylist(from: decoder))
        }
        else {
            self = .system(try SystemPlaylist(from: decoder))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try playlist.encode(to: encoder)
    }
    
}
