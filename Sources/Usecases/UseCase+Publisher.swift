import Combine

/// Combine publisher adapter for ``UseCase``.
///
/// This helper wraps a synchronous use case result in a `Just` publisher and
/// erases it to `AnyPublisher`.
public extension UseCase {
    /// Creates a publisher that emits the result of the use case and never fails.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case. Defaults to `()` for `Void`.
    ///   - priority: Unused. Present for API symmetry with async variants.
    /// - Returns: An `AnyPublisher<Result, Never>` that emits a single value.
    ///
    /// ## Example
    /// ```swift
    /// let pub: AnyPublisher<Int, Never> = addUseCase.publisher(parameters: 3)
    /// ```
    func publisher(parameters: Parameter = () as! Parameter, priority _: TaskPriority = .background) -> AnyPublisher<Result, Never> {
        Just(execute(parameters))
            .eraseToAnyPublisher()
    }
}
