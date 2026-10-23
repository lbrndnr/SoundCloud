import Foundation
import Testing
@testable import SoundCloud

private let userJSON = """
{
    "id": 8735966,
    "kind": "user",
    "username": "crackmagazine",
    "first_name": "Crack",
    "last_name": "Magazine",
    "full_name": "Crack Magazine",
    "followers_count": 45166,
    "avatar_url": "https://i1.sndcdn.com/avatars-000272088189-nlkha2-large.jpg"
}
"""

private func trackJSON(id: Int) -> String {
    return """
    {
        "id": \(id),
        "kind": "track",
        "title": "Track \(id)",
        "description": "A description",
        "artwork_url": "https://i1.sndcdn.com/artworks-\(id)-large.jpg",
        "waveform_url": "https://wave.sndcdn.com/\(id)_m.json",
        "permalink_url": "https://soundcloud.com/crackmagazine/track-\(id)",
        "duration": 4057051,
        "playback_count": 10,
        "likes_count": null,
        "reposts_count": 3,
        "created_at": "2023-06-08T14:35:30Z",
        "media": {
            "transcodings": [
                {
                    "url": "https://api-v2.soundcloud.com/media/\(id)/stream/hls",
                    "duration": 4057051,
                    "format": { "protocol": "hls", "mime_type": "audio/mpeg" },
                    "quality": "sq"
                },
                {
                    "url": "https://api-v2.soundcloud.com/media/\(id)/stream/progressive",
                    "duration": 4057051,
                    "format": { "protocol": "progressive", "mime_type": "audio/mpeg" },
                    "quality": "sq"
                }
            ]
        },
        "user": \(userJSON)
    }
    """
}

/// A playlist as returned by the API: only the first track is complete, the others merely contain their id.
private let userPlaylistJSON = """
{
    "id": 1234,
    "kind": "playlist",
    "title": "My Playlist",
    "artwork_url": null,
    "permalink_url": "https://soundcloud.com/crackmagazine/sets/my-playlist",
    "public": true,
    "is_album": false,
    "secret_token": "s-abc",
    "created_at": "2023-06-08T14:35:30Z",
    "user": \(userJSON),
    "tracks": [
        \(trackJSON(id: 1)),
        { "id": 2, "kind": "track" },
        { "id": 3, "kind": "track" }
    ]
}
"""

private let systemPlaylistJSON = """
{
    "id": "soundcloud:system-playlists:track-stations:1",
    "urn": "soundcloud:system-playlists:track-stations:1",
    "kind": "system-playlist",
    "title": "Station",
    "calculated_artwork_url": "https://i1.sndcdn.com/artworks-station-large.jpg",
    "permalink_url": "https://soundcloud.com/discover/sets/track-stations:1",
    "is_public": true,
    "user": \(userJSON),
    "tracks": [\(trackJSON(id: 1)), \(trackJSON(id: 2))]
}
"""

private let postJSON = """
{
    "uuid": "post-1",
    "created_at": "2023-06-08T14:35:30Z",
    "caption": null,
    "type": "track-repost",
    "track": \(trackJSON(id: 1)),
    "user": \(userJSON)
}
"""

/// Decodes `json` the way `SoundCloud` decodes API responses.
private func decodeAPI<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(formatter)

    return try decoder.decode(T.self, from: Data(json.utf8))
}

private func roundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

@Suite("Coding round trips")
struct CodingTests {

    @Test func trackRoundTrip() throws {
        let track = try decodeAPI(Track.self, from: trackJSON(id: 1))
        #expect(track.id == "1")
        #expect(track.duration == 4057.051)
        #expect(track.streamURL?.absoluteString == "https://api-v2.soundcloud.com/media/1/stream/progressive")

        let decoded = try roundTrip(track)
        #expect(decoded.id == track.id)
        #expect(decoded.title == track.title)
        #expect(decoded.description == track.description)
        #expect(decoded.artworkURL == track.artworkURL)
        #expect(decoded.waveformURL == track.waveformURL)
        #expect(decoded.streamURL == track.streamURL)
        #expect(decoded.permalinkURL == track.permalinkURL)
        #expect(decoded.duration == track.duration)
        #expect(decoded.playbackCount == track.playbackCount)
        #expect(decoded.likeCount == track.likeCount)
        #expect(decoded.repostCount == track.repostCount)
        #expect(decoded.date == track.date)
        #expect(decoded.user.id == track.user.id)
    }

    @Test func userPlaylistRoundTripKeepsAllTrackIDs() throws {
        let playlist = try decodeAPI(UserPlaylist.self, from: userPlaylistJSON)
        #expect(playlist.trackIDs == ["1", "2", "3"])

        let decoded = try roundTrip(playlist)
        #expect(decoded.id == playlist.id)
        #expect(decoded.title == playlist.title)
        #expect(decoded.isPublic == playlist.isPublic)
        #expect(decoded.secretToken == playlist.secretToken)
        #expect(decoded.date == playlist.date)
        #expect(decoded.trackIDs == ["1", "2", "3"])
    }

    @Test func systemPlaylistRoundTrip() throws {
        let playlist = try decodeAPI(SystemPlaylist.self, from: systemPlaylistJSON)

        let decoded = try roundTrip(playlist)
        #expect(decoded.id == playlist.id)
        #expect(decoded.urn == playlist.urn)
        #expect(decoded.artworkURL == playlist.artworkURL)
        #expect(decoded.tracks?.map(\.id) == ["1", "2"])
        #expect(decoded.trackIDs == ["1", "2"])
    }

    @Test func anyPlaylistsRoundTripPreserveTheirKind() throws {
        let playlists = [
            try decodeAPI(UserPlaylist.self, from: userPlaylistJSON).eraseToAnyPlaylist(),
            try decodeAPI(SystemPlaylist.self, from: systemPlaylistJSON).eraseToAnyPlaylist()
        ]

        let decoded = try roundTrip(playlists)
        #expect(decoded.count == 2)
        #expect(decoded[0].userPlaylist?.id == "1234")
        #expect(decoded[1].systemPlaylist?.urn == "soundcloud:system-playlists:track-stations:1")
    }

    @Test func postRoundTrip() throws {
        let post = try decodeAPI(Post.self, from: postJSON)

        let decoded = try roundTrip(post)
        #expect(decoded.id == post.id)
        #expect(decoded.isRepost)
        #expect(decoded.tracks.map(\.id) == ["1"])
    }

}
