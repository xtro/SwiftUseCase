/// A bridge from Combine publishers to async-throwing use cases.
///
/// ``CombineUseCase`` adapts a `Publisher` so it can be invoked like an
/// ``AsyncThrowingUseCase``, awaiting either the first value or an error.

import Combine

/// A type that wraps a Combine publisher as an ``AsyncThrowingUseCase``.
///
/// Provide a publisher as the `Parameter` and await the first output or a
/// failure. The subscription is cancelled after delivering a value or a
/// terminal completion.
///
/// - Type Parameters:
///   - P: The publisher type to adapt. `Result == P.Output`, `Failure == P.Failure`.
///
/// - Important: This use case completes after the first value. If you need to
///   accumulate multiple values, transform the publisher (e.g., `first()`,
///   `collect()`, or `reduce`) before wrapping it.
/// - Note: Cancellation of the async task cancels the underlying subscription.
///
/// ## Example
/// ```swift
/// let uc = CombineUseCase<AnyPublisher<User, Error>>()
/// let user = try await uc( api.getUser(id: id).eraseToAnyPublisher() )
/// ```
public struct CombineUseCase<P: Publisher>: AsyncThrowingUseCase {
    public typealias Parameter = P
    public typealias Result = P.Output
    public typealias Failure = P.Failure

    /// Executes the publisher and awaits its first value or failure.
    ///
    /// The implementation installs a cancellation handler that cancels the
    /// Combine subscription if the surrounding `Task` is cancelled.
    public var execute: AsyncThrowingExecutable<Parameter, Result> = { publisher in
        let task = Cancellable()
        return try await withTaskCancellationHandler {
            return try await withUnsafeThrowingContinuation { [task] continuation in
                task.value = publisher
                    .sink(receiveCompletion: { [task] in
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
        } onCancel: { [task] in
            task.value?.cancel()
        }
    }
    /// A small box to hold the active subscription for coordinated cancellation.
    private class Cancellable {
        var value: AnyCancellable?
    }
}
