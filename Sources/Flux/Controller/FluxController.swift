import Foundation

/// A networking controller for making requests with features like authentication, environment handling, json mapping and error handling.
public class FluxController<E: Endpoint, F: DecodableError> {
    
    /// The current environment, either `.live`, `.test`, or `.preview`.
    public var environment: Flux.Environment = .live
    
    /// An optional authentication provider to be used with the requests.
    public var authenticator: Authenticator? = nil
    
    internal let urlSession: URLSession
    
    #if DEBUG
    internal let loggingQueue = DispatchQueue(label: #function)
    #endif
    
    /// A networking controller for making requests with features like authentication, environment handling, and error handling.
    ///
    /// - Parameters:
    ///   - environment: The current environment, either `.live`, `.test`, or `.preview`.
    ///   - authenticator: An optional authentication provider to be used with the requests.
    ///   - configuration: A configuration object that specifies certain behaviors, such as caching policies, timeouts, proxies, pipelining, TLS versions to support, cookie policies, and credential storage.
    ///   - delegate: A session delegate object that handles requests for authentication and other session-related events.
    ///
    /// * **Environment:**
    ///   * **.live:** Makes a real network call to the production API endpoint.
    ///   * **.test:** Does not make a network call. This environment is intended for unit testing your code that interacts with the API.
    ///   * **.preview:** Does not make a network call. This environment is used with SwiftUI previews to provide sample data without actual network requests.
    ///
    /// * **Authentication:**
    ///   * The controller checks the authentication state through the `authenticator` (if provided).
    ///     If authentication is required and fails, a `.failure(.authenticationError)` result is returned.
    public init(environment: Flux.Environment = .live, authenticator: Authenticator? = nil, configuration: URLSessionConfiguration = .default, delegate: URLSessionDelegate? = nil) {
        self.environment = environment
        self.authenticator = authenticator
        
        self.urlSession = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }
    
    /// Performs a network request using the provided `Endpoint`.
    ///
    /// - Parameter endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    /// - Throws: An error of type `F` if the request fails due to an issue like authentication, connection, or decoding errors.
    /// - Returns: The decoded response model of type `T`.
    public func request<T: Decodable>(_ endpoint: E) async throws(F) -> T {
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
    /// - Parameter endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    /// - Returns: An asynchronous result of type `Result<T, F>`.
    ///     On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F` describing the issue.
    public func request<T: Decodable>(_ endpoint: E) async -> Result<T, F> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    /// Performs a network request using the provided `Endpoint` and calls a completion handler with the result.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    ///   - completion: A closure that will be called asynchronously with the result of the network request.
    ///   The closure takes a single argument of type `Result<T, F>`.
    ///   On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F` describing the issue.
    public func request<T: Decodable>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task { @MainActor in
            do {
                let result: T = try await request(endpoint)
                completion(.success(result))
            } catch {
                let error = error as? F ?? .unknownError()
                completion(.failure(error))
            }
        }
    }
    
    private func makeRequest<T: Decodable>(_ endpoint: Endpoint) async throws(F) -> T {
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
            logError(endpoint, error.asFluxError)
            #endif
            throw(error as? F ?? .unknownError(error.localizedDescription))
        }
    }
    
    func decodedError(_ endpoint: Endpoint, _ data: Data) -> F {
        let error = try? data.decode(
            into: F.self,
            using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
        )
        return error ?? .unknownError()
    }
    
    #if DEBUG
    private func makeMockRequest<T: Decodable>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            authenticator?.mapRequest(&urlRequest)
            
            if environment != .test {
                try await Task.sleep(interval: Flux.DebugConfiguration.delayInterval)
            }
            
            let sampleData = endpoint.sampleData ?? Data()
            
            logRequest(endpoint, urlRequest, nil, sampleData)
            
            let model = try (sampleData).decode(
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

