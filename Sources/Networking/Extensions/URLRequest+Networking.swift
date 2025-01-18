import Foundation

public extension URLRequest {
    
    /// Initializes a `URLRequest` from an `Endpoint` instance.
    init(_ endpoint: Endpoint) throws(Networking.Error) {
        let url = if endpoint.path.isEmpty {
            endpoint.baseURL
        } else {
            endpoint.baseURL.appendingPathComponent(endpoint.path.ensurePrefix("/"))
        }
        
        self.init(url: url)
        self.httpMethod = endpoint.method.rawValue
        
        endpoint.headers?.forEach { (key, value) in
            self.setValue(value, forHTTPHeaderField: key)
        }
        
        switch endpoint.task {
        case .none:
            break
                
        case let .rawBody(dictionary):
            do {
                self.httpBody = try dictionary.encode(using: endpoint)
            } catch {
                throw .encodingError(error.description)
            }
            
        case let .encodableBody(encodable):
            do {
                self.httpBody = try encodable.encode(using: endpoint)
            } catch {
                throw .encodingError(error.description)
            }
                
        case let .queryParameters(parameters):
            self.url?.append(queryParameters: parameters)
                
        case let .rawBodyAndQuery(dictionary, parameters):
            self.url?.append(queryParameters: parameters)
            
            do {
                self.httpBody = try dictionary.encode(using: endpoint)
            } catch {
                throw .encodingError(error.description)
            }
            
        case let .encodableBodyAndQuery(encodable, parameters):
            self.url?.append(queryParameters: parameters)
            
            do {
                self.httpBody = try encodable.encode(using: endpoint)
            } catch {
                throw .encodingError(error.description)
            }
        }
    }
}

fileprivate extension Encodable {
    func encode(using endpoint: Endpoint) throws -> Data {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = endpoint.keyEncodingStrategy
        jsonEncoder.dateEncodingStrategy = endpoint.dateEncodingStrategy
        return try jsonEncoder.encode(self)
    }
}

fileprivate extension Dictionary where Key == String, Value == (any Sendable) {
    func encode(using endpoint: Endpoint) throws -> Data {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = endpoint.keyEncodingStrategy
        jsonEncoder.dateEncodingStrategy = endpoint.dateEncodingStrategy
        
        let mappedDictionary = self.mapValues(AnyEncodable.init)
        return try jsonEncoder.encode(mappedDictionary)
    }
}
