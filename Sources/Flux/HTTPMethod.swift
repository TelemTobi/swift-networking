import Foundation

/// The HTTP method used in a network request.
public enum HTTPMethod: String {

    /// `CONNECT` method.
    case connect

    /// `DELETE` method.
    case delete

    /// `GET` method.
    case get

    /// `HEAD` method.
    case head

    /// `OPTIONS` method.
    case options

    /// `PATCH` method.
    case patch

    /// `POST` method.
    case post

    /// `PUT` method.
    case put

    /// **Deprecated:** Use `GET` instead.
    case query

    /// `TRACE` method.
    case trace
}
