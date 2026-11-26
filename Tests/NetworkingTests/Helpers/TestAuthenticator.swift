import Foundation
@testable import Networking

struct TestInterceptor: Interceptor {
    var authenticationState: AuthenticationState
    var authenticate: @Sendable () -> Bool
    var intercept: @Sendable (inout URLRequest) -> Void
    var refreshAuthentication: @Sendable (URLRequest) -> Bool = { _ in false }
    
    func authenticate() async throws -> Bool {
        authenticate()
    }
    
    func intercept(_ request: inout URLRequest) {
        intercept(&request)
    }
    
    func refreshAuthentication(for request: URLRequest, after error: DecodableError) async -> Bool {
        refreshAuthentication(request)
    }
}
