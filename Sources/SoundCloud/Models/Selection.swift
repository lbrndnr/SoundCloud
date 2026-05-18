//
//  Selection.swift
//

import Foundation

public struct Selection: Decodable, Identifiable, Hashable {

    public var id: String
    public var title: String
    public var description: String?
    public var items: [AnyItem]

    private enum CodingKeys: String, CodingKey {
        case id = "urn"
        case title
        case description
        case items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Best-effort decode items so one unexpected entry doesn't break the whole selection.
        let page = try container.decode(Page<LossyItem>.self, forKey: .items)
        items = page.collection.compactMap { $0.value }
    }

    public static func == (lhs: Selection, rhs: Selection) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }

}

private struct LossyItem: Decodable {

    let value: AnyItem?

    init(from decoder: Decoder) throws {
        value = try? AnyItem(from: decoder)
    }

}
