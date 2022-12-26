// AsyncThrowingUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

/// Asyncronized throwing use case implementation.
public protocol AsyncThrowingUseCase: UseCaseable {
    associatedtype Failure = Error

    var execute: AsyncThrowingExecutable<Parameter, Result> { get }
}

public extension AsyncThrowingUseCase {
    func callAsFunction(_ parameters: Parameter) async throws -> Result {
        try await execute(parameters)
    }

    func callAsFunction() async throws -> Result where Parameter == Void {
        try await execute(())
    }
}
