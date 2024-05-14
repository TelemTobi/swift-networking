import Foundation

extension Data {
    
    func parse<T: Decodable>(type: T.Type, using dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, _ keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> T {
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        
        return try jsonDecoder.decode(type, from: self)
    }
    
    var prettyPrintedJSON: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}
