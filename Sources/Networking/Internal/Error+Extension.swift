extension Error {
    
    var description: String {
        "\(self)"
    }
    
    var asNetworkingError: Networking.Error {
        if let networkingError = self as? Networking.Error {
            return networkingError
        }
        
        if self is DecodingError {
            return .decodingError(description)
        }
        
        return .unknownError(localizedDescription)
    }
}
