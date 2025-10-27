import Combine

/// Convenience callbacks-based APIs for ``AsyncUseCase``.
///
/// These helpers adapt an async use case to a callbacks style using
/// ``AnyUseCase`` under the hood, returning an `AnyCancellable` for optional
/// cancellation.
public extension AsyncUseCase {
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
    /// - Note: Callbacks are invoked on the same executor used by ``AnyUseCase``
    ///   (typically the main actor for async variants).
    ///
    /// ## Example
    /// ```swift
    /// struct LoadProfile: AsyncUseCase {
    ///     typealias Parameter = UUID
    ///     typealias Result = Profile
    ///     var execute: AsyncExecutable<UUID, Profile> { { id in await api.load(id) } }
    /// }
    ///
    /// let task = LoadProfile().execute(userID) { profile in
    ///     print(profile)
    /// }
    ///
    /// // Optionally cancel later
    /// task.cancel()
    /// ```
    func execute(_ parameters: Parameter? = nil, onComplete: @escaping (Result) -> Void) -> AnyCancellable {
        let usecase = eraseToAnyUseCase
        usecase.onComplete = onComplete
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}

/// Syntactic sugar for executing with a completion callback using function-call syntax.
public extension AsyncUseCase {
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
