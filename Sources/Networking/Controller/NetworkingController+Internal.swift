import Foundation

extension NetworkingController {
    internal func makeRequest<T: Decodable & Sendable>(_ endpoint: Endpoint, attempt: Int = .zero, allowsAuthenticationRefresh: Bool = true) async throws(F) -> T {
        var status = HttpStatus.undefined
        var sentRequest: URLRequest?
        
        do {
            var urlRequest = try URLRequest(endpoint)
            
            interceptor?.intercept(&urlRequest)
            sentRequest = urlRequest
            
            var (data, response) = try await urlSession.data(for: urlRequest)
            status = response.status
            
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
            
            let error: F = error as? F ?? .unknownError(error.description)
            let canRefreshAuthentication = allowsAuthenticationRefresh && status == .unauthorized
            
            if canRefreshAuthentication, await reauthenticate(for: sentRequest, after: error) {
                return try await makeRequest(endpoint, attempt: attempt, allowsAuthenticationRefresh: false)
            }
            
            if attempt < endpoint.retryCount {
                let backoffDuration = 0.2 * pow(2, Double(attempt))
                try? await Task.sleep(interval: backoffDuration)
                return try await makeRequest(endpoint, attempt: attempt + 1, allowsAuthenticationRefresh: allowsAuthenticationRefresh)
            }
            
            interceptor?.intercept(error)
            throw(error)
        }
    }
    
    private func reauthenticate(for request: URLRequest?, after error: F) async -> Bool {
        guard let interceptor, let request else { return false }
        guard await interceptor.refreshAuthentication(for: request, after: error) else { return false }
        
        return (try? await interceptor.authenticate()) == true
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
    
    internal func makeRequest<T: Decodable & Sendable & JsonMapper>(_ endpoint: Endpoint, attempt: Int = .zero, allowsAuthenticationRefresh: Bool = true) async throws(F) -> T {
        var status = HttpStatus.undefined
        var sentRequest: URLRequest?
        
        do {
            var urlRequest = try URLRequest(endpoint)
            
            interceptor?.intercept(&urlRequest)
            sentRequest = urlRequest
            
            var (data, response) = try await urlSession.data(for: urlRequest)
            status = response.status
            
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
            
            let error: F = error as? F ?? .unknownError(error.description)
            let canRefreshAuthentication = allowsAuthenticationRefresh && status == .unauthorized
            
            if canRefreshAuthentication, await reauthenticate(for: sentRequest, after: error) {
                return try await makeRequest(endpoint, attempt: attempt, allowsAuthenticationRefresh: false)
            }
            
            if attempt < endpoint.retryCount {
                let backoffDuration = 0.2 * pow(2, Double(attempt))
                try? await Task.sleep(interval: backoffDuration)
                return try await makeRequest(endpoint, attempt: attempt + 1, allowsAuthenticationRefresh: allowsAuthenticationRefresh)
            }
            
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
