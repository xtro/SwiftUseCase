// ThrowingUseCase+Callbacks.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension ThrowingUseCase {
    func execute(_ parameters: Parameter? = nil, onFailure: @escaping (Failure) -> Void, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        let usecase = eraseToAnyUseCase
        usecase.onComplete = onComplete
        usecase.onFailure = {
            onFailure($0 as! Failure)
        }
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}

public extension ThrowingUseCase {
    func callAsFunction(_ parameters: Parameter? = nil, onFailure: @escaping (Failure) -> Void, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        execute(parameters, onFailure: onFailure, onComplete: onComplete)
    }
}
