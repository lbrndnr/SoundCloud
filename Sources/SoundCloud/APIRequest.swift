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
        case library
        case stream
        case whoToFollow
        case followings(String)
        case followers(String)
        case history
        case search(String)
        
        case user(String)
        case userStream(String)
        
        case tracks([String])
        case trackLikes(String)
        case likeTrack(String)
        case unlikeTrack(String)
        case repostTrack(String)
        case unrepostTrack(String)
        case comments(String)
        
        case playlist(String)
//        case playlistLikes(String)
        case likePlaylist(String)
        case unlikePlaylist(String)
        case repostPlaylist(String)
        case unrepostPlaylist(String)
        case addToPlaylist(String, [String])
    }
    
    public static func me() -> APIRequest<User> {
        return APIRequest<User>(api: .me)
    }
    
    public static func library() -> APIRequest<Slice<Like<AnyPlaylist>>> {
        return APIRequest<Slice<Like<AnyPlaylist>>>(api: .library)
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
    
    public static func user(with id: String) -> APIRequest<User> {
        return APIRequest<User>(api: .user(id))
    }
    
    public static func stream(of user: User) -> APIRequest<Slice<Post>> {
        return APIRequest<Slice<Post>>(api: .userStream(user.id))
    }
    
    public static func tracks(_ ids: [String]) -> APIRequest<[Track]> {
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
    
    public static func repost(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .repostTrack(track.id))
    }
    
    public static func unrepost(_ track: Track) -> APIRequest<String> {
        return APIRequest<String>(api: .unrepostTrack(track.id))
    }
    
    public static func comments(of track: Track) -> APIRequest<Slice<Comment>> {
        return APIRequest<Slice<Comment>>(api: .comments(track.id))
    }
    
    public static func playlist(_ id: String) -> APIRequest<AnyPlaylist> {
        return APIRequest<AnyPlaylist>(api: .playlist(id))
    }
    
    public static func like<T: Playlist>(_ playlist: T) -> APIRequest<String> {
        return APIRequest<String>(api: .likePlaylist(playlist.id))
    }
    
    public static func unlike<T: Playlist>(_ playlist: T) -> APIRequest<String> {
        return APIRequest<String>(api: .unlikePlaylist(playlist.id))
    }
    
    public static func repost(_ playlist: UserPlaylist) -> APIRequest<String> {
        return APIRequest<String>(api: .repostPlaylist(playlist.id))
    }
    
    public static func unrepost(_ playlist: UserPlaylist) -> APIRequest<String> {
        return APIRequest<String>(api: .unrepostPlaylist(playlist.id))
    }
    
    public static func add(to playlist: UserPlaylist, trackIDs: [String]) -> APIRequest<UserPlaylist> {
        return APIRequest<UserPlaylist>(api: .addToPlaylist(playlist.id, trackIDs))
    }
    
    public var api: API
    
    var path: String {
        switch api {
        case .me: return "me"
        case .library: return "me/library/all"
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
        case .unlikeTrack(let trackID): return "users/\(SoundCloud.shared.user?.id ?? "")/track_likes/\(trackID)"
        case .repostTrack(let trackID): fallthrough
        case .unrepostTrack(let trackID): return "me/track_reposts/\(trackID)"
        case .comments(let trackID): return "tracks/\(trackID)/comments"
            
        case .playlist(let id): return "playlists/\(id)"
        case .likePlaylist(let playlistID): fallthrough
        case .unlikePlaylist(let playlistID): return "users/\(SoundCloud.shared.user?.id ?? "")/playlist_likes/\(playlistID)"
        case .repostPlaylist(let playlistID): fallthrough
        case .unrepostPlaylist(let playlistID): return "me/playlist_reposts/\(playlistID)"
        case .addToPlaylist(let id, _): return "playlists/\(id)"
        }
    }
    
    var queryParameters: [String: String]? {
        switch api {
        case .tracks(let ids): return ["ids": ids.map { String($0) }.joined(separator: ",")]
        case .search(let query): return ["q": query]
        case .comments(_): return ["client_id": "D7YkmhAjzaV0qsA9e71yKXufTMyJAX2Q", "filter_replies": "0", "threaded": "1"]
        default: return nil
        }
    }
    
    var httpMethod: String {
        switch api {
        case .likeTrack(_): return "PUT"
        case .unlikeTrack(_): return "DELETE"
        case .repostTrack(_): return "PUT"
        case .unrepostTrack(_): return "DELETE"
        case .likePlaylist(_): return "PUT"
        case .unlikePlaylist(_): return "DELETE"
        case .repostPlaylist(_): return "PUT"
        case .unrepostPlaylist(_): return "DELETE"
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

