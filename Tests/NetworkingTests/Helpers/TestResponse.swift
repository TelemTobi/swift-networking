import Foundation

struct TestResponse: Decodable, Equatable {
    let id: Int?
    let name: String?
    let birthdate: Date?
}
