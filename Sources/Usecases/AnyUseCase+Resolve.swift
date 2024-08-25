// AnyUseCase+Resolve.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

public extension UseCase {
    /// Erase type to ``AnyUseCase``
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

public extension AsyncUseCase {
    /// Erase type to ``AnyUseCase``
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

public extension ThrowingUseCase {
    /// Erase type to ``AnyUseCase``
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

public extension AsyncThrowingUseCase {
    /// Erase type to ``AnyUseCase``
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``UseCase``.
    /// - Parameters:
    ///   - usecase: A ``UseCase`` implementation.
    convenience init<U: UseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        execute = { [weak self] parameters in
            guard let self else { return }
            onComplete?(usecase(parameters))
        }
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``AsyncUseCase``.
    /// - Parameters:
    ///   - usecase: A ``AsyncUseCase`` implementation.
    convenience init<U: AsyncUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        execute = { parameters in
            task = Task.detached { [usecase] in
                let result = await usecase(parameters)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    onComplete?(result)
                }
            }
        }
        cancellation = {
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``ThrowingUseCase``.
    /// - Parameters:
    ///   - usecase: A ``ThrowingUseCase`` implementation.
    convenience init<U: ThrowingUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        execute = { [weak self] parameters in
            guard let self else { return }
            do {
                let result = try usecase(parameters)
                onComplete?(result)
            } catch {
                onFailure?(error)
            }
        }
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``AsyncThrowingUseCase``.
    /// - Parameters:
    ///   - usecase: A ``AsyncThrowingUseCase`` implementation.
    convenience init<U: AsyncThrowingUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        execute = { parameters in
            task = Task.detached { [usecase] in
                do {
                    let result = try await usecase(parameters)
                    try Task.checkCancellation()
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        onComplete?(result)
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        onFailure?(error)
                    }
                }
            }
        }
        cancellation = { [task] in
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}
