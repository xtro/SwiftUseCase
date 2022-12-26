// CombineUseCase.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public struct CombineUseCase<P: Publisher>: AsyncThrowingUseCase {
    public typealias Parameter = P
    public typealias Result = P.Output
    public typealias Failure = P.Failure
    public var execute: AsyncThrowingExecutable<Parameter, Result> = { publisher in
        let task = Cancellable()
        return try await withTaskCancellationHandler {
            return try await withUnsafeThrowingContinuation { continuation in
                task.value = publisher
                    .sink(receiveCompletion: {
                        switch $0 {
                        case .finished:
                            break
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                        task.value?.cancel()
                    }, receiveValue: {
                        continuation.resume(returning: $0)
                    })
            }
        } onCancel: {
            task.value?.cancel()
        }
    }
    private class Cancellable {
        var value: AnyCancellable?
    }
}
