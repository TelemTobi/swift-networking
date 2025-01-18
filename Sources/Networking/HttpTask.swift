import Foundation

/// Defines the configuration for a network request, specifying how data is included in the request body or query parameters.
public enum HttpTask: Sendable {

    /// A request with no additional data.
    ///
    /// Use this for requests that do not require a body or query parameters.
    case none

    /// A request with query parameters encoded into the URL.
    ///
    /// - Parameter parameters: A dictionary of `[String: Any]` representing the query parameters.
    ///   Values can include strings, numbers, booleans, and other JSON-compatible types.
    case queryParameters(_ parameters: [String: any Sendable])

    /// A request with a dictionary of data in the body.
    ///
    /// - Parameter body: A dictionary of `[String: Any]` containing the data to be included in the request body.
    ///   This is useful for requests that require non-Encodable objects or manual key-value data.
    case rawBody(_ body: [String: any Sendable])
    
    /// A request with data encoded in the body.
    ///
    /// - Parameter encodable: An `Encodable` object representing the request body. This could be a dictionary,
    ///   a custom struct, or any type conforming to `Encodable`, which will be serialized using the provided encoding strategies.
    case encodableBody(_ encodable: Encodable & Sendable)

    /// A request with both body data and query parameters.
    ///
    /// - Parameters:
    ///   - body: A dictionary of `[String: Any]` containing the data to be included in the request body.
    ///   - queryParameters: A dictionary of `[String: Any]` representing the query parameters.
    ///     Both dictionaries should include JSON-compatible types such as strings, numbers, and booleans.
    case rawBodyAndQuery(body: [String: any Sendable], queryParameters: [String: any Sendable])

    /// A request with an `Encodable` object in the body and query parameters encoded in the URL.
    ///
    /// - Parameters:
    ///   - encodable: An `Encodable` object representing the request body. This could be a dictionary,
    ///     a custom struct, or any type conforming to `Encodable`.
    ///   - queryParameters: A dictionary of `[String: Any]` representing the query parameters.
    ///     Values can include strings, numbers, booleans, and other JSON-compatible types.
    case encodableBodyAndQuery(body: Encodable & Sendable, queryParameters: [String: any Sendable])

}
