//  SwiftUseCase - AnyUseCase+Combine.swift
//
// Copyright (c) 2022-2025 Gabor Nagy
// Created by Gabor Nagy (gabor.nagy.0814@gmail.com)

import Combine
import Foundation

/// Extensions that bridge Combine publishers into ``AnyUseCase``.
///
/// These APIs let you adapt existing `Publisher` pipelines into the
/// use-case abstraction used by this package, enabling a consistent way
/// to trigger and observe asynchronous work from UI layers.
public extension Publisher {
    /// Erases the publisher into an ``AnyUseCase`` that emits values via callbacks.
    ///
    /// The returned use case subscribes to the upstream publisher when executed
    /// and forwards the first emitted value to ``AnyUseCase/onComplete``.
    /// If the publisher fails, the error is forwarded to ``AnyUseCase/onFailure``.
    /// In both cases, the subscription is cancelled immediately after receiving
    /// a value or a terminal completion.
    ///
    /// - Parameter receiveOn: An optional queue on which to receive publisher
    ///   events. If `nil`, the main queue is used.
    /// - Returns: An ``AnyUseCase`` with `Parameter == Void` and `Result == Output`.
    ///
    /// - Important: This adapter cancels the subscription after the first value.
    ///   If you need to handle multiple values, consider composing your publisher
    ///   to produce a single output (e.g., `first()` or `reduce(_)`) before
    ///   adapting it.
    /// - Note: Back-pressure is managed by Combine. The use case triggers a single
    ///   subscription each time it is executed.
    ///
    /// ## Example
    /// Convert a network request publisher into a use case:
    ///
    /// ```swift
    /// struct User: Decodable { /* ... */ }
    ///
    /// let requestPublisher: AnyPublisher<User, Error> = api
    ///     .getUser(id: id)
    ///     .eraseToAnyPublisher()
    ///
    /// let useCase = requestPublisher.eraseToAnyUseCase()
    ///
    /// useCase.onComplete = { user in
    ///     print("Loaded user: \(user)")
    /// }
    /// useCase.onFailure = { error in
    ///     print("Failed: \(error)")
    /// }
    ///
    /// // Execute from UI layer
    /// useCase.execute(())
    /// ```
    ///
    /// ## Threading
    /// Events are delivered on `receiveOn` if provided, otherwise on the main
    /// queue. This is convenient for updating UI-bound state from the callbacks.
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

