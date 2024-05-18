import Foundation

extension String {
    var boolValue: Bool {
        (self as NSString).boolValue
    }
}

extension JSONDecoder.DateDecodingStrategy {

    static var tmdbDateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        .custom { decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-mm-DD"
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed decoding date \(dateString)")
        }
    }
}
