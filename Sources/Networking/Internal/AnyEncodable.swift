import Foundation

internal struct AnyEncodable: Encodable {
    private let value: Any
    
    internal init(_ value: Any) {
        self.value = value
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let decimal as Decimal:
            try container.encode(decimal)
        case let bool as Bool:
            try container.encode(bool)
        case let date as Date:
            try container.encode(date)
        case let array as [Any]:
            try container.encode(array.map(AnyEncodable.init))
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues(AnyEncodable.init))
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Unsupported type: \(type(of: value))"
                )
            )
        }
    }
}
