import Foundation
@testable import Networking

struct TestError: DecodableError, Equatable {
    var type: Networking.Error
    
    init(_ type: Networking.Error) {
        self.type = type
    }
}
