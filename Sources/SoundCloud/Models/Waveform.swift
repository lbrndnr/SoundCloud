//
//  Waveform.swift
//  Nuage
//
//  Created by Laurin Brandner on 14.01.21.
//

import Foundation

public struct Waveform: Decodable {
    
    public var width: Int
    public var height: Int
    public var samples: [Int]
    
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case samples
    }
    
}
