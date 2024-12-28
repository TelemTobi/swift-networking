import Foundation

public extension Data {
    
    func decode<T: Decodable>(into type: T.Type, using dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, _ keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> T {
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        
        do {
            return try jsonDecoder.decode(type, from: self)
        } catch {
            throw Flux.Error.decodingError("\(error)")
        }
    }
    
    func decodeJson() throws -> [String: AnyHashable]? {
        try JSONSerialization.jsonObject(with: self, options: []) as? [String: AnyHashable]
    }
    
    var prettyPrintedJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}
