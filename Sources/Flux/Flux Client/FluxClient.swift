import Foundation

/// A network client for making requests with features like authentication, environment handling, and error handling.
public struct FluxClient<E: Endpoint, F: DecodableError> {
    
    /// An optional authentication provider to be used with the requests.
    public var authenticator: Authenticator? = nil
    
    /// The current environment, either `.live`, `.test`, or `.preview`.
    public var environment: Flux.Environment = .live
    
    
    private let loggingQueue = DispatchQueue(label: #function)
    
    /// A network client for making requests with features like authentication, environment handling, and error handling.
    ///
    /// - Parameters:
    ///   - authenticator: An optional authentication provider to be used with the requests.
    ///   - environment: The current environment, either `.live`, `.test`, or `.preview`.
    ///
    /// * **Authentication:**
    ///   * The client checks the authentication state through the `authenticator` (if provided).
    ///     If authentication is required and fails, a `.failure(.authenticationError)` result is returned.
    ///
    /// * **Environment:**
    ///   * **.live:** Makes a real network call to the production API endpoint.
    ///   * **.test:** Does not make a network call. This environment is intended for unit testing your code that interacts with the API.
    ///   * **.preview:** Does not make a network call. This environment is used with SwiftUI previews to provide sample data without actual network requests.
    public init(authenticator: Authenticator? = nil, environment: Flux.Environment = .live) {
        self.authenticator = authenticator
        self.environment = environment
    }
    
    /// Performs a network request using the provided `Endpoint`.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    /// - Returns: An asynchronous result of type `Result<T, F>`. 
    ///     On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F` describing the issue.
    public func request<T: Decodable>(_ endpoint: E) async -> Result<T, F> {
        
        guard environment == .live else {
            return await makeStubRequest(endpoint)
        }
        
        switch authenticator?.state ?? .reachable {
        case .notReachable:
            return .failure(.connectionError)
        case .notLoggedIn:
            return .failure(.authenticationError)
        case .reachable:
            break
        }
        
        do {
            if try await authenticator?.authenticate() ?? true {
                return await makeRequest(endpoint)
            } else {
                return .failure(.authenticationError)
            }
        } catch {
            return .failure(.connectionError)
        }
    }
    
    /// Performs a network request using the provided `Endpoint` and a completion handler.
    ///
    /// - Parameters:
    ///   - endpoint: The `Endpoint` object defining the API endpoint and request parameters.
    ///   - completion: A closure that will be called asynchronously with the result of the network request. 
    ///   The closure takes a single argument of type `Result<T, F>`.
    ///   On success, the result contains the decoded model of type `T`. On failure, it contains an error of type `F` describing the issue.
    public func request<T: Decodable>(_ endpoint: E, completion: @escaping (Result<T, F>) -> Void) {
        Task {
            await completion(request(endpoint))
        }
    }
    
    private func makeRequest<T: Decodable>(_ endpoint: Endpoint) async -> Result<T, F> {
        var urlRequest = URLRequest(endpoint)
        authenticator?.mapRequest(&urlRequest)
     
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if endpoint.shouldPrintLogs {
               loggingQueue.async { [urlRequest] in
                    logRequest(endpoint, urlRequest, response, data)
                }
            }
            
            guard response.status.group == .success else {
                return await handleError(endpoint, data)
            }
            
            do {
                let model: T = try data.parse(
                    type: T.self,
                    using: endpoint.dateDecodingStrategy,
                    endpoint.keyDecodingStrategy
                )
                return .success(model)
                
            } catch {
                return .failure(.decodingError)
            }
            
        } catch {
            return .failure(.unknownError)
        }
    }
    
    private func makeStubRequest<T: Decodable>(_ endpoint: Endpoint) async -> Result<T, F> {
        do {
            if environment == .preview {
                try await Task.sleep(interval: Flux.Stub.delayInterval)
            }
            
            let model: T = try (endpoint.sampleData ?? Data()).parse(
                type: T.self,
                using: endpoint.dateDecodingStrategy,
                endpoint.keyDecodingStrategy
            )
            return .success(model)
            
        } catch {
            return .failure(.decodingError)
        }
    }
    
    private func handleError<T: Decodable>(_ endpoint: Endpoint, _ data: Data) async -> Result<T, F> {
        if let error = try? data.parse(
            type: F.self,
            using: endpoint.dateDecodingStrategy,
            endpoint.keyDecodingStrategy
        ) {
            return .failure(error)
        } else {
            return .failure(.unknownError)
        }
    }
}
