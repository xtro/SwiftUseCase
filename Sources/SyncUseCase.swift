// SyncUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

/// Syncronized use case implementation.
public protocol SyncUseCase: UseCaseable {
    var execute: Executable<Parameter, Result> { get }
}

public extension SyncUseCase {
    func callAsFunction(_ parameters: Parameter) -> Result {
        execute(parameters)
    }

    func callAsFunction() -> Result where Parameter == Void {
        execute(())
    }
}
