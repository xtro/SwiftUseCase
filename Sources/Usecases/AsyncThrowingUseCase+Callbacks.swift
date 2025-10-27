import Combine

/// Convenience callbacks-based APIs for ``AsyncThrowingUseCase``.
///
/// These helpers adapt an async-throwing use case to a callbacks style using
/// ``AnyUseCase`` under the hood, returning an `AnyCancellable` for optional
/// cancellation.
public extension AsyncThrowingUseCase {
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
    /// - Note: Callbacks are invoked on the same executor used by ``AnyUseCase``
    ///   (typically the main actor for async variants).
    ///
    /// ## Example
    /// ```swift
    /// struct Download: AsyncThrowingUseCase {
    ///     typealias Parameter = URL
    ///     typealias Result = Data
    ///     var execute: AsyncThrowingExecutable<URL, Data> { { url in try await client.download(url) } }
    /// }
    ///
    /// let task = Download().execute(url,
    ///     onFailure: { error in print("failed: \(error)") },
    ///     onComplete: { data in print("bytes: \(data.count)") }
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
public extension AsyncThrowingUseCase {
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

