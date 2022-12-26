// SyncThrowingUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

/// Syncronized use case implementation.
public protocol SyncThrowingUseCase: UseCaseable {
    associatedtype Failure = Error

    var execute: ThrowingExecutable<Parameter, Result> { get }
}

public extension SyncThrowingUseCase {
    func callAsFunction(_ parameters: Parameter) throws -> Result {
        try execute(parameters)
    }

    func callAsFunction() throws -> Result where Parameter == Void {
        try execute(())
    }
}
