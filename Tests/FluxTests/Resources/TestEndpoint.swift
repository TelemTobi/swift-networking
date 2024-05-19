import Foundation
@testable import Flux

struct TestEndpoint: Endpoint {
    let baseURL: URL
    let path: String
    let method: HTTPMethod
    var task: HTTPTask
    let headers: [String: String]?
    let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
    let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy
    var sampleData: Data?
}

struct TestBody: Encodable {
    let someDate: Date
    let someCondition: Bool
}
