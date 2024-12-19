//
//  Error+Extension.swift
//  Flux
//
//  Created by Telem Tobi on 19/12/2024.
//

extension Error {
    
    var asFluxError: Flux.Error {
        (self as? Flux.Error) ?? .unknownError(self.localizedDescription)
    }
}
