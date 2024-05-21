import Foundation
@testable import Flux

struct TestAuthenticator: Authenticator {
    
    var state: AuthenticationState
    var authenticate: () -> Bool
    var mapRequest: (inout URLRequest) -> Void
    
    func authenticate() async throws -> Bool {
        authenticate()
    }
    
    func mapRequest(_ request: inout URLRequest) {
        mapRequest(&request)
    }
}
