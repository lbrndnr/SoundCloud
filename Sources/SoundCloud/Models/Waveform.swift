//
//  Waveform.swift
//  Nuage
//
//  Created by Laurin Brandner on 14.01.21.
//

import Foundation

public struct Waveform {
    
    public var width: Int
    public var height: Int
    public var samples: [Int]
    
    public init(width: Int, height: Int, samples: [Int]) {
        self.width = width
        self.height = height
        self.samples = samples
    }
    
    public init(width: Int, height: Int, repeatedSample: Int) {
        let samples = Array(repeating: repeatedSample, count: width)
        self.init(width: width, height: height, samples: samples)
    }
    
}

extension Waveform: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case width
        case height
        case samples
    }
    
}
