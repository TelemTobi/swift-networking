import Foundation
@testable import Networking

struct TestEndpoint: Endpoint {
    var baseURL: URL
    var path: String
    var method: HttpMethod
    var task: HttpTask
    var headers: [String: String]?
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    var retryCount: Int = .zero
    
    #if DEBUG
    var shouldUseSampleData: Bool = false
    var sampleData: Data?
    #endif
}
