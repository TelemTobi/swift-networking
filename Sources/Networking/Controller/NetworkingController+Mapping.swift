import Foundation

extension NetworkingController {
    /// Performs a network request using the provided `Endpoint`.
    ///
    /// This method fetches data from the specified endpoint, processes it using a `JsonMapper` (if implemented),
    /// and then decodes the transformed data into the specified model type.
    ///
    /// ### JSON Mapping
    /// If the response data requires additional processing (e.g., validation or transformation),
    /// the model type must conform to both `Decodable` and `JsonMapper`.
    /// The static `map(_:)` method of the `JsonMapper` protocol is called before decoding.
    ///
    /// - Parameter endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    /// - Throws: An error of type `F` if the request fails due to issues like authentication, connection, or decoding errors.
    /// - Returns: The decoded response model of type `T`.
    public func request<T: Decodable & JsonMapper>(_ endpoint: E) async throws(F) -> T {
        #if DEBUG
        guard environment == .live, !endpoint.shouldUseSampleData else {
            return try await makeMockRequest(endpoint)
        }
        #endif
        
        switch authenticator?.state ?? .reachable {
        case .notReachable:
            throw(.connectionError)
        case .notLoggedIn:
            throw(.authenticationError)
        case .reachable:
            break
        }
        
        do {
            if try await authenticator?.authenticate() == false {
                throw(F.authenticationError)
            }
        } catch {
            throw(.connectionError)
        }
        
        return try await makeRequest(endpoint)
    }
    
    /// Performs a network request using the provided `Endpoint`.
    ///
    /// This method fetches data from the specified endpoint, processes it using a `JsonMapper` (if implemented),
    /// and then decodes the transformed data into the specified model type. The result is returned as an asynchronous
    /// `Result` containing the decoded model or an error.
    ///
    /// ### JSON Mapping
    /// If the response data requires additional processing, the `JsonMapper.map(_:)` method is called
    /// before decoding into the target type.
    ///
    /// - Parameter endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    /// - Returns: An asynchronous `Result<T, F>`. On success, it contains the decoded model of type `T`.
    ///   On failure, it contains an error of type `F` describing the issue.
    public func request<T: Decodable & JsonMapper>(_ endpoint: E) async -> Result<T, F> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    /// Performs a network request using the provided `Endpoint` and calls a completion handler with the result.
    ///
    /// This method fetches data from the specified endpoint, processes it using a `JsonMapper` (if implemented),
    /// and then decodes the transformed data into the specified model type. The completion handler is invoked
    /// with the result.
    ///
    /// ### JSON Mapping
    /// If the response data requires additional processing, the `JsonMapper.map(_:)` method is called
    /// before decoding into the target type.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    ///   - completion: A closure that is called asynchronously with the result of the network request.
    ///     The closure takes a single argument of type `Result<T, F>`.
    ///     On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F`.
    public func request<T: Decodable & JsonMapper>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task { @MainActor in
            do {
                let result: T = try await request(endpoint)
                completion(.success(result))
            } catch {
                let error = error as? F ?? .unknownError(error.description)
                completion(.failure(error))
            }
        }
    }
    
    private func makeRequest<T: Decodable & JsonMapper>(_ endpoint: Endpoint) async throws(F) -> T {
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
            logError(endpoint, error.asFluxError)
            #endif
            throw(error as? F ?? .unknownError(error.description))
        }
    }
    
    #if DEBUG
    private func makeMockRequest<T: Decodable & JsonMapper>(_ endpoint: Endpoint) async throws(F) -> T {
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
            logError(endpoint, error.asFluxError)
            throw(F.init(error.asFluxError))
        }
    }
    #endif
}
