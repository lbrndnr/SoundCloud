//
//  ResourceRequest.swift
//  Nuage
//
//  Created by Laurin Brandner on 14.01.21.
//

import Foundation

public struct ParseError: Error {}

public struct ResourceRequest<T: Decodable> {
    
    typealias Decoder = (([AnyHashable: Any]) throws -> T)
    
    public enum Resource {
        case waveform(URL)
        case audioFile(URL)
    }
    
    public static func waveform(_ url: URL) -> ResourceRequest<Waveform> {
        return ResourceRequest<Waveform>(resource: .waveform(url))
    }
    
    public static func audioFile(_ url: URL) -> ResourceRequest<URL> {
        return ResourceRequest<URL>(resource: .audioFile(url))
    }
    
    public var resource: Resource
    
    var url: URL {
        switch resource {
        case .waveform(let url): return url
        case .audioFile(let url): return url
        }
    }
    
    var needsAuthorization: Bool {
        switch resource {
        case .audioFile(_): return true
        default: return false
        }
    }
    
    var decoder: Decoder? {
        switch resource {
        case .audioFile(_): return { payload in
            guard let payload = payload as? [String: String] else { throw ParseError() }
            return URL(string: payload["url"]!) as! T
        }
        default: return nil
        }
    }
    
}
