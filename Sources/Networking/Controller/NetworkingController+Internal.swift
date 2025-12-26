import Foundation

extension NetworkingController {
    internal func makeRequest<T: Decodable & Sendable>(_ endpoint: Endpoint, attempt: Int = .zero) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            
            interceptor?.intercept(&urlRequest)
            
            var (data, response) = try await urlSession.data(for: urlRequest)
            
            logRequest(endpoint, urlRequest, response, data, attempt)
            
            interceptor?.intercept(&data)
            
            guard response.status.group == .success else {
                throw(decodedError(endpoint, data))
            }
            
            let model = try data.decode(
                into: T.self,
                using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
            )
            
            return model
            
        } catch {
            logError(endpoint, error.asNetworkingError, attempt)
            
            if attempt < endpoint.retryCount {
                let backoffDuration = 0.25 * Double(attempt + 1)
                try? await Task.sleep(interval: backoffDuration)
                return try await makeRequest(endpoint, attempt: attempt + 1)
            }
            
            let error: F = error as? F ?? .unknownError(error.description)
            interceptor?.intercept(error)
            throw(error)
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
            interceptor?.intercept(&urlRequest)
            
            if environment != .test {
                try await Task.sleep(interval: Networking.DebugConfiguration.delayInterval)
            }
            
            var sampleData = endpoint.sampleData ?? Data()
            
            interceptor?.intercept(&sampleData)
            
            logRequest(endpoint, urlRequest, nil, sampleData)
            
            let model = try (sampleData).decode(
                into: T.self,
                using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
            )
            
            return model
            
        } catch {
            logError(endpoint, error.asNetworkingError)
            
            let error = F.init(error.asNetworkingError)
            interceptor?.intercept(error)
            throw(error)
        }
    }
    #endif
    
    internal func makeRequest<T: Decodable & Sendable & JsonMapper>(_ endpoint: Endpoint, attempt: Int = .zero) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            
            interceptor?.intercept(&urlRequest)
            
            var (data, response) = try await urlSession.data(for: urlRequest)
            
            logRequest(endpoint, urlRequest, response, data, attempt)

            interceptor?.intercept(&data)
            
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
            logError(endpoint, error.asNetworkingError, attempt)
            
            if attempt < endpoint.retryCount {
                let backoffDuration = 0.25 * Double(attempt + 1)
                try? await Task.sleep(interval: backoffDuration)
                return try await makeRequest(endpoint, attempt: attempt + 1)
            }
            
            let error: F = error as? F ?? .unknownError(error.description)
            interceptor?.intercept(error)
            throw(error)
        }
    }
    
    #if DEBUG
    internal func makeMockRequest<T: Decodable & JsonMapper>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            interceptor?.intercept(&urlRequest)
            
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
            
            let error = F.init(error.asNetworkingError)
            interceptor?.intercept(error)
            throw(error)
        }
    }
    #endif
}
