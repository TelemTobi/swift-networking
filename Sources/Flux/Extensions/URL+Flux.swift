import Foundation

extension URL {
    
    public mutating func append(queryParameters: [String: Any]) {
        var urlComponents = URLComponents(string: self.absoluteString)
        
        urlComponents?.queryItems = queryParameters.map {
            URLQueryItem(name: $0.key, value: String(describing: $0.value))
        }
        
        self = urlComponents?.url ?? self
    }
}
