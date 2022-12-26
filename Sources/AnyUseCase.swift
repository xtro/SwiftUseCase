// AnyUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

/// A type-erasing use case object that executes the given closures
///
/// - `Cancellation` executes on cancellation.
/// - `Completion` executes after completion.
/// - `Failure` executes when `Execution` fails.
public protocol AnyUseCaseType: UseCaseable {
    typealias Cancellation = () -> Bool
    typealias Completion = (Result) -> Void
    typealias Failure = (Error) -> Void

    /// Cancellation closure, returns true if cancellation did finish successfuly.
    var cancellation: Cancellation? { get set }
    /// onFailure closure
    var onFailure: Failure? { get set }
    /// onComplete closure
    var onComplete: Completion? { get set }
    /// UseCase parameters
    var parameters: Parameter? { get }
}

/// Implementation of ``AnyUseCaseType``.
///
/// ```swift
/// ```
public class AnyUseCase<Parameter: Sendable, Result: Sendable>: AnyUseCaseType {
    public typealias Execution = (Parameter) -> Void

    public var execute: (Parameter) -> Void
    public var cancellation: Cancellation?
    public var onFailure: Failure?
    public var onComplete: Completion?
    public let parameters: Parameter?

    public func callAsFunction(_ parameters: Parameter? = nil) {
        execute(parameters ?? self.parameters ?? (() as! Parameter))
    }

    /// Construct an AnyUseCase object.
    /// - Parameters:
    ///   - execution: ``Execution`` closure.
    ///   - cancellation: ``AnyUseCaseType/Cancellation-swift.typealias`` closure.
    public init(_ execution: Execution? = nil, _: Cancellation? = nil) {
        execute = execution ?? { _ in }
        cancellation = nil
        parameters = nil
    }

    enum Error: Swift.Error {
        case unsupportedCancellation
    }

    /// Cancel executing use case
    /// - Returns: Returns cancellation result or throws an ``AnyUseCaseType/Failure`` if cancellation closure not defined.
    public func cancel() throws -> Bool {
        if let cancelled = cancellation?() {
            return cancelled
        }
        throw Error.unsupportedCancellation
    }
}
