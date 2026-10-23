//
//  SoundCloud.swift
//  Nuage
//
//  Created by Laurin Brandner on 18.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation
import Observation

public struct AuthenticationError: Error {}

public struct HTTPError: Error {

    public var statusCode: Int

}

/// The entry point for requests to SoundCloud's private API v2.
///
/// Requests fail with an `AuthenticationError` when there is no access token,
/// with a `NoUserError` when they need the logged in user before it's loaded
/// and with an `HTTPError` on non-2xx responses.
@MainActor
@Observable
public final class SoundCloud {

    public static let shared = SoundCloud()

    /// The logged in user. It's loaded whenever `accessToken` is set.
    public var user: User?

    public var accessToken: String? {
        didSet {
            reloadUser()
        }
    }

    @ObservationIgnored private var userTask: Task<Void, Never>?

    init() {}

    private func reloadUser() {
        userTask?.cancel()
        guard accessToken != nil else {
            userTask = nil
            return
        }

        userTask = Task {
            do {
                user = try await get(.me())
            }
            catch {
                // Keep the current user, e.g. the one restored from disk
                guard !Task.isCancelled else { return }
                print("Failed to load the user: \(error)")
            }
        }
    }

    // MARK: - Requests

    public func get<T: Decodable & Sendable>(_ request: APIRequest<T>) async throws -> T {
        return try await Self.decoded(authorized(request))
    }

    public func get<T: Decodable & Sendable>(_ request: APIRequest<Page<T>>, limit: Int? = 20) async throws -> Page<T> {
        let queryItems = limit.map { [URLQueryItem(name: "limit", value: String(min($0, 150)))] }
        return try await Self.decoded(authorized(request, queryItems: queryItems ?? []))
    }

    /// Loads pages until at least `count` elements are loaded or there are no more pages.
    /// The returned page contains all loaded elements and points to the page after the last loaded one.
    public func get<T: Decodable & Sendable>(_ request: APIRequest<Page<T>>, count: Int) async throws -> Page<T> {
        let queryItems = [URLQueryItem(name: "limit", value: "150")]
        var page: Page<T> = try await Self.decoded(authorized(request, queryItems: queryItems))
        var collection = page.collection

        while collection.count < count, let next = page.next {
            page = try await Self.decoded(authorized(next, queryItems: queryItems))
            collection += page.collection
        }

        page.collection = collection
        return page
    }

    /// Loads all pages and returns their elements.
    public func get<T: Decodable & Sendable>(all request: APIRequest<Page<T>>) async throws -> [T] {
        let queryItems = [URLQueryItem(name: "limit", value: "150")]
        var page: Page<T> = try await Self.decoded(authorized(request, queryItems: queryItems))
        var collection = page.collection

        while let next = page.next {
            page = try await Self.decoded(authorized(next, queryItems: queryItems))
            collection += page.collection
        }

        return collection
    }

    public func get<T: Decodable & Sendable>(next page: Page<T>, limit: Int = 20) async throws -> Page<T> {
        guard let next = page.next else { throw NoNextPageError() }

        return try await get(next: next, limit: limit)
    }

    public func get<T: Decodable & Sendable>(next: URL, limit: Int = 20) async throws -> Page<T> {
        let queryItems = [URLQueryItem(name: "limit", value: String(min(limit, 150)))]
        return try await Self.decoded(authorized(next, queryItems: queryItems))
    }

    public func get<T: Decodable & Sendable>(_ request: ResourceRequest<T>) async throws -> T {
        let urlRequest = try request.needsAuthorization ? authorized(request.url) : URLRequest(url: request.url)
        return try await Self.decoded(urlRequest, using: request)
    }

    /// Performs a request whose response body isn't needed, e.g. liking a track.
    public func perform<T>(_ request: APIRequest<T>) async throws {
        _ = try await Self.data(for: authorized(request))
    }

    // MARK: - Authorization

    func authorized<T>(_ request: APIRequest<T>, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        if request.needsUserID && user == nil {
            throw NoUserError()
        }

        let url = URL(string: "https://api-v2.soundcloud.com/\(request.path(userID: user?.id))")!
        var items = queryItems
        if let parameters = request.queryParameters {
            items += parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var req = try authorized(url, queryItems: items)
        req.httpMethod = request.httpMethod

        if let body = request.jsonBody {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return req
    }

    func authorized(_ url: URL, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard let accessToken = accessToken else { throw AuthenticationError() }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }

        let explicitItems = [URLQueryItem(name: "oauth_token", value: accessToken)] + queryItems
        let explicitKeys = explicitItems.map { $0.name }
        let urlItems = components.queryItems?.filter { !explicitKeys.contains($0.name) }
        components.queryItems = (urlItems ?? []) + explicitItems

        guard let authorizedURL = components.url else { throw URLError(.badURL) }
        return URLRequest(url: authorizedURL)
    }

    // MARK: - Loading

    // These are nonisolated, so that loading and decoding happens off the main actor.

    nonisolated private static func decoded<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        let data = try await data(for: request)
        return try makeDecoder().decode(T.self, from: data)
    }

    nonisolated private static func decoded<T: Decodable & Sendable>(_ request: URLRequest, using resource: ResourceRequest<T>) async throws -> T {
        let data = try await data(for: request)

        if let resourceDecoder = resource.decoder {
            guard let payload = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [AnyHashable: Any] else {
                throw ParseError()
            }
            return try resourceDecoder(payload)
        }

        return try makeDecoder().decode(T.self, from: data)
    }

    nonisolated private static func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw HTTPError(statusCode: response.statusCode)
        }

        return data
    }

    nonisolated private static func makeDecoder() -> JSONDecoder {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)

        return decoder
    }

}
