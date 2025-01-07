extension Error {
    
    var description: String {
        "\(self)"
    }
    
    var asFluxError: Flux.Error {
        if let fluxError = self as? Flux.Error {
            return fluxError
        }
        
        if self is DecodingError {
            return .decodingError(description)
        }
        
        return .unknownError(localizedDescription)
    }
}
