import Foundation
@testable import Flux

struct TestEndpoint: Endpoint {
    var baseURL: URL
    var path: String
    var method: HttpMethod
    var task: HttpTask
    var headers: [String: String]?
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
    var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    var sampleData: Data?
}
