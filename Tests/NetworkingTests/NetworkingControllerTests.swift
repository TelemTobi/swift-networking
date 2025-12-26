import XCTest
@testable import Networking

final class NetworkingControllerTests: XCTestCase {
    
    var testEndpoint = TestEndpoint(
        baseURL: URL(string: "https://someMadeUpUrl.co.il")!,
        path: "",
        method: .get,
        task: .none,
        headers: [:],
        keyEncodingStrategy: .convertToSnakeCase,
        dateEncodingStrategy: .iso8601,
        dateDecodingStrategy: .iso8601,
        sampleData: sampleData(fileName: "SampleResponse")
    )
    
    var testInterceptor = TestInterceptor(
        authenticationState: .notReachable,
        authenticate: { false },
        intercept: { _ in }
    )
    
    private func makeEphemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return configuration
    }
    
    fileprivate static func sampleData(fileName: String) -> Data {
        if let filePath = Bundle.module.path(forResource: fileName, ofType: "json") {
            do {
                let stringFromFile = try String(contentsOfFile: filePath)
                return stringFromFile.data(using: .utf8)!
            } catch (let error) {
                fatalError(error.localizedDescription)
            }
        } else {
            fatalError("Sample Json file named \(fileName) not found")
        }
    }

    func testInterceptor() async {
        var controller = NetworkingController<TestEndpoint, TestError>(
            environment: .live,
            interceptor: testInterceptor
        )
        
        var result: Result<TestResponse, TestError>
        
        // Connection error
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.connectionError))
        
        // Authentication error
        testInterceptor.authenticationState = .notLoggedIn
        controller = .init(environment: .live, interceptor: testInterceptor)
        
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.authenticationError))

        // Reachable
        testInterceptor.authenticationState = .reachable
        controller = .init(environment: .live, interceptor: testInterceptor)
        
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.connectionError))
    }
    
    func testRequest() async {
        let controller = NetworkingController<TestEndpoint, TestError>(
            environment: .test,
            interceptor: testInterceptor
        )
        
        var result: Result<TestResponse, TestError>
        
        // Success result
        result = await controller.request(testEndpoint)
        let date = ISO8601DateFormatter().date(from: "1995-05-15T09:40:48Z")
        let expectedResponse = TestResponse(id: 5, name: "Telem Tobi", birthdate: date)
        XCTAssertEqual(result, .success(expectedResponse))
        
        // Decoding error
        testEndpoint.sampleData = Self.sampleData(fileName: "SampleBadResponse")
        
        result = await controller.request(testEndpoint)
        
        guard case let .failure(error) = result else {
            XCTFail("Expected an error but got success")
            return
        }
        
        XCTAssert(error.description.contains("decodingError"))
    }
    
    func testRetryEventuallySucceeds() async {
        let dateString = "1995-05-15T09:40:48Z"
        let responseData = """
        {
            "id": 5,
            "name": "Telem Tobi",
            "birthdate": "\(dateString)"
        }
        """.data(using: .utf8)!
        
        MockURLProtocol.requestHandlers = [
            { throw URLError(.timedOut) },
            {
                let response = HTTPURLResponse(
                    url: URL(string: "https://someMadeUpUrl.co.il")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, responseData)
            }
        ]
        MockURLProtocol.requestCount = 0
        
        var endpoint = testEndpoint
        endpoint.retryCount = 1
        
        let controller = NetworkingController<TestEndpoint, TestError>(
            environment: .live,
            interceptor: TestInterceptor(
                authenticationState: .reachable,
                authenticate: { true },
                intercept: { _ in }
            ),
            configuration: makeEphemeralSessionConfiguration()
        )
        
        let result: Result<TestResponse, TestError> = await controller.request(endpoint)
        
        guard case let .success(response) = result else {
            XCTFail("Expected success after retry, got \(result)")
            return
        }
        
        XCTAssertEqual(response.id, 5)
        XCTAssertEqual(response.name, "Telem Tobi")
        XCTAssertEqual(response.birthdate, ISO8601DateFormatter().date(from: dateString))
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }
    
    func testRetryStopsAfterExhaustingAttempts() async {
        MockURLProtocol.requestHandlers = Array(repeating: { throw URLError(.cannotConnectToHost) }, count: 3)
        MockURLProtocol.requestCount = 0
        
        var endpoint = testEndpoint
        endpoint.retryCount = 2
        
        let controller = NetworkingController<TestEndpoint, TestError>(
            environment: .live,
            interceptor: TestInterceptor(
                authenticationState: .reachable,
                authenticate: { true },
                intercept: { _ in }
            ),
            configuration: makeEphemeralSessionConfiguration()
        )
        
        let result: Result<TestResponse, TestError> = await controller.request(endpoint)
        
        guard case let .failure(error) = result else {
            XCTFail("Expected failure after exhausting retries, got \(result)")
            return
        }
        
        if case .unknownError = error.type {
            // expected
        } else {
            XCTFail("Expected unknownError, got \(error.type)")
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 3)
    }
}
