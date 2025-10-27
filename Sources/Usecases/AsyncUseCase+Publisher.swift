import Combine

/// Combine publisher adapter for ``AsyncUseCase``.
///
/// This helper executes the async use case in a detached task and bridges the
/// result into a Combine `Publisher`, delivering completion on the main actor.
public extension AsyncUseCase {
    /// Creates a publisher that executes the use case and never fails.
    ///
    /// The publisher starts work when subscribed, running the use case in a
    /// detached task at the given priority. Results are delivered to the
    /// subscriber on the main actor.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case. Defaults to `()` for `Void`.
    ///   - priority: The priority of the detached task. Defaults to `.background`.
    /// - Returns: An `AnyPublisher<Result, Never>` that emits a single value.
    ///
    /// - Note: Work is performed in a detached task; cancellation propagates
    ///   when the subscriber cancels the subscription.
    ///
    /// ## Example
    /// ```swift
    /// let pub: AnyPublisher<Profile, Never> = loadProfileUseCase
    ///     .publisher(parameters: userID)
    ///
    /// let cancellable = pub.sink(receiveValue: { profile in
    ///     print(profile)
    /// })
    /// ```
    func publisher(parameters: Parameter = () as! Parameter, priority: TaskPriority = .background) -> AnyPublisher<Result, Never> {
        Future { promise in
            Task.detached(priority: priority) {
                let result = await execute(parameters)
                await MainActor.run { [promise] in
                    promise(.success(result))
                }
            }
        }.eraseToAnyPublisher()
    }
}
