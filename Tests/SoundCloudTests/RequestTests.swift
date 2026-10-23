import Foundation
import Testing
@testable import SoundCloud

/// Answers requests of `URLSession.shared` with canned responses, keyed by the URL path.
private final class StubURLProtocol: URLProtocol {

    struct Response {
        var statusCode = 200
        var body: String
    }

    nonisolated(unsafe) static var responses = [String: Response]()
    nonisolated(unsafe) static var requests = [URLRequest]()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)

        let url = request.url!
        let stub = Self.responses[url.path] ?? Response(statusCode: 404, body: "{}")
        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(stub.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

}

private let userJSON = """
{
    "id": 1,
    "username": "user",
    "first_name": "First",
    "last_name": "Last",
    "full_name": "First Last",
    "avatar_url": "https://i1.sndcdn.com/avatar.jpg"
}
"""

private func followingsPage(ids: ClosedRange<Int>, next: String?) -> String {
    let users = ids.map { userJSON.replacingOccurrences(of: "\"id\": 1", with: "\"id\": \($0)") }
    let next = next.map { "\"https://api-v2.soundcloud.com\($0)\"" } ?? "null"
    return "{ \"collection\": [\(users.joined(separator: ","))], \"next_href\": \(next) }"
}

private let user = User(id: "1", username: "user", firstName: "First", lastName: "Last", avatarURL: URL(string: "https://i1.sndcdn.com/avatar.jpg")!)

// Serialized, since the stubs are shared global state
@MainActor
@Suite("Requests", .serialized)
struct RequestTests {

    private let soundCloud: SoundCloud

    init() {
        URLProtocol.registerClass(StubURLProtocol.self)
        StubURLProtocol.responses = [:]
        StubURLProtocol.requests = []

        soundCloud = SoundCloud()
        soundCloud.accessToken = "token"
    }

    @Test func getDecodesResponse() async throws {
        StubURLProtocol.responses["/users/1"] = .init(body: userJSON)

        let user = try await soundCloud.get(.user(with: "1"))
        #expect(user.username == "user")

        let request = try #require(StubURLProtocol.requests.last(where: { $0.url?.path == "/users/1" }))
        #expect(request.url?.query?.contains("oauth_token=token") == true)
    }

    @Test func getAllFollowsNextPages() async throws {
        StubURLProtocol.responses["/users/1/followings"] = .init(body: followingsPage(ids: 1...2, next: "/page2"))
        StubURLProtocol.responses["/page2"] = .init(body: followingsPage(ids: 3...4, next: "/page3"))
        StubURLProtocol.responses["/page3"] = .init(body: followingsPage(ids: 5...5, next: nil))

        let users = try await soundCloud.get(all: .followings(of: user))
        #expect(users.map(\.id) == ["1", "2", "3", "4", "5"])
    }

    @Test func getCountStopsOnceEnoughElementsAreLoaded() async throws {
        StubURLProtocol.responses["/users/1/followings"] = .init(body: followingsPage(ids: 1...2, next: "/page2"))
        StubURLProtocol.responses["/page2"] = .init(body: followingsPage(ids: 3...4, next: "/page3"))

        let page = try await soundCloud.get(.followings(of: user), count: 3)
        #expect(page.collection.map(\.id) == ["1", "2", "3", "4"])
        #expect(page.next?.path == "/page3")
        #expect(!StubURLProtocol.requests.contains { $0.url?.path == "/page3" })
    }

    @Test func getNextFailsWithoutNextPage() async throws {
        let page = Page<User>(collection: [], next: nil)

        await #expect(throws: NoNextPageError.self) {
            let _: Page<User> = try await soundCloud.get(next: page)
        }
    }

    @Test func performFailsOnHTTPError() async throws {
        StubURLProtocol.responses["/me/track_reposts/42"] = .init(statusCode: 403, body: "{}")
        let track = try #require(try trackWithID("42"))

        await #expect {
            try await soundCloud.perform(.repost(track))
        } throws: { error in
            (error as? HTTPError)?.statusCode == 403
        }
    }

    @Test func requestsFailWithoutAccessToken() async throws {
        let soundCloud = SoundCloud()

        await #expect(throws: AuthenticationError.self) {
            try await soundCloud.get(.user(with: "1"))
        }
    }

    @Test func requestsNeedingAUserFailWithoutOne() async throws {
        let track = try #require(try trackWithID("42"))

        await #expect(throws: NoUserError.self) {
            try await soundCloud.perform(.addToHistory(track))
        }
    }

    private func trackWithID(_ id: String) throws -> Track? {
        let json = """
        {
            "id": "\(id)",
            "title": "Track",
            "waveform_url": "https://wave.sndcdn.com/x_m.json",
            "permalink_url": "https://soundcloud.com/user/track",
            "duration": 1,
            "created_at": 0,
            "user": \(userJSON)
        }
        """
        return try JSONDecoder().decode(Track.self, from: Data(json.utf8))
    }

}
