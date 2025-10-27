import Combine

/// Combine publisher adapters for ``AsyncThrowingUseCase``.
///
/// These helpers execute the async-throwing use case in a detached task and
/// bridge the result into a Combine `Publisher`, delivering completion on the
/// main actor.
public extension AsyncThrowingUseCase {
    /// Creates a publisher that executes the use case and fails with the specified error type.
    ///
    /// The publisher starts work when subscribed, running the use case in a
    /// detached task at the given priority. Results are delivered to the
    /// subscriber on the main actor.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case. Defaults to `()` for `Void`.
    ///   - failureType: The error type used by the returned publisher.
    ///   - priority: The priority of the detached task. Defaults to `.background`.
    /// - Returns: An `AnyPublisher<Result, F>` that emits a single value or failure.
    ///
    /// - Important: The error is force-cast to `F`. Ensure your provided
    ///   `failureType` can represent the underlying error.
    /// - Note: Work is performed in a detached task; cancellation propagates
    ///   when the subscriber cancels the subscription.
    ///
    /// ## Example
    /// ```swift
    /// enum NetworkFailure: Error { case offline, server }
    /// let pub: AnyPublisher<User, NetworkFailure> = myUseCase
    ///     .publisher(parameters: id, failureType: NetworkFailure.self)
    ///
    /// let cancellable = pub.sink(
    ///     receiveCompletion: { print($0) },
    ///     receiveValue: { user in print(user) }
    /// )
    /// ```
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
public extension AsyncThrowingUseCase {
    /// Creates a publisher that executes the use case and fails with `Error`.
    ///
    /// This variant uses `Error` as the failure type to avoid force-casting.
    /// Execution occurs in a detached task at the specified priority, and
    /// results are delivered on the main actor.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case.
    ///   - priority: The priority of the detached task. Defaults to `.background`.
    /// - Returns: An `AnyPublisher<Result, Error>` that emits a single value or failure.
    ///
    /// ## Example
    /// ```swift
    /// let pub: AnyPublisher<Data, Error> = downloadUseCase
    ///     .publisher(parameters: url)
    /// ```
    func publisher(parameters: Parameter, priority: TaskPriority = .background) -> AnyPublisher<Result, Error> {
        Future { promise in
            Task.detached(priority: priority) {
                do {
                    let result = try await execute(parameters)
                    await MainActor.run { [promise] in
                        promise(.success(result))
                    }
                } catch {
                    await MainActor.run { [promise] in
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}

