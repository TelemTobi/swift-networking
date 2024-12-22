extension Error {
    
    var asFluxError: Flux.Error {
        if let fluxError = self as? Flux.Error {
            return fluxError
        }
        
        if self is DecodingError {
            return .decodingError(localizedDescription)
        }
        
        return .unknownError(localizedDescription)
    }
}
