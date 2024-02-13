// ThrowingUseCase+Publisher.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension ThrowingUseCase {
    func publisher<F: Error>(parameters: Parameter = () as! Parameter, failureType _: F.Type, priority _: TaskPriority = .background) -> AnyPublisher<Result, F> where Self.Failure == F {
        Future { promise in
            do {
                promise(.success(try execute(parameters)))
            } catch {
                promise(.failure(error as! F))
            }
        }.eraseToAnyPublisher()
    }
}
public extension ThrowingUseCase {
    func publisher(parameters: Parameter, priority _: TaskPriority = .background) -> AnyPublisher<Result, Error> {
        Future { promise in
            do {
                promise(.success(try execute(parameters)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
