import Foundation
@testable import Networking

struct TestError: DecodableError, Equatable {
    
    var debugDescription: String
    
    init(_ type: Networking.Error) {
        self.debugDescription = type.debugDescription
    }
}
