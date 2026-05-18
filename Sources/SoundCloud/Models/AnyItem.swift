//
//  AnyItem.swift
//

import Foundation

public enum AnyItem: SoundCloudIdentifiable {
    case user(User)
    case playlist(AnyPlaylist)

    public var id: String {
        switch self {
        case .user(let user): return user.id
        case .playlist(let playlist): return playlist.id
        }
    }
}

extension AnyItem: Decodable {

    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)

        switch kind {
        case "user":
            self = .user(try User(from: decoder))
        case "playlist", "system-playlist":
            self = .playlist(try AnyPlaylist(from: decoder))
        default:
            throw UnknownKindError(kind: kind)
        }
    }

}
