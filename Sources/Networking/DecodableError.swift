import Foundation

/// A protocol defining a custom error type that can be decoded from the API response.
public protocol DecodableError: Error, Decodable {
    var type: Networking.Error { get }
    /// Creates a new instance of the error from a `Networking.Error` type.
    init(_ type: Networking.Error)
}

public extension DecodableError {
    static var unknownError: Self { .init(.unknownError(nil)) }
    static var connectionError: Self { .init(.connectionError) }
    static var authenticationError: Self { .init(.authenticationError) }
    
    static func unknownError(_ message: String? = nil) -> Self {
        .init(.unknownError(message))
    }

    static func decodingError(_ message: String) -> Self {
        .init(.decodingError(message))
    }
    
    static func encodingError(_ message: String) -> Self {
        .init(.encodingError(message))
    }
}
