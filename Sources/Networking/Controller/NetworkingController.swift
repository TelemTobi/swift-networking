import Foundation

/// A networking controller for making requests with features like authentication, environment handling, json mapping and error handling.
open class NetworkingController<E: Endpoint, F: DecodableError> {
    
    /// The current environment, either `.live`, `.test`, or `.preview`.
    public let environment: Networking.Environment
    
    /// An optional authentication provider to be used with the requests.
    public let authenticator: Authenticator?
    
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
    public init(environment: Networking.Environment = .live, authenticator: Authenticator? = nil, configuration: URLSessionConfiguration = .default, delegate: URLSessionDelegate? = nil) {
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
    open func request<T: Decodable & Sendable>(_ endpoint: E) async throws(F) -> T {
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
    open func request<T: Decodable & Sendable>(_ endpoint: E) async -> Result<T, F> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    #if swift(<6.0)
    /// Performs a network request using the provided `Endpoint` and calls a completion handler with the result.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    ///   - completion: A closure that will be called asynchronously with the result of the network request.
    ///   The closure takes a single argument of type `Result<T, F>`.
    ///   On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F` describing the issue.
    open func request<T: Decodable & Sendable>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task {
            do {
                let result: T = try await request(endpoint)
                completion(.success(result))
            } catch {
                let error = error as? F ?? .unknownError(error.description)
                completion(.failure(error))
            }
        }
    }
    #endif
    
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
    open func request<T: Decodable & Sendable & JsonMapper>(_ endpoint: E) async throws(F) -> T {
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
    open func request<T: Decodable & Sendable & JsonMapper>(_ endpoint: E) async -> Result<T, F> {
        do {
            let result: T = try await request(endpoint)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    #if swift(<6.0)
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
    open func request<T: Decodable & Sendable & JsonMapper>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task {
            do {
                let result: T = try await request(endpoint)
                completion(.success(result))
            } catch {
                let error = error as? F ?? .unknownError(error.description)
                completion(.failure(error))
            }
        }
    }
    #endif
}
