import Foundation

public extension URLRequest {
    
    /// Initializes a `URLRequest` from an `Endpoint` instance.
    init(_ endpoint: Endpoint) throws {
        let url = if endpoint.path.isEmpty {
            endpoint.baseURL
        } else {
            endpoint.baseURL.appendingPathComponent(endpoint.path)
        }
        
        self.init(url: url)
        self.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { (key, value) in
            self.setValue(value, forHTTPHeaderField: key)
        }
        
        switch endpoint.task {
        case .empty:
            break
                
        case let .withBody(encodable):
            let jsonEncoder = JSONEncoder()
            jsonEncoder.keyEncodingStrategy = endpoint.keyEncodingStrategy
            jsonEncoder.dateEncodingStrategy = endpoint.dateEncodingStrategy
            self.httpBody = try jsonEncoder.encode(encodable)
                
        case let .withQueryParameters(parameters):
            self.url?.append(queryParameters: parameters)
                
        case let .withBodyAndQueryParameters(encodable, parameters):
            let jsonEncoder = JSONEncoder()
            jsonEncoder.keyEncodingStrategy = endpoint.keyEncodingStrategy
            jsonEncoder.dateEncodingStrategy = endpoint.dateEncodingStrategy
            self.httpBody = try jsonEncoder.encode(encodable)
            self.url?.append(queryParameters: parameters)
        }
    }
}
