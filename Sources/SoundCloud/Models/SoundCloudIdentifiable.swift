//
//  SoundCloudIdentifiable.swift
//  Nuage
//
//  Created by Laurin Brandner on 02.11.20.
//  Copyright © 2020 Laurin Brandner. All rights reserved.
//

import Foundation

public protocol SoundCloudIdentifiable: Identifiable, Hashable {
    
    var id: String { get }
    
}

extension SoundCloudIdentifiable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
}
