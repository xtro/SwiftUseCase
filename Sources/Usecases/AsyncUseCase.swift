// AsyncUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

/// Asyncronized use case implementation.
public protocol AsyncUseCase: AsyncUsecaseable {
    var execute: AsyncExecutable<Parameter, Result> { get }
}

public extension AsyncUseCase {
    func callAsFunction(_ parameters: Parameter) async -> Result {
        await execute(parameters)
    }

    func callAsFunction() async -> Result where Parameter == Void {
        await execute(())
    }
}
