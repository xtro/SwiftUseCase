// UseCase+Publisher.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Combine

public extension UseCase {
    func publisher(parameters: Parameter = () as! Parameter, priority _: TaskPriority = .background) -> AnyPublisher<Result, Never> {
        Just(execute(parameters))
            .eraseToAnyPublisher()
    }
}
