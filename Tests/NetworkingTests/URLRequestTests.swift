import XCTest
@testable import Networking

final class URLRequestTests: XCTestCase {

    var testEndpoint = TestEndpoint(
        baseURL: URL(string: "https://google.com")!,
        path: "",
        method: .get,
        task: .none,
        headers: [:],
        keyEncodingStrategy: .convertToSnakeCase,
        dateEncodingStrategy: .iso8601,
        dateDecodingStrategy: .iso8601
    )
    
    func testEndpointURL() throws {
        testEndpoint.path = "/endpoint"
        var urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://google.com/endpoint")
        
        testEndpoint.path = "endpoint"
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.url?.absoluteString, "https://google.com/endpoint")
    }
    
    func testEndpointMethod() throws {
        var urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.httpMethod, "GET")
        
        testEndpoint.method = .post
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.httpMethod, "POST")
        
        testEndpoint.method = .patch
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.httpMethod, "PATCH")
        
        testEndpoint.method = .put
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.httpMethod, "PUT")
        
        testEndpoint.method = .delete
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.httpMethod, "DELETE")
    }
    
    func testEndpointTask() throws {
        // MARK: Empty task
        
        let dateFormatter = ISO8601DateFormatter()
        var urlRequest = try URLRequest(testEndpoint)
        XCTAssertNil(urlRequest.httpBody)
        XCTAssertNil(urlRequest.url?.query?.components(separatedBy: "&"))
        
        // MARK: With body
        
        let testBody = TestBody(someDate: Date(), someCondition: false)
        testEndpoint.task = .encodableBody(testBody)
        urlRequest = try URLRequest(testEndpoint)
        
        XCTAssertEqual(
            try urlRequest.httpBody?.decodeIntoDictionary(),
            ["some_date": dateFormatter.string(from: testBody.someDate), "some_condition": false]
        )
        
        // MARK: With query parameters
        
        testEndpoint.task = .queryParameters(["key1": "1", "key2": 2, "key3": true])
        urlRequest = try URLRequest(testEndpoint)

        XCTAssertEqual(
            Set(urlRequest.url?.query?.components(separatedBy: "&") ?? []),
            Set(["key1=1", "key2=2", "key3=true"])
        )
        
        // MARK: With body and query parameters
        
        testEndpoint.task = .encodableBodyAndQuery(
            body: testBody,
            queryParameters: ["key1": "1", "key2": 2, "key3": true]
        )
        
        urlRequest = try URLRequest(testEndpoint)
        
        XCTAssertEqual(
            try urlRequest.httpBody?.decodeIntoDictionary(),
            ["some_date": dateFormatter.string(from: testBody.someDate), "some_condition": false]
        )
        
        XCTAssertEqual(
            Set(urlRequest.url?.query?.components(separatedBy: "&") ?? []),
            Set(["key1=1", "key2=2", "key3=true"])
        )
    }
    
    func testEndpointHeaders() throws {
        testEndpoint.headers = ["key1": "value1", "key2": "value2"]
        var urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["key1": "value1", "key2": "value2"])
        
        testEndpoint.headers = [:]
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, [:])
        
        testEndpoint.headers = nil
        urlRequest = try URLRequest(testEndpoint)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, [:])
    }
}
