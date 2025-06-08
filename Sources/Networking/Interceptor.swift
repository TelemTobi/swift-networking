import Foundation

/// A protocol defining functionalities for intercepting and modifying network requests and responses.
public protocol Interceptor: Sendable {
    /// The current authentication state of the user.
    var authenticationState: AuthenticationState { get }

    /// Asynchronously attempts to authenticate the user.
    ///
    /// - Throws: An error if authentication fails.
    /// - Returns: `true` if authentication is successful, `false` otherwise.
    func authenticate() async throws -> Bool
    
    /// Allows the interceptor to modify the `URLRequest` before it's sent.
    ///
    /// This method provides an opportunity to customize the request by adding headers, query parameters,
    /// or modifying any other request properties. This can be useful for including authentication credentials,
    /// device information, or other information relevant to all API requests.
    ///
    /// - Parameter request: The URLRequest that will be modified.
    func intercept(_ request: inout URLRequest)
    
    /// Allows the interceptor to process or modify the response data before decoding.
    ///
    /// This method is called after receiving the response data but before any decoding takes place.
    /// It can be used to transform, validate, or modify the raw response data. Common use cases include:
    /// - Decrypting encrypted responses
    /// - Modifying response format to match your model structure
    /// - Validating response integrity
    ///
    /// - Parameter data: The response data that can be modified.
    func intercept(_ data: inout Data)
    
    /// Allows the interceptor to process or handle errors before they are thrown.
    ///
    /// This method is called when an error occurs during the request lifecycle, before it's thrown to the caller.
    /// It can be used to:
    /// - Log errors
    /// - Modify error information
    /// - Trigger error-specific workflows (like authentication refresh on 401 errors)
    ///
    /// - Parameter error: The error that occurred during the request.
    func intercept(_ error: DecodableError)
}

public extension Interceptor {
    var authenticationState: AuthenticationState { .reachable }
    func authenticate() async throws -> Bool { true }
    func intercept(_ request: inout URLRequest) {}
    func intercept(_ data: inout Data) {}
    func intercept(_ error: DecodableError) {}
}

/// An enum representing the possible authentication states of a user.
public enum AuthenticationState: Sendable {
    /// User can be authenticated.
    case reachable
    
    /// No network connection available.
    case notReachable
    
    /// User needs to sign in.
    case notLoggedIn
}
