//
//  APIRequest.swift
//  Nuage
//
//  Created by Laurin Brandner on 18.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public struct APIRequest<T: Decodable> {
    
    public enum API {
        case me
        case albumsAndPlaylists
        case stream
        case whoToFollow
        case followings(Int)
        case followers(Int)
        case history
        case search(String)
        
        case user(Int)
        case userStream(Int)
        
        case tracks([Int])
        case trackLikes(Int)
        case likeTrack(Int)
        case unlikeTrack(Int)
        case reblogTrack(Int)
        case unreblogTrack(Int)
        
        case playlist(Int)
//        case playlistLikes(Int)
        case likePlaylist(Int)
        case unlikePlaylist(Int)
        case reblogPlaylist(Int)
        case unreblogPlaylist(Int)
        case addToPlaylist(Int, [Int])
    }
    
    public static func me() -> APIRequest<User> {
        return APIRequest<User>(api: .me)
    }
    
    public static func albumsAndPlaylists() -> APIRequest<Slice<Like<Playlist>>> {
        return APIRequest<Slice<Like<Playlist>>>(api: .albumsAndPlaylists)
    }
    
    public static func stream() -> APIRequest<Slice<Post>> {
        return APIRequest<Slice<Post>>(api: .stream)
    }
    
    public static func whoToFollow() -> APIRequest<Slice<Recommendation>> {
        return APIRequest<Slice<Recommendation>>(api: .whoToFollow)
    }
    
    public static func followings(of user: User) -> APIRequest<Slice<User>> {
        return APIRequest<Slice<User>>(api: .followings(user.id))
    }
    
    public static func followers(of user: User) -> APIRequest<Slice<User>> {
        return APIRequest<Slice<User>>(api: .followers(user.id))
    }
    
    public static func history() -> APIRequest<Slice<HistoryItem>> {
        return APIRequest<Slice<HistoryItem>>(api: .history)
    }
    
    public static func search(_ query: String) -> APIRequest<Slice<Some>> {
        return APIRequest<Slice<Some>>(api: .search(query))
    }
    
    public static func user(with id: Int) -> APIRequest<User> {
        return APIRequest<User>(api: .user(id))
    }
    
    public static func stream(of user: User) -> APIRequest<Slice<Post>> {
        return APIRequest<Slice<Post>>(api: .userStream(user.id))
    }
    
    public static func tracks(_ ids: [Int]) -> APIRequest<[Track]> {
        return APIRequest<[Track]>(api: .tracks(ids))
    }
    
    public static func trackLikes(of user: User) -> APIRequest<Slice<Like<Track>>> {
        return APIRequest<Slice<Like<Track>>>(api: .trackLikes(user.id))
    }
    
    public static func like(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .likeTrack(track.id))
    }
    
    public static func unlike(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .unlikeTrack(track.id))
    }
    
    public static func reblog(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .reblogTrack(track.id))
    }
    
    public static func unreblog(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .unreblogTrack(track.id))
    }
    
    public static func playlist(_ id: Int) -> APIRequest<Playlist> {
        return APIRequest<Playlist>(api: .playlist(id))
    }
    
    public static func like(_ playlist: Playlist) -> APIRequest<String> {
        return APIRequest<String>(api: .likePlaylist(playlist.id))
    }
    
    public static func unlike(_ playlist: Playlist) -> APIRequest<String> {
        return APIRequest<String>(api: .unlikePlaylist(playlist.id))
    }
    
    public static func reblog(_ playlist: Playlist) -> APIRequest<String> {
        return APIRequest<String>(api: .reblogPlaylist(playlist.id))
    }
    
    public static func unreblog(_ playlist: Playlist) -> APIRequest<String> {
        return APIRequest<String>(api: .unreblogPlaylist(playlist.id))
    }
    
    public static func add(to playlist: Playlist, trackIDs: [Int]) -> APIRequest<Playlist> {
        return APIRequest<Playlist>(api: .addToPlaylist(playlist.id, trackIDs))
    }
    
    public var api: API
    
    var path: String {
        switch api {
        case .me: return "me"
        case .albumsAndPlaylists: return "me/library/albums_playlists_and_system_playlists"
        case .stream: return "stream"
        case .whoToFollow: return "me/suggested/users/who_to_follow"
        case .followings(let id): return "users/\(id)/followings"
        case .followers(let id): return "users/\(id)/followers"
        case .history: return "me/play-history/tracks"
        case .search(_): return "search"
            
        case .user(let id): return "users/\(id)"
        case .userStream(let id): return "stream/users/\(id)"
        
        case .tracks(_): return "tracks"
        case .trackLikes(let id): return "users/\(id)/track_likes"
        case .likeTrack(let trackID): fallthrough
        case .unlikeTrack(let trackID): return "users/\(SoundCloud.shared.user?.id ?? 0)/track_likes/\(trackID)"
        case .reblogTrack(let trackID): fallthrough
        case .unreblogTrack(let trackID): return "me/track_reposts/\(trackID)"
            
        case .playlist(let id): return "playlists/\(id)"
        case .likePlaylist(let playlistID): fallthrough
        case .unlikePlaylist(let playlistID): return "users/\(SoundCloud.shared.user?.id ?? 0)/playlist_likes/\(playlistID)"
        case .reblogPlaylist(let playlistID): fallthrough
        case .unreblogPlaylist(let playlistID): return "me/playlist_reposts/\(playlistID)"
        case .addToPlaylist(let id, _): return "playlists/\(id)"
        }
    }
    
    var queryParameters: [String: String]? {
        switch api {
        case .tracks(let ids): return ["ids": ids.map { String($0) }.joined(separator: ",")]
        case .search(let query): return ["q": query]
        default: return nil
        }
    }
    
    var httpMethod: String {
        switch api {
        case .likeTrack(_): return "PUT"
        case .unlikeTrack(_): return "DELETE"
        case .reblogTrack(_): return "PUT"
        case .unreblogTrack(_): return "DELETE"
        case .likePlaylist(_): return "PUT"
        case .unlikePlaylist(_): return "DELETE"
        case .reblogPlaylist(_): return "PUT"
        case .unreblogPlaylist(_): return "DELETE"
        case .addToPlaylist(_, _): return "PUT"
        default: return "GET"
        }
    }
    
    var body: Data? {
        switch api {
        case .addToPlaylist(_, let trackIDs):
            let tracks = ["tracks": trackIDs]
            let payload = ["playlist": tracks]
            do {
                return try JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed)
            }
            catch {
                return nil
            }
        default: return nil
        }
    }
    
    var needsUserID: Bool {
        switch api {
        case .likeTrack(_): fallthrough
        case .unlikeTrack(_): return true
        case .likePlaylist(_): fallthrough
        case .unlikePlaylist(_): return true
        default: return false
        }
    }
    
}

