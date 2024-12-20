extension Error {
    
    var asFluxError: Flux.Error {
        (self as? Flux.Error) ?? .unknownError(self.localizedDescription)
    }
}
