import Foundation
@testable import Networking

struct TestAuthenticator: Authenticator {
    
    var state: AuthenticationState
    var authenticate: @Sendable () -> Bool
    var mapRequest: @Sendable (inout URLRequest) -> Void
    
    func authenticate() async throws -> Bool {
        authenticate()
    }
    
    func mapRequest(_ request: inout URLRequest) {
        mapRequest(&request)
    }
}
