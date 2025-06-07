import Foundation

extension NetworkingController {
    internal func makeRequest<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            
            authenticator?.mapRequest(&urlRequest)
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            #if DEBUG
            logRequest(endpoint, urlRequest, response, data)
            #endif
            
            guard response.status.group == .success else {
                throw(decodedError(endpoint, data))
            }
            
            let model = try data.decode(
                into: T.self,
                using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
            )
            
            return model
            
        } catch {
            #if DEBUG
            logError(endpoint, error.asNetworkingError)
            #endif
            throw(error as? F ?? .unknownError(error.description))
        }
    }
    
    internal func decodedError(_ endpoint: Endpoint, _ data: Data) -> F {
        let error = try? data.decode(
            into: F.self,
            using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
        )
        return error ?? .unknownError()
    }
    
    #if DEBUG
    internal func makeMockRequest<T: Decodable>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            authenticator?.mapRequest(&urlRequest)
            
            if environment != .test {
                try await Task.sleep(interval: Networking.DebugConfiguration.delayInterval)
            }
            
            let sampleData = endpoint.sampleData ?? Data()
            
            logRequest(endpoint, urlRequest, nil, sampleData)
            
            let model = try (sampleData).decode(
                into: T.self,
                using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
            )
            
            return model
            
        } catch {
            logError(endpoint, error.asNetworkingError)
            throw(F.init(error.asNetworkingError))
        }
    }
    #endif
    
    internal func makeRequest<T: Decodable & Sendable & JsonMapper>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            
            authenticator?.mapRequest(&urlRequest)
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            #if DEBUG
            logRequest(endpoint, urlRequest, response, data)
            #endif
            
            guard response.status.group == .success else {
                throw(decodedError(endpoint, data))
            }
            
            let model = try T
                .map(data)
                .decode(
                    into: T.self,
                    using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
                )
            return model
            
        } catch {
            #if DEBUG
            logError(endpoint, error.asNetworkingError)
            #endif
            throw(error as? F ?? .unknownError(error.description))
        }
    }
    
    #if DEBUG
    internal func makeMockRequest<T: Decodable & JsonMapper>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            authenticator?.mapRequest(&urlRequest)
            
            if environment != .test {
                try await Task.sleep(interval: Networking.DebugConfiguration.delayInterval)
            }
            
            let sampleData = endpoint.sampleData ?? Data()
            
            logRequest(endpoint, urlRequest, nil, sampleData)

            let model = try T
                .map(sampleData)
                .decode(
                    into: T.self,
                    using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
                )
            
            return model
            
        } catch {
            logError(endpoint, error.asNetworkingError)
            throw(F.init(error.asNetworkingError))
        }
    }
    #endif
}
