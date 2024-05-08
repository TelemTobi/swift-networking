import Foundation

public extension URLResponse {
    
    var status: HTTPStatus {
        let statusCode = (self as? HTTPURLResponse)?.statusCode ?? .zero
        return HTTPStatus(rawValue: statusCode) ?? .undefined
    }
}
