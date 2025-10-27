import Combine

/// Convenience callbacks-based APIs for ``UseCase``.
///
/// These helpers adapt a synchronous use case to a callbacks style using
/// ``AnyUseCase`` under the hood, returning an `AnyCancellable` for optional
/// cancellation.
public extension UseCase {
    /// Executes the use case and reports the result via a completion callback.
    ///
    /// This method erases the use case to ``AnyUseCase`` and executes it,
    /// forwarding success to `onComplete`.
    ///
    /// - Parameters:
    ///   - parameters: Optional input for the use case. If omitted and the
    ///     `Parameter` type is `Void`, an empty tuple is supplied automatically.
    ///   - onComplete: A closure invoked with the result on success.
    /// - Returns: An `AnyCancellable` that can be used to request cancellation.
    ///
    /// - Important: If `Parameter` is not `Void`, you must provide `parameters`.
    ///
    /// ## Example
    /// ```swift
    /// struct Add: UseCase {
    ///     typealias Parameter = Int
    ///     typealias Result = Int
    ///     func callAsFunction(_ x: Int) -> Int { x + 1 }
    /// }
    ///
    /// let task = Add().execute(41) { value in
    ///     print(value) // 42
    /// }
    ///
    /// // Optionally cancel later (no effect for synchronous work)
    /// task.cancel()
    /// ```
    func execute(_ parameters: Parameter? = nil, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        let usecase = eraseToAnyUseCase
        usecase.onComplete = { result in
            onComplete(result)
        }
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}

/// Syntactic sugar for executing with a completion callback using function-call syntax.
public extension UseCase {
    /// Invokes the use case using function-call syntax with a completion callback.
    ///
    /// This is equivalent to calling ``execute(_:onComplete:)``.
    ///
    /// ## Example
    /// ```swift
    /// let cancellable = myUseCase(
    ///     input,
    ///     onComplete: { print($0) }
    /// )
    /// ```
    func callAsFunction(_ parameters: Parameter? = nil, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        execute(parameters, onComplete: onComplete)
    }
}
