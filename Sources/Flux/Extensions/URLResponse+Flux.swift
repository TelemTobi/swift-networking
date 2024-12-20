import Foundation

public extension URLResponse {
    
    var status: HttpStatus {
        let statusCode = (self as? HTTPURLResponse)?.statusCode ?? .zero
        return HttpStatus(rawValue: statusCode) ?? .undefined
    }
}
