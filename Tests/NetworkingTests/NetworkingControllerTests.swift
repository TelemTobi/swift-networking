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
    
    private func makeEphemeralSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
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
            urlSession: makeEphemeralSession(),
            environment: .live,
            interceptor: TestInterceptor(
                authenticationState: .reachable,
                authenticate: { true },
                intercept: { _ in }
            )
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
            urlSession: makeEphemeralSession(),
            environment: .live,
            interceptor: TestInterceptor(
                authenticationState: .reachable,
                authenticate: { true },
                intercept: { _ in }
            )
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
    
    func testUnauthorizedIsRetriedOnceAfterRefreshingAuthentication() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        let authentications = Counter()
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: authentications,
            refreshAuthentication: { true }
        ).request(testEndpoint)
        
        guard case .success = result else {
            XCTFail("Expected success after refreshing authentication, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
        XCTAssertEqual(authentications.value, 1)
    }
    
    func testUnauthorizedIsThrownWhenAuthenticationIsNotRefreshed() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: { false }
        ).request(testEndpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the 401 to be thrown, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testUnauthorizedRetryHappensOnlyOnce() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: { true }
        ).request(testEndpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the second 401 to be thrown, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
    }
    
    func testOtherFailuresDoNotRefreshAuthentication() async {
        MockURLProtocol.requestHandlers = [{ try self.response(status: 500) }, successResponse]
        MockURLProtocol.requestCount = 0
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: { true }
        ).request(testEndpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the 500 to be thrown, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testDefaultInterceptorDoesNotRefreshAuthentication() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        
        let controller = NetworkingController<TestEndpoint, TestError>(
            urlSession: makeEphemeralSession(),
            environment: .live,
            interceptor: DefaultInterceptor()
        )
        
        let result: Result<TestResponse, TestError> = await controller.request(testEndpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the 401 to be thrown, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }
    
    func testUnauthorizedRefreshesAuthenticationBeforeRetrying() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        let refreshes = Counter()
        
        var endpoint = testEndpoint
        endpoint.retryCount = 2
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: {
                refreshes.increment()
                return true
            }
        ).request(endpoint)
        
        guard case .success = result else {
            XCTFail("Expected success after refreshing authentication, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
        XCTAssertEqual(refreshes.value, 1)
    }
    
    func testUnauthorizedRefreshIsAskedOnceAcrossRetries() async {
        MockURLProtocol.requestHandlers = Array(repeating: unauthorizedResponse, count: 3)
        MockURLProtocol.requestCount = 0
        let refreshes = Counter()
        
        var endpoint = testEndpoint
        endpoint.retryCount = 2
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: {
                refreshes.increment()
                return false
            }
        ).request(endpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the 401 to be thrown after exhausting retries, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 3)
        XCTAssertEqual(refreshes.value, 1)
    }
    
    func testUnauthorizedResendKeepsRetryCount() async {
        MockURLProtocol.requestHandlers = Array(repeating: unauthorizedResponse, count: 4)
        MockURLProtocol.requestCount = 0
        let refreshes = Counter()
        
        var endpoint = testEndpoint
        endpoint.retryCount = 2
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            refreshAuthentication: {
                refreshes.increment()
                return true
            }
        ).request(endpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the 401 to be thrown after exhausting retries, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 4)
        XCTAssertEqual(refreshes.value, 1)
    }
    
    func testOutdatedCredentialsAreResentWithoutRefreshing() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        let refreshes = Counter()
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            intercept: { $0.setValue("Bearer outdated", forHTTPHeaderField: "Authorization") },
            hasRefreshedCredentials: { $0.value(forHTTPHeaderField: "Authorization") == "Bearer outdated" },
            refreshAuthentication: {
                refreshes.increment()
                return false
            }
        ).request(testEndpoint)
        
        guard case .success = result else {
            XCTFail("Expected success after resending with the current credentials, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
        XCTAssertEqual(refreshes.value, 0)
    }
    
    func testOutdatedCredentialsAreResentOnlyOnce() async {
        MockURLProtocol.requestHandlers = [unauthorizedResponse, unauthorizedResponse, successResponse]
        MockURLProtocol.requestCount = 0
        let refreshes = Counter()
        
        let result: Result<TestResponse, TestError> = await authenticatedController(
            authentications: Counter(),
            hasRefreshedCredentials: { _ in true },
            refreshAuthentication: {
                refreshes.increment()
                return true
            }
        ).request(testEndpoint)
        
        guard case .failure = result else {
            XCTFail("Expected the second 401 to be thrown, got \(result)")
            return
        }
        
        XCTAssertEqual(MockURLProtocol.requestCount, 2)
        XCTAssertEqual(refreshes.value, 0)
    }
    
    private var unauthorizedResponse: () throws -> (HTTPURLResponse, Data) {
        { try self.response(status: 401) }
    }
    
    private var successResponse: () throws -> (HTTPURLResponse, Data) {
        { try self.response(status: 200, data: Self.sampleData(fileName: "SampleResponse")) }
    }
    
    private func response(status: Int, data: Data = Data()) throws -> (HTTPURLResponse, Data) {
        let url = try XCTUnwrap(URL(string: "https://someMadeUpUrl.co.il"))
        let response = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
        return (response, data)
    }
    
    private func authenticatedController(
        authentications: Counter,
        intercept: @escaping @Sendable (inout URLRequest) -> Void = { _ in },
        hasRefreshedCredentials: @escaping @Sendable (URLRequest) -> Bool = { _ in false },
        refreshAuthentication: @escaping @Sendable () -> Bool
    ) -> NetworkingController<TestEndpoint, TestError> {
        NetworkingController(
            urlSession: makeEphemeralSession(),
            environment: .live,
            interceptor: TestInterceptor(
                authenticationState: .reachable,
                authenticate: {
                    authentications.increment()
                    return true
                },
                intercept: intercept,
                hasRefreshedCredentials: hasRefreshedCredentials,
                refreshAuthentication: refreshAuthentication
            )
        )
    }
}

private struct DefaultInterceptor: Interceptor {}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    
    var value: Int { lock.withLock { count } }
    
    func increment() { lock.withLock { count += 1 } }
}
