// AsyncThrowingUseCase+Publisher.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension AsyncThrowingUseCase {
    func publisher<F: Error>(parameters: Parameter = () as! Parameter, failureType _: F.Type, priority: TaskPriority = .background) -> AnyPublisher<Result, F> {
        Future { promise in
            Task.detached(priority: priority) {
                do {
                    let result = try await execute(parameters)
                    await MainActor.run { [promise] in
                        promise(.success(result))
                    }
                } catch {
                    await MainActor.run { [promise] in
                        promise(.failure(error as! F))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
