# SoundCloud

[![Twitter: @lbrndnr](https://img.shields.io/badge/contact-@lbrndnr-blue.svg?style=flat)](https://twitter.com/lbrndnr)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/lbrndnr/SoundCloud/blob/master/LICENSE)

## About

`SoundCloud` is a Swift package that implements the private SoundCloud API v2. It allows you to login and request the user stream or system playlists, among others. Note that this API is private. I was not granted access to the API nor its documentation, so this package could break at any given moment. This also means that you should definitely use your own client id, since it's likely to expire at some point.

## Usage

You can login using the following request:
```swift
@State private var subscriptions = Set<AnyCancellable>()

SoundCloud.login(username: username, password: password)
    .receive(on: RunLoop.main)
    .sink(receiveCompletion: { completion in
}, receiveValue: { accessToken in
    print("Logged in with access token: \(accessToken)")
})
.store(in: &subscriptions)
```

Note that it's currently not possible to login using Google accounts that have been granted access to SoundCloud.
A typical request to fetch recommendations on whom to follow can be implemented as follows: 
```swift
@State private var users = [User]()
@State private var subscriptions = Set<AnyCancellable>()

SoundCloud.shared.get(.whoToFollow())
    .map { $0.collection }
    .replaceError(with: [])
    .receive(on: RunLoop.main)
    .map { $0.map { $0.user } }
    .assign(to: \.users, on: self)
    .store(in: &subscriptions)
```
## Requirements
`SoundCloud` is built using Swift 5 and Combine.

## Author
I'm Laurin Brandner, I'm on [Twitter](https://twitter.com/lbrndnr).

## License
`SoundCloud` is licensed under the [MIT License](http://opensource.org/licenses/mit-license.php).
