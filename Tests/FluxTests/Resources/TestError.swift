import Foundation
@testable import Flux

struct TestError: DecodableError, Equatable {
    
    var debugDescription: String
    
    init(_ type: Flux.Error) {
        self.debugDescription = type.debugDescription
    }
}
