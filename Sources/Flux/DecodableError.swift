import Foundation

/// A protocol defining a custom error type that can be decoded from the API response.
public protocol DecodableError: Error, Decodable {
    /// Creates a new instance of the error from a `Flux.Error` type.
    init(_ type: Flux.Error)
}

public extension DecodableError {
    static var connectionError: Self { .init(.connectionError) }
    static var authenticationError: Self { .init(.authenticationError) }
    static var decodingError: Self { .init(.decodingError) }
    static var unknownError: Self { .init(.unknownError) }
}
