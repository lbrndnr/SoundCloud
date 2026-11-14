//
//  ResponseCache.swift
//  Nuage
//
//  Created by Laurin Brandner on 14.11.26.
//

import Foundation
import CryptoKit

/// Whether requests use the cache, see `ResponseCache.policy`.
public enum CachePolicy: Sendable {
    /// Responses are loaded from the network and not cached.
    case none
    /// Responses are only loaded from the cache, requests fail with a `CacheMissError` otherwise.
    case cacheOnly
    /// Responses are loaded from the network and replace the cached ones.
    case reload
}

public struct CacheMissError: Error {}

/// A persistent cache of the raw API responses, keyed by their request URL.
///
/// Entries that weren't used for `maxAge` are deleted. When the cache exceeds `maxSize` bytes,
/// the least recently used entries are deleted until it fits again.
public actor ResponseCache {

    /// The cache policy of the requests performed within `ResponseCache.$policy.withValue(_:operation:)`.
    @TaskLocal public static var policy = CachePolicy.none

    private struct Entry {
        var size: Int
        var lastUsed: Date
    }

    private let directory: URL
    private let maxAge: TimeInterval
    private let maxSize: Int

    /// The entries by file name. It's read from disk on first use.
    private var index = [String: Entry]()
    private var isIndexLoaded = false

    public init(directory: URL, maxAge: TimeInterval, maxSize: Int) {
        self.directory = directory
        self.maxAge = maxAge
        self.maxSize = maxSize
    }

    // MARK: - Access

    func data(forKey key: String) -> Data? {
        loadIndexIfNeeded()

        let name = fileName(forKey: key)
        guard let entry = index[name] else { return nil }

        let now = Date()
        guard now.timeIntervalSince(entry.lastUsed) < maxAge,
              let data = try? Data(contentsOf: url(forFileName: name)) else {
            remove(name)
            return nil
        }

        // The modification date persists when the entry was last used
        try? FileManager.default.setAttributes([.modificationDate: now], ofItemAtPath: url(forFileName: name).path)
        index[name]?.lastUsed = now

        return data
    }

    func store(_ data: Data, forKey key: String) {
        guard data.count <= maxSize else { return }
        loadIndexIfNeeded()

        let name = fileName(forKey: key)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url(forFileName: name), options: .atomic)
            index[name] = Entry(size: data.count, lastUsed: Date())
        }
        catch {
            print("Failed to cache response: \(error)")
            return
        }

        evict()
    }

    public func removeAll() {
        try? FileManager.default.removeItem(at: directory)
        index = [:]
        isIndexLoaded = true
    }

    // MARK: - Eviction

    private func loadIndexIfNeeded() {
        guard !isIndexLoaded else { return }
        isIndexLoaded = true

        let keys: Set<URLResourceKey> = [.fileSizeKey, .contentModificationDateKey]
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys))) ?? []
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: keys),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { continue }
            index[url.lastPathComponent] = Entry(size: size, lastUsed: date)
        }

        evict()
    }

    /// Deletes the expired entries, then the least recently used ones until the cache fits into `maxSize`.
    private func evict() {
        let expiryDate = Date().addingTimeInterval(-maxAge)
        for (name, entry) in index where entry.lastUsed < expiryDate {
            remove(name)
        }

        var size = index.values.reduce(0) { $0 + $1.size }
        guard size > maxSize else { return }

        for (name, entry) in index.sorted(by: { $0.value.lastUsed < $1.value.lastUsed }) {
            guard size > maxSize else { break }
            remove(name)
            size -= entry.size
        }
    }

    private func remove(_ name: String) {
        try? FileManager.default.removeItem(at: url(forFileName: name))
        index[name] = nil
    }

    // MARK: - Files

    /// Keys are URLs, which can be too long for a file name.
    private func fileName(forKey key: String) -> String {
        return SHA256.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func url(forFileName name: String) -> URL {
        return directory.appendingPathComponent(name)
    }

}
