import Combine

/// Convenience callbacks-based APIs for ``ThrowingUseCase``.
///
/// These helpers adapt a throwing use case to a callbacks style using
/// ``AnyUseCase`` under the hood, returning an `AnyCancellable` for optional
/// cancellation.
public extension ThrowingUseCase {
    /// Executes the use case and reports results via callbacks.
    ///
    /// This method erases the use case to ``AnyUseCase`` and executes it,
    /// forwarding success to `onComplete` and errors to `onFailure`.
    ///
    /// - Parameters:
    ///   - parameters: Optional input for the use case. If omitted and the
    ///     `Parameter` type is `Void`, an empty tuple is supplied automatically.
    ///   - onFailure: A closure invoked with the error if execution fails.
    ///   - onComplete: A closure invoked with the result on success.
    /// - Returns: An `AnyCancellable` that can be used to request cancellation.
    ///
    /// - Important: If `Parameter` is not `Void`, you must provide `parameters`.
    /// - Note: Errors are force-cast to `Failure` to satisfy the generic API.
    ///   Ensure your `Failure` type can represent the underlying error.
    ///
    /// ## Example
    /// ```swift
    /// struct Validate: ThrowingUseCase {
    ///     typealias Parameter = String
    ///     typealias Result = Void
    ///     typealias Failure = ValidationError
    ///     func callAsFunction(_ text: String) throws { if text.isEmpty { throw ValidationError.empty } }
    /// }
    ///
    /// let task = Validate().execute("",
    ///     onFailure: { error in print("failed: \(error)") },
    ///     onComplete: { _ in print("ok") }
    /// )
    ///
    /// // Optionally cancel later
    /// task.cancel()
    /// ```
    func execute(_ parameters: Parameter? = nil, onFailure: @escaping (Failure) -> Void, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        let usecase = eraseToAnyUseCase
        usecase.onComplete = onComplete
        usecase.onFailure = {
            onFailure($0 as! Failure)
        }
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}

/// Syntactic sugar for executing with callbacks using function-call syntax.
public extension ThrowingUseCase {
    /// Invokes the use case using function-call syntax with callbacks.
    ///
    /// This is equivalent to calling ``execute(_:onFailure:onComplete:)``.
    ///
    /// ## Example
    /// ```swift
    /// let cancellable = myUseCase(
    ///     input,
    ///     onFailure: { print($0) },
    ///     onComplete: { print($0) }
    /// )
    /// ```
    func callAsFunction(_ parameters: Parameter? = nil, onFailure: @escaping (Failure) -> Void, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        execute(parameters, onFailure: onFailure, onComplete: onComplete)
    }
}
