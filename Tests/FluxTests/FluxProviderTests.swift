import XCTest
@testable import Flux

final class FluxProviderTests: XCTestCase {
    
    var testEndpoint = TestEndpoint(
        baseURL: URL(string: "https://someMadeUpUrl.co.il")!,
        path: "",
        method: .get,
        task: .empty,
        headers: [:],
        keyEncodingStrategy: .convertToSnakeCase,
        dateEncodingStrategy: .iso8601
    )
    
    var testAuthenticator = TestAuthenticator(
        state: .notReachable,
        authenticate: { false },
        mapRequest: { _ in }
    )
    
    func testAuthentication() async {
        var provider = FluxProvider<TestEndpoint, TestError>(
            authenticator: testAuthenticator,
            environment: .live
        )
        
        var result: Result<TestResponse, TestError>
        
        // Connection error
        result = await provider.request(testEndpoint)
        XCTAssertEqual(result, .failure(.connectionError))
        
        // Authentication error
        testAuthenticator.state = .notLoggedIn
        provider.authenticator = testAuthenticator
        
        result = await provider.request(testEndpoint)
        XCTAssertEqual(result, .failure(.authenticationError))
        
        testAuthenticator.state = .reachable
        provider.authenticator = testAuthenticator
        
        result = await provider.request(testEndpoint)
        XCTAssertEqual(result, .failure(.authenticationError))
    }
    
    func testRequest() async {
        
    }
}
