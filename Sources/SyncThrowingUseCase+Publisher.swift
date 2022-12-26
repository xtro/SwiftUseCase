// SyncThrowingUseCase+Publisher.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension SyncThrowingUseCase {
    func publisher<F: Error>(parameters: Parameter = () as! Parameter, failureType _: F.Type, priority _: TaskPriority = .background) -> AnyPublisher<Result, F> where Self.Failure == F {
        Future { promise in
            do {
                let result = try execute(parameters)
                promise(.success(result))
            } catch {
                promise(.failure(error as! F))
            }
        }.eraseToAnyPublisher()
    }
}
