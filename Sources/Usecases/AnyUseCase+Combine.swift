// AnyUseCase+Combine.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine
import Foundation

public extension Publisher {
    /// Convert a combine publsher into an ``AnyUseCase``
    /// - Parameter receiveOn: Optional ``DispatchQueue`` or ``DispatchQueue.main``
    /// - Returns: An ``AnyUseCase`` instance.
    func eraseToAnyUseCase(receiveOn: DispatchQueue? = nil) -> AnyUseCase<Void, Output> {
        let usecase = AnyUseCase<Void, Output>()
        let execution: AnyUseCase<Void, Output>.Execution = { _ in
            var cancellable: AnyCancellable?
            cancellable = self
                .receive(on: receiveOn ?? DispatchQueue.main)
                .sink(receiveCompletion: { [usecase, cancellable] complete in
                    switch complete {
                    case .finished:
                        break
                    case let .failure(error):
                        usecase.onFailure?(error)
                    }
                    cancellable?.cancel()
                }, receiveValue: { [usecase, cancellable] output in
                    usecase.onComplete?(output)
                    cancellable?.cancel()
                })
        }
        usecase.execute = execution
        return usecase
    }
}
