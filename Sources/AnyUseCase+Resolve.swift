// AnyUseCase+Resolve.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

public extension SyncUseCase {
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

public extension SyncThrowingUseCase {
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
    /// Construct an ``AnyUseCase`` based on a  ``SyncUseCase``.
    /// - Parameters:
    ///   - usecase: A ``SyncUseCase`` implementation.
    ///   - parameters: Parameters of a ``SyncUseCase``.
    convenience init<U: SyncUseCase>(usecase: U, parameters: Parameter? = nil) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        resolve(usecase: usecase, parameters: parameters)
    }

    private func resolve<U: SyncUseCase>(usecase: U, parameters: Parameter? = nil) where U.Parameter == Parameter, U.Result == Result {
        let execution: Execution = { parameters in
            let result = usecase(parameters)
            self.onComplete?(result)
        }
        execute = execution
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``AsyncUseCase``.
    /// - Parameters:
    ///   - usecase: A ``AsyncUseCase`` implementation.
    ///   - parameters: Parameters of a ``AsyncUseCase``.
    convenience init<U: AsyncUseCase>(usecase: U, parameters: Parameter? = nil) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        let execution: Execution = { parameters in
            task = Task.detached { [usecase] in
                let result = await usecase(parameters)
                await MainActor.run { [weak self] in
                    self?.onComplete?(result)
                }
            }
        }
        execute = execution
        cancellation = {
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``SyncThrowingUseCase``.
    /// - Parameters:
    ///   - usecase: A ``SyncThrowingUseCase`` implementation.
    ///   - parameters: Parameters of a ``SyncThrowingUseCase``.
    convenience init<U: SyncThrowingUseCase>(usecase: U, parameters: Parameter? = nil) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        let execution: Execution = { parameters in
            do {
                let result = try usecase(parameters)
                self.onComplete?(result)
            } catch {
                self.onFailure?(error)
            }
        }
        execute = execution
    }
}

public extension AnyUseCase {
    /// Construct an ``AnyUseCase`` based on a  ``AsyncThrowingUseCase``.
    /// - Parameters:
    ///   - usecase: A ``AsyncThrowingUseCase`` implementation.
    ///   - parameters: Parameters of a ``AsyncThrowingUseCase``.
    convenience init<U: AsyncThrowingUseCase>(usecase: U, parameters: Parameter? = nil) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        let execution: Execution = { parameters in
            task = Task.detached { [usecase] in
                do {
                    let result = try await usecase(parameters)
                    try Task.checkCancellation()
                    await MainActor.run { [weak self] in
                        self?.onComplete?(result)
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        self?.onFailure?(error)
                    }
                }
            }
        }
        execute = execution
        cancellation = { [task] in
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}
