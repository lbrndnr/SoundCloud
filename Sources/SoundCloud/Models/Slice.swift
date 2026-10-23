//
//  Page.swift
//  Nuage
//
//  Created by Laurin Brandner on 26.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation

public struct NoNextPageError: Error { }

public struct Page<T: Decodable>: Decodable {
    
    public var collection: [T]
    public var next: URL?
    
    enum CodingKeys: String, CodingKey {
        case collection
        case next = "next_href"
    }
    
}

extension Page: Sendable where T: Sendable {}
