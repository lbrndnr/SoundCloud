//
//  APIRequest.swift
//  Nuage
//
//  Created by Laurin Brandner on 18.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public enum Filter: String {
    case users
    case tracks
    case albums
    case playlists
}

public struct APIRequest<T> {
    
    public enum API {
        case me
        case library
        case stream
        case whoToFollow
        case followings(String)
        case followers(String)
        case search(String, Filter?)
        case resolve(URL)
        
        case user(String)
        case userStream(String)
        
        case history
        case addToHistory(String)
        
        case tracks([String])
        case trackLikes(String)
        case likeTrack(String)
        case unlikeTrack(String)
        case repostTrack(String)
        case unrepostTrack(String)
        case comments(String)
        
        case userPlaylist(String)
        case systemPlaylist(String)
//        case playlistLikes(String)
        case likePlaylist(String)
        case unlikePlaylist(String)
        case repostPlaylist(String)
        case unrepostPlaylist(String)
        case setPlaylistTracks(String, [Int])
    }
    
    public static func me() -> APIRequest<User> {
        return APIRequest<User>(api: .me)
    }
    
    public static func library() -> APIRequest<Page<Like<AnyPlaylist>>> {
        return APIRequest<Page<Like<AnyPlaylist>>>(api: .library)
    }
    
    public static func stream() -> APIRequest<Page<Post>> {
        return APIRequest<Page<Post>>(api: .stream)
    }
    
    public static func whoToFollow() -> APIRequest<Page<Recommendation>> {
        return APIRequest<Page<Recommendation>>(api: .whoToFollow)
    }
    
    public static func followings(of user: User) -> APIRequest<Page<User>> {
        return APIRequest<Page<User>>(api: .followings(user.id))
    }
    
    public static func followers(of user: User) -> APIRequest<Page<User>> {
        return APIRequest<Page<User>>(api: .followers(user.id))
    }
    
    public static func history() -> APIRequest<Page<HistoryItem>> {
        return APIRequest<Page<HistoryItem>>(api: .history)
    }
    
    public static func search(_ query: String, filter: Filter? = nil) -> APIRequest<Page<Some>> {
        return APIRequest<Page<Some>>(api: .search(query, filter))
    }
    
    public static func resolve(_ url: URL) -> APIRequest<Some> {
        return APIRequest<Some>(api: .resolve(url))
    }
    
    public static func user(with id: String) -> APIRequest<User> {
        return APIRequest<User>(api: .user(id))
    }
    
    public static func stream(of user: User) -> APIRequest<Page<Post>> {
        return APIRequest<Page<Post>>(api: .userStream(user.id))
    }
    
    public static func tracks(_ ids: [String]) -> APIRequest<[Track]> {
        return APIRequest<[Track]>(api: .tracks(ids))
    }
    
    public static func trackLikes(of user: User) -> APIRequest<Page<Like<Track>>> {
        return APIRequest<Page<Like<Track>>>(api: .trackLikes(user.id))
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
    
    public static func comments(of track: Track) -> APIRequest<Page<Comment>> {
        return APIRequest<Page<Comment>>(api: .comments(track.id))
    }
    
    public static func userPlaylist(_ id: String) -> APIRequest<UserPlaylist> {
        return APIRequest<UserPlaylist>(api: .userPlaylist(id))
    }
    
    public static func systemPlaylist(_ urn: String) -> APIRequest<SystemPlaylist> {
        return APIRequest<SystemPlaylist>(api: .systemPlaylist(urn))
    }

    public static func addToHistory(_ track: Track) -> APIRequest<()> {
        return APIRequest<()>(api: .addToHistory(track.urn))
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
    
    public static func set(_ playlist: UserPlaylist, trackIDs: [Int]) -> APIRequest<UserPlaylist> {
        return APIRequest<UserPlaylist>(api: .setPlaylistTracks(playlist.id, trackIDs))
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
        case .search(_, let filter):
            if let filter = filter {
                return "search/\(filter)"
            }
            return "search"
        case .resolve(_): return "resolve"
            
        case .history: return "me/play-history/tracks"
        case .addToHistory(_): return "me/play-history"
            
        case .user(let id): return "users/\(id)"
        case .userStream(let id): return "stream/users/\(id)"
        
        case .tracks(_): return "tracks"
        case .trackLikes(let id): return "users/\(id)/track_likes"
        case .likeTrack(let trackID): fallthrough
        case .unlikeTrack(let trackID): return "users/\(SoundCloud.shared.user?.id ?? "")/track_likes/\(trackID)"
        case .repostTrack(let trackID): fallthrough
        case .unrepostTrack(let trackID): return "me/track_reposts/\(trackID)"
        case .comments(let trackID): return "tracks/\(trackID)/comments"
            
        case .userPlaylist(let id): return "playlists/\(id)"
        case .systemPlaylist(let urn): return "system-playlists/\(urn)"
        case .likePlaylist(let playlistID): fallthrough
        case .unlikePlaylist(let playlistID): return "users/\(SoundCloud.shared.user?.id ?? "")/playlist_likes/\(playlistID)"
        case .repostPlaylist(let playlistID): fallthrough
        case .unrepostPlaylist(let playlistID): return "me/playlist_reposts/\(playlistID)"
        case .setPlaylistTracks(let id, _): return "playlists/\(id)"
        }
    }
    
    var queryParameters: [String: String]? {
        switch api {
        case .tracks(let ids): return ["ids": ids.map { String($0) }.joined(separator: ",")]
        case .search(let query, _): return ["q": query]
        case .resolve(let url): return ["url": url.absoluteString]
        case .comments(_): return ["client_id": "D7YkmhAjzaV0qsA9e71yKXufTMyJAX2Q", "filter_replies": "0", "threaded": "1"]
        default: return nil
        }
    }
    
    var httpMethod: String {
        switch api {
        case .addToHistory(_): return "POST"
        case .likeTrack(_): return "PUT"
        case .unlikeTrack(_): return "DELETE"
        case .repostTrack(_): return "PUT"
        case .unrepostTrack(_): return "DELETE"
        case .likePlaylist(_): return "PUT"
        case .unlikePlaylist(_): return "DELETE"
        case .repostPlaylist(_): return "PUT"
        case .unrepostPlaylist(_): return "DELETE"
        case .setPlaylistTracks(_, _): return "PUT"
        default: return "GET"
        }
    }
    
    var jsonBody: [String: Any]? {
        switch api {
        case .addToHistory(let urn): return ["track_urn": urn]
        case .setPlaylistTracks(_, let trackIDs):
            return [
                "playlist": [
                    "tracks": trackIDs
                ]
            ]
        default: return nil
        }
    }
    
    var needsUserID: Bool {
        switch api {
        case .addToHistory(_): return true
        case .likeTrack(_): return true
        case .unlikeTrack(_): return true
        case .likePlaylist(_): return true
        case .unlikePlaylist(_): return true
        default: return false
        }
    }
    
}

