//
//  Waveform.swift
//  Nuage
//
//  Created by Laurin Brandner on 14.01.21.
//

import Foundation

public struct Waveform: Encodable, Decodable {
    
    public var width: Int {
        return samples.count
    }
    public var minHeight: Int {
        return samples.min() ?? 0
    }
    public var maxHeight: Int {
        return samples.max() ?? 0
    }
    public var samples: [Int]
    
    public init(samples: [Int]) {
        self.samples = samples
    }
    
    enum CodingKeys: String, CodingKey {
        case samples
    }
    
}

extension Waveform: Equatable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(samples.hashValue)
    }
    
    public static func ==(lhs: Waveform, rhs: Waveform) -> Bool {
        return lhs.samples == rhs.samples
    }
    
}
