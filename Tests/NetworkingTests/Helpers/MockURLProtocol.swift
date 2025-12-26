import Foundation

/// URLProtocol mock that serves queued responses for testing URLSession flows.
final class MockURLProtocol: URLProtocol {
    static nonisolated(unsafe) var requestHandlers: [() throws -> (HTTPURLResponse, Data)] = []
    static nonisolated(unsafe) var requestCount = 0
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        Self.requestCount += 1
        
        guard !Self.requestHandlers.isEmpty else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        let handler = Self.requestHandlers.removeFirst()
        
        do {
            let (response, data) = try handler()
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

