import Combine

/// Combine publisher adapters for ``ThrowingUseCase``.
///
/// These helpers execute the throwing use case and bridge the result into a
/// Combine `Publisher`.
///
public extension ThrowingUseCase {
    /// Creates a publisher that executes the use case and fails with the specified error type.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case. Defaults to `()` for `Void`.
    ///   - failureType: The error type used by the returned publisher.
    ///   - priority: Unused. Present for API symmetry with async variants.
    /// - Returns: An `AnyPublisher<Result, F>` that emits a single value or failure.
    ///
    /// - Important: The error is force-cast to `F`. Ensure your provided
    ///   `failureType` can represent the underlying error.
    ///
    /// ## Example
    /// ```swift
    /// enum ValidationError: Error { case empty }
    /// let pub: AnyPublisher<Void, ValidationError> = validateUseCase
    ///     .publisher(parameters: "", failureType: ValidationError.self)
    /// ```
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
    /// Creates a publisher that executes the use case and fails with `Error`.
    ///
    /// This variant uses `Error` as the failure type to avoid force-casting.
    ///
    /// - Parameters:
    ///   - parameters: Input passed to the use case.
    ///   - priority: Unused. Present for API symmetry with async variants.
    /// - Returns: An `AnyPublisher<Result, Error>` that emits a single value or failure.
    ///
    /// ## Example
    /// ```swift
    /// let pub: AnyPublisher<Int, Error> = throwingUseCase
    ///     .publisher(parameters: 3)
    /// ```
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
