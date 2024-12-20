import XCTest
@testable import Flux

final class FluxControllerTests: XCTestCase {
    
    var testEndpoint = TestEndpoint(
        baseURL: URL(string: "https://someMadeUpUrl.co.il")!,
        path: "",
        method: .get,
        task: .empty,
        headers: [:],
        keyEncodingStrategy: .convertToSnakeCase,
        dateEncodingStrategy: .iso8601,
        dateDecodingStrategy: .iso8601,
        sampleData: sampleData(fileName: "SampleResponse")
    )
    
    var testAuthenticator = TestAuthenticator(
        state: .notReachable,
        authenticate: { false },
        mapRequest: { _ in }
    )
    
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

    func testAuthentication() async {
        let controller = FluxController<TestEndpoint, TestError>(
            environment: .live,
            authenticator: testAuthenticator
        )
        
        var result: Result<TestResponse, TestError>
        
        // Connection error
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.connectionError))
        
        // Authentication error
        testAuthenticator.state = .notLoggedIn
        controller.authenticator = testAuthenticator
        
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.authenticationError))
        
        testAuthenticator.state = .reachable
        controller.authenticator = testAuthenticator
        
        result = await controller.request(testEndpoint)
        XCTAssertEqual(result, .failure(.connectionError))
    }
    
    func testRequest() async {
        let controller = FluxController<TestEndpoint, TestError>(
            environment: .test,
            authenticator: testAuthenticator
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
        
        XCTAssert(error.debugDescription.hasPrefix("decodingError"))
    }
}
