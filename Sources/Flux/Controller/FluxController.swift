import Foundation

public typealias DecodableJson = Decodable & JsonMapper

/// A networking controller for making requests with features like authentication, environment handling, and error handling.
public class FluxController<E: Endpoint, F: DecodableError> {
    
    /// The current environment, either `.live`, `.test`, or `.preview`.
    public var environment: Flux.Environment = .live
    
    /// An optional authentication provider to be used with the requests.
    public var authenticator: Authenticator? = nil
    
    private let urlSession: URLSession
    
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
    public func request<T: DecodableJson>(_ endpoint: E) async throws(F) -> T {
        
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
    public func request<T: DecodableJson>(_ endpoint: E) async -> Result<T, F> {
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
    public func request<T: DecodableJson>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task {
            do {
                let result: T = try await request(endpoint)
                completion(.success(result))
            } catch {
                let error = error as? F ?? .unknownError()
                completion(.failure(error))
            }
        }
    }
    
    private func makeRequest<T: DecodableJson>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            var urlRequest = try URLRequest(endpoint)
            
            authenticator?.mapRequest(&urlRequest)
            
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            #if DEBUG
            if endpoint.shouldPrintLogs {
               logRequest(endpoint, urlRequest, response, data)
            }
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
            throw(F.init(error.asFluxError))
        }
    }
    
    private func decodedError(_ endpoint: Endpoint, _ data: Data) -> F {
        let error = try? F
            .map(data)
            .decode(
                into: F.self,
                using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
            )
        return error ?? .unknownError()
    }
    
    #if DEBUG
    private func makeMockRequest<T: DecodableJson>(_ endpoint: Endpoint) async throws(F) -> T {
        do {
            if environment == .preview {
                try await Task.sleep(interval: Flux.Stub.delayInterval)
            }
            
            let model = try T
                .map(endpoint.sampleData ?? Data())
                .decode(
                    into: T.self,
                    using: endpoint.dateDecodingStrategy, endpoint.keyDecodingStrategy
                )
            return model
            
        } catch {
            throw(F.init(error.asFluxError))
        }
    }
    #endif
}

