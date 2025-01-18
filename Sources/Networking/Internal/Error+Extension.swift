extension Error {
    
    var description: String {
        "\(self)"
    }
    
    var asNetworkingError: Networking.Error {
        if let fluxError = self as? Networking.Error {
            return fluxError
        }
        
        if self is DecodingError {
            return .decodingError(description)
        }
        
        return .unknownError(localizedDescription)
    }
}
