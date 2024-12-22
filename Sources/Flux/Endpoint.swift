import Foundation

import Foundation

/// Defines the specifications required to construct a `URLRequest`.
public protocol Endpoint {

    /// The base URL for the API endpoint.
    ///
    /// This URL should be the root of the API you're interacting with.
    var baseURL: URL { get }

    /// The path component to be appended to the `baseURL` to form the complete URL.
    ///
    /// This string represents the specific resource you're targeting within the API.
    var path: String { get }

    /// The HTTP method for the network request.
    ///
    /// This value specifies the type of operation you want to perform (e.g., GET, POST, PUT).
    var method: HttpMethod { get }

    /// The configuration for the HTTP request body and query parameters.
    ///
    /// This specifies how the request data should be encoded and included in the request.
    var task: HttpTask { get }

    /// The headers to be included in the network request.
    ///
    /// This dictionary allows you to specify custom headers for authentication, content type, etc.
    /// (Default: `nil`)
    var headers: [String: String]? { get }

    /// The strategy used by `JSONDecoder` for decoding JSON response keys.
    ///
    /// This property allows you to customize how JSON keys are mapped to your model properties.
    ///
    /// (Default: `.useDefaultKeys`)
    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }

    /// The strategy used by `JSONDecoder` for decoding dates from the JSON response.
    ///
    /// This property allows you to specify how date strings are parsed into your model objects.
    ///
    /// (Default: `.deferredToDate`)
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }
    
    /// **The strategy used by `JSONEncoder` for encoding model properties as JSON keys.**
    ///
    /// This property allows you to customize how your model properties are mapped to JSON object keys during request body encoding.
    ///
    /// (Default: `.useDefaultKeys`)
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
    
    /// **The strategy used by `JSONEncoder` for encoding dates into the JSON request body.**
    ///
    /// This property allows you to specify how your `Date` properties are formatted and included in the request body.
    ///
    /// (Default: `.deferredToDate`)
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }

    #if DEBUG
    /// A Boolean value that indicates whether the endpoint should use sample data instead of making a real network request.
    ///
    /// When set to `true`, the `sampleData` property will be used to simulate the network response, allowing you to test the endpoint without relying on an actual network connection.
    var shouldUseSampleData: Bool { get }
    
    /// Optional sample data used for testing or mocking purposes.
    ///
    /// This property allows you to provide pre-defined data to simulate a network response in tests.
    var sampleData: Data? { get }
    
    /// A Boolean value indicating whether request and response details should be printed to the console.
    ///
    /// When set to `true`, The following information will be logged upon receiving a response:
    ///  * Request URL
    ///  * HTTP Method
    ///  * Request Headers
    ///  * Request Body (if applicable)
    ///  * Status Code
    ///  * Response Headers
    ///  * Response Body (formatted JSON)
    ///
    /// You can use this property to control logging verbosity for specific endpoints.
    ///
    /// (Default: `true`)
    var shouldPrintLogs: Bool { get }
    #endif
}

// Default implementations for optional properties
public extension Endpoint {

    var headers: [String: String]? { nil }

    var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { .useDefaultKeys }

    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .deferredToDate }
    
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { .useDefaultKeys }
    
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .deferredToDate }

    #if DEBUG
    var shouldUseSampleData: Bool { false }
    
    var sampleData: Data? { nil }
    
    var shouldPrintLogs: Bool { Flux.DebugConfiguration.shouldPrintLogs }
    #endif
}
