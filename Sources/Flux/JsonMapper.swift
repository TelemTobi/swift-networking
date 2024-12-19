//
//  JsonMapper.swift
//  Flux
//
//  Created by Telem Tobi on 19/12/2024.
//

import Foundation

/// A protocol that defines a mechanism for processing and transforming JSON response data from an API.
///
/// The `JsonMapper` protocol is designed for components responsible for handling incoming JSON responses.
/// Implementing types can transform the data, validate it, or make modifications before passing it forward.
///
/// ### Usage
/// Implement this protocol to define custom logic for resolving or modifying incoming data.
/// If the transformation fails, throw `Networking.Error.mappingError` to indicate a mapping failure.
public protocol JsonMapper {

    /// Transforms or processes the incoming JSON data.
    ///
    /// - Parameter data: The raw JSON data received from the API.
    /// - Returns: The processed data, ready for further use.
    /// - Throws: `Networking.Error.mappingError` if the transformation or validation fails.
    static func map(_ data: Data) throws(Flux.Error) -> Data
}

public extension JsonMapper {
    static func map(_ data: Data) throws(Flux.Error) -> Data { data }
}
