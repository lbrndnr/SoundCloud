//
//  SoundCloud.swift
//  Nuage
//
//  Created by Laurin Brandner on 18.12.19.
//  Copyright © 2019 Laurin Brandner. All rights reserved.
//

import Foundation
import Combine

public struct AuthenticationError: Error {}

public class SoundCloud: ObservableObject {
    
    public static var shared = SoundCloud()
    
    @Published public var user: User?
    public var accessToken: String? {
        didSet {
            get(.me())
                .receive(on: RunLoop.main)
                .map { Optional($0) }
                .replaceError(with: user)
                .filter { $0 != nil }
                .assign(to: \.user, on: self)
                .store(in: &subscriptions)
        }
    }
    
    private var decoder: JSONDecoder
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
    }
    
    // MARK: - Authentication
    
    private func authorized<T>(_ request: APIRequest<T>, queryItems: [URLQueryItem] = []) -> URLRequest {
        let url = URL(string: "https://api-v2.soundcloud.com/\(request.path)")!
        var items = queryItems
        if let parameters = request.queryParameters {
            items += zip(parameters.keys, parameters.values).map { URLQueryItem(name: $0.0, value: $0.1)}
        }
        
        var req = authorized(url, queryItems: items)
        req.httpMethod = request.httpMethod
        
        if let body = request.jsonBody {
            req.httpBody = try! JSONSerialization.data(withJSONObject: body)
        }
        
        return req
    }
    
    private func authorized(_ url: URL, queryItems: [URLQueryItem] = []) -> URLRequest {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let authItems = [URLQueryItem(name: "oauth_token", value: accessToken!)]
        
        let explicitItems = authItems + queryItems
        let explicitKeys = explicitItems.map { $0.name }
        let urlItems = components.queryItems?.filter { !explicitKeys.contains($0.name) }
        components.queryItems = (urlItems ?? []) + explicitItems
        
        return URLRequest(url: components.url!)
    }
    
    // MARK: - Requests
    
    public func get<T: Decodable>(all request: APIRequest<Slice<T>>) -> AnyPublisher<[T], Error> {
        if request.needsUserID && user == nil {
            return Fail(error: NoUserError())
                .eraseToAnyPublisher()
        }
        
        let queryItems = [URLQueryItem(name: "limit", value: "150")]
        let request = authorized(request, queryItems: queryItems)
        let subject = CurrentValueSubject<URLRequest, Error>(request)
        
        let getRequest: (URLRequest) -> AnyPublisher<Slice<T>, Error> = self.get
        
        return subject
            .flatMap(getRequest)
            .handleEvents(receiveOutput: { slice in
                if let next = slice.next {
                    let request = self.authorized(next, queryItems: queryItems)
                    subject.send(request)
                }
                else {
                    subject.send(completion: .finished)
                }
            })
            .reduce([T]()) { $0 + $1.collection }
            .eraseToAnyPublisher()
    }
    
    public func get<T: Decodable>(_ request: APIRequest<T>) -> AnyPublisher<T, Error> {
        if request.needsUserID && user == nil {
            return Fail(error: NoUserError())
                .eraseToAnyPublisher()
        }
        
        return get(authorized(request))
    }
    
    public func get<T: Decodable>(_ request: APIRequest<Slice<T>>, count: Int) -> AnyPublisher<Slice<T>, Error> {
        if request.needsUserID && user == nil {
            return Fail(error: NoUserError())
                .eraseToAnyPublisher()
        }
        
        let queryItems = [URLQueryItem(name: "limit", value: "150")]
        let request = authorized(request, queryItems: queryItems)
        let subject = CurrentValueSubject<URLRequest, Error>(request)
        
        let getRequest: (URLRequest) -> AnyPublisher<Slice<T>, Error> = self.get
        var currentCount = 0
        
        return subject
            .flatMap(getRequest)
            .handleEvents(receiveOutput: { slice in
                currentCount += slice.collection.count
                
                if let next = slice.next, currentCount < count {
                    let request = self.authorized(next, queryItems: queryItems)
                    print("get next")
                    subject.send(request)
                }
                else {
                    subject.send(completion: .finished)
                }
            })
            .collect()
            .tryMap { slices in
                guard var newSlice = slices.last else { return Slice(collection: []) }
                newSlice.collection = slices.reduce([]) { $0 + $1.collection }
                
                return newSlice
            }
            .eraseToAnyPublisher()
    }
    
    public func get<T: Decodable>(_ request: APIRequest<Slice<T>>, limit: Int? = 20) -> AnyPublisher<Slice<T>, Error> {
        if request.needsUserID && user == nil {
            return Fail(error: NoUserError())
                .eraseToAnyPublisher()
        }
        
        let queryItems = limit.map { [URLQueryItem(name: "limit", value: String(min($0, 150)))] }
        return get(authorized(request, queryItems: queryItems ?? []))
    }
    
    public func get<T: Decodable>(next slice: Slice<T>, limit: Int = 20) -> AnyPublisher<Slice<T>, Error> {
        guard let next = slice.next else {
            return Fail(error: NoNextSliceError())
                .eraseToAnyPublisher()
        }
        
        return get(next: next, limit: limit)
    }
    
    public func get<T: Decodable>(next: URL, limit: Int = 20) -> AnyPublisher<Slice<T>, Error> {
        let queryItems = [URLQueryItem(name: "limit", value: String(min(limit, 150)))]
        let request = authorized(next, queryItems: queryItems)
        return get(request)
    }
    
    private func get<T: Decodable>(_ request: URLRequest) -> AnyPublisher<T, Error> {
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func get<T: Decodable>(_ request: ResourceRequest<T>) -> AnyPublisher<T, Error> {
        let req = request.needsAuthorization ? authorized(request.url) : URLRequest(url: request.url)
        let publisher = URLSession.shared.dataTaskPublisher(for: req)
        
        if let decoder = request.decoder {
            return publisher.tryMap { data, _ in
                let payload = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [AnyHashable: Any]
                return try decoder(payload)
            }.eraseToAnyPublisher()
        }
            
        return publisher
            .map { $0.data }
            .decode(type: T.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    public func perform(_ request: APIRequest<String>) -> AnyPublisher<(), Error> {
        return URLSession.shared.dataTaskPublisher(for: authorized(request))
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
}
