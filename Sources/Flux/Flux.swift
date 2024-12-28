// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum Flux {
    
    /// An enum representing the different environments your API can be deployed to.
    public enum Environment {
        /// The production environment where live user traffic occurs.
        case live

        /// A staging environment used solely for unit testing your code that interacts with the API. Network calls are not made in this environment.
        case test

        /// A preview environment used with SwiftUI previews to provide sample data without actual network requests.
        case preview
    }

    
    /// An enum representing the various error types that can occur during network requests.
    public enum Error: Swift.Error {
        /// Indicates a connection issue (e.g., no internet).
        case connectionError

        /// Indicates an authentication failure.
        case authenticationError

        /// Indicates an error while decoding the response data.
        case decodingError(String)
        
        /// Indicates an error while encoding the request body..
        case encodingError(String)

        /// Indicates an unknown error.
        case unknownError(String?)
        
        public var debugDescription: String {
            String(describing: self)
        }
    }
    
    /// A namespace containing configuration for debug requests.
    public enum DebugConfiguration {
        /// Static property defining the delay (in seconds) for stub requests in the preview environment.
        static var delayInterval: TimeInterval = 1.0
        
        /// The global default value for the Endpoint's `shouldPrintLogs`.
        static var shouldPrintLogs: Bool = true
    }
}
