# SoundCloud

[![Twitter: @lbrndnr](https://img.shields.io/badge/contact-@lbrndnr-blue.svg?style=flat)](https://twitter.com/lbrndnr)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/lbrndnr/SoundCloud/blob/master/LICENSE)

## About

`SoundCloud` is a Swift package that implements the private SoundCloud API v2. It allows you to login and request the user stream or system playlists, among others. Note that this API is private. I was not granted access to the API nor its documentation, so this package could break at any given moment. This also means that you should definitely use your own client id, since it's likely to expire at some point.

## Usage

`SoundCloud` doesn't handle the login itself. Once you have an OAuth token (e.g. from the `oauth_token` cookie after signing in on soundcloud.com), set it on the shared instance. This also loads the logged in user:
```swift
SoundCloud.shared.accessToken = accessToken
```

`SoundCloud` is `@Observable`, so SwiftUI views reading `SoundCloud.shared.user` update once the user is loaded.

Requests are `async` and throw on failure. A typical request to fetch recommendations on whom to follow can be implemented as follows:
```swift
@State private var users = [User]()

var body: some View {
    List(users) { user in
        Text(user.username)
    }
    .task {
        do {
            users = try await SoundCloud.shared.get(.whoToFollow()).collection.map { $0.user }
        }
        catch {
            print("Failed to load recommendations: \(error)")
        }
    }
}
```

Paginated requests return a `Page`, use `get(next:)` to load the following one, or `get(all:)` to load all elements at once.

## Requirements
`SoundCloud` requires Swift 5.9, macOS 14 or iOS 17.

## Author
I'm Laurin Brandner, I'm on [Twitter](https://twitter.com/lbrndnr).

## License
`SoundCloud` is licensed under the [MIT License](http://opensource.org/licenses/mit-license.php).
