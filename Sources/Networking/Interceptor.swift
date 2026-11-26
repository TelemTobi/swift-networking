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
    /// - Trigger error-specific workflows
    ///
    /// To renew credentials and resend a request after a 401, implement ``refreshAuthentication(after:)`` instead.
    ///
    /// - Parameter error: The error that occurred during the request.
    func intercept(_ error: DecodableError)

    /// Renews the credentials after the server refused them with `401 Unauthorized`, for example by
    /// force-refreshing an expired access token.
    ///
    /// Called on the first 401, before any retry from the endpoint's `retryCount`. Return `true` and the controller
    /// authenticates again with ``authenticate()`` and resends the request with the renewed credentials. The resend
    /// doesn't reset the retry count, so a request makes at most `retryCount + 2` attempts. This is called at most
    /// once per request, whatever it returns, so it can't loop. Only the final error reaches
    /// ``intercept(_:)-(DecodableError)``.
    ///
    /// Requests that fail at the same time each call this method. Renew the credentials once for all of them,
    /// for example by having every caller await the same in-flight refresh task.
    ///
    /// - Parameter error: The 401 error, for APIs that tell refusal reasons apart.
    /// - Returns: `true` when the credentials were renewed. Defaults to `false`, which keeps the existing behavior:
    ///   the 401 is retried according to `retryCount`, then thrown.
    func refreshAuthentication(after error: DecodableError) async -> Bool
}

public extension Interceptor {
    var authenticationState: AuthenticationState { .reachable }
    func authenticate() async throws -> Bool { true }
    func intercept(_ request: inout URLRequest) {}
    func intercept(_ data: inout Data) {}
    func intercept(_ error: DecodableError) {}
    func refreshAuthentication(after error: DecodableError) async -> Bool { false }
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
