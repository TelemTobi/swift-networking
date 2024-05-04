import Foundation

public extension URLRequest {
    
    /// Initializes a `URLRequest` from an `Endpoint` instance.
    init(_ endpoint: Endpoint) {
        self.init(url: endpoint.baseURL.appending(path: endpoint.path))
        self.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { (key, value) in
            self.setValue(value, forHTTPHeaderField: key)
        }
        
        switch endpoint.task {
        case .empty:
                break
                
        case let .withBody(encodable):
                self.httpBody = try? JSONEncoder().encode(encodable)
                
        case let .withQueryParameters(parameters):
            self.url?.append(queryItems: parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) })
                
        case let .withBodyAndQueryParameters(encodable, parameters):
                self.httpBody = try? JSONEncoder().encode(encodable)
                self.url?.append(queryItems: parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) })
        }
    }
}
