import Foundation

/// Defines the configuration for a network request, including data and parameters.
public enum HTTPTask {

    /// A request with no additional data in the body or query parameters.
    case empty

    /// A request with query parameters encoded in the URL.
    ///
    /// You can provide a dictionary of `[String: Any]` for the query parameters.
    /// This dictionary can contain values of various types, including strings, numbers, and booleans.
    case withQueryParameters([String: Any])

    /// A request with an `Encodable` object in the body.
    ///
    /// The object will be serialized according to the provided `Encodable` protocol.
    /// You can provide a dictionary of `[String: Any]`, a custom `Encodable` struct,
    /// or any other type conforming to `Encodable`.
    case withBody(Encodable)

    /// A request with an `Encodable` object in the body and query parameters encoded in the URL.
    ///
    /// You can provide a dictionary of `[String: Any]`, a custom `Encodable` struct,
    /// or any other type conforming to `Encodable` for the body.
    ///
    /// Provide a dictionary of `[String: Any]` for the query parameters.
    /// This dictionary can contain values of various types, including strings, numbers, and booleans.
    case withBodyAndQueryParameters(Encodable, parameters: [String: Any])
}
