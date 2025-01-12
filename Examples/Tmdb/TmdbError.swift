import Foundation
import Networking

struct TmdbError: DecodableError {
    
    let statusCode: Int?
    let developerMessage: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case developerMessage = "status_message"
    }
    
    init(_ type: Networking.Error) {
        statusCode = -1
        developerMessage = type.localizedDescription
    }
}
