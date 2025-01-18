import Foundation

/// An enum representing the possible authentication states of a user.
public enum AuthenticationState: Sendable {

    /// User can be authenticated.
    case reachable

    /// No network connection available.
    case notReachable

    /// User needs to sign in.
    case notLoggedIn
}

/// A protocol defining functionalities for an authentication provider.
public protocol Authenticator: Sendable {
    
    /// The current authentication state of the user.
    var state: AuthenticationState { get }

    /// Asynchronously attempts to authenticate the user.
    ///
    /// - Throws: An error if authentication fails.
    /// - Returns: `true` if authentication is successful, `false` otherwise.
    func authenticate() async throws -> Bool
    
    /// Allows the authenticator to modify the `URLRequest` before it's sent.
    ///
    /// This method provides an opportunity for the authenticator to customize the request by adding headers or query parameters. 
    /// This can be useful for including global authentication credentials or other information relevant to all API requests.
    func mapRequest(_ request: inout URLRequest)
}
