// SyncUseCase+Callbacks.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension SyncUseCase {
    func execute(_ parameters: Parameter? = nil, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        let usecase = eraseToAnyUseCase
        usecase.onComplete = { result in
            onComplete(result)
        }
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}
public extension SyncUseCase {
    func callAsFunction(_ parameters: Parameter? = nil, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        execute(parameters, onComplete: onComplete)
    }
}
