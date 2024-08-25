// AnyUseCase+Callbacks.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension AnyUseCase {
    func execute(_ parameters: Parameter? = nil, onFailure: @escaping Failure, onComplete: @escaping Completion) -> AnyCancellable {
        let usecase = self
        usecase.onComplete = onComplete
        usecase.onFailure = onFailure
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}
