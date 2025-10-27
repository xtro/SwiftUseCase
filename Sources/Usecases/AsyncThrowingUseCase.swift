/// A protocol for asynchronous, throwing use cases.
///
/// Use ``AsyncThrowingUseCase`` to model domain operations that perform work
/// asynchronously and may fail with an error. Conforming types expose an
/// `execute` closure and gain `callAsFunction` overloads for ergonomic usage.
import Foundation

/// A protocol that models an asynchronous use case which can throw errors.
///
/// Conform to `AsyncThrowingUseCase` to represent a single unit of async work
/// that might fail, such as performing a network request, reading from disk,
/// or validating user input on a background executor.
///
/// Instances provide an `execute` closure for the core logic and can be invoked
/// like an async throwing function via `callAsFunction`:
///
/// ```swift
/// let user = try await fetchUser(userID)
/// ```
///
/// - SeeAlso: ``AsyncUsecaseable``
/// - Important: Keep business logic inside the conforming type and prefer
///   pure functions where possible. Handle cancellation cooperatively.
public protocol AsyncThrowingUseCase: AsyncUsecaseable {
    /// The error type produced by this use case. Defaults to ``Swift/Error``.
    associatedtype Failure = Error

    /// The asynchronous, throwing operation that performs the use case.
    ///
    /// Implement this property to provide the core logic of the use case.
    /// The closure receives the `Parameter` and either returns the `Result`
    /// or throws an error.
    ///
    /// ## Example
    /// ```swift
    /// struct DownloadFile: AsyncThrowingUseCase {
    ///     typealias Parameter = URL
    ///     typealias Result = Data
    ///
    ///     var execute: AsyncThrowingExecutable<URL, Data> {
    ///         { url in try await client.download(url) }
    ///     }
    /// }
    /// ```
    var execute: AsyncThrowingExecutable<Parameter, Result> { get }
}

public extension AsyncThrowingUseCase {
    /// Invokes the use case with the given parameters.
    ///
    /// This overload forwards the call to ``execute`` and allows you to call
    /// the use case like an async throwing function:
    ///
    /// ```swift
    /// let value = try await myUseCase(input)
    /// ```
    ///
    /// - Parameter parameters: The input value passed to the use case.
    /// - Returns: The result produced by the use case.
    /// - Throws: An error thrown by the use case.
    /// - SeeAlso: ``callAsFunction()``
    func callAsFunction(_ parameters: Parameter) async throws -> Result {
        try await execute(parameters)
    }

    /// Invokes the use case that does not require input.
    ///
    /// Use this overload when the use case's `Parameter` type is `Void`.
    /// It forwards the call to ``execute`` with an empty tuple.
    ///
    /// ```swift
    /// struct WarmUpCache: AsyncThrowingUseCase {
    ///     typealias Parameter = Void
    ///     typealias Result = Bool
    ///     var execute: AsyncThrowingExecutable<Void, Bool> { { _ in try await cache.warmUp() } }
    /// }
    ///
    /// let ok = try await WarmUpCache()()
    /// ```
    ///
    /// - Returns: The result produced by the use case.
    /// - Throws: An error thrown by the use case.
    /// - SeeAlso: ``callAsFunction(_:)``
    func callAsFunction() async throws -> Result where Parameter == Void {
        try await execute(())
    }
}

