import Foundation
import Flux

struct TmdbError: DecodableError {
    
    let statusCode: Int?
    let developerMessage: String?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case developerMessage = "status_message"
    }
    
    init(_ type: Flux.Error) {
        statusCode = -1
        developerMessage = type.localizedDescription
    }
}
