// AsyncUseCase+Publisher.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension AsyncUseCase {
    func publisher(parameters: Parameter = () as! Parameter, priority: TaskPriority = .background) -> AnyPublisher<Result, Never> {
        Future { promise in
            Task.detached(priority: priority) {
                let result = await execute(parameters)
                await MainActor.run {
                    promise(.success(result))
                }
            }
        }.eraseToAnyPublisher()
    }
}
