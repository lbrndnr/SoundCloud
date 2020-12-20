//
//  Slice.swift
//  Nuage
//
//  Created by Laurin Brandner on 26.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation
import Combine

public struct NoNextSliceError: Error { }

public struct Slice<T: Decodable>: Decodable {
    
    public var collection: [T]
    public var next: URL?
    
    enum CodingKeys: String, CodingKey {
        case collection
        case next = "next_href"
    }
    
}
