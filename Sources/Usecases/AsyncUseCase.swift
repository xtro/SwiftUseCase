/// A lightweight abstraction for asynchronous use cases.
///
/// The types in this file define a protocol for modeling domain-specific
/// operations as async functions. Conforming types expose an `execute` closure
/// and gain convenient `callAsFunction` overloads so they can be invoked like
/// regular async functions.
///
/// - Note: This protocol builds on `AsyncUsecaseable` and relies on the
///   associated `Parameter` and `Result` types as well as the
///   `AsyncExecutable` alias.

import Foundation

/// A protocol that models an asynchronous use case with a strongly typed
/// input and output.
///
/// Conform to `AsyncUseCase` to represent a single unit of asynchronous
/// work in your domain, such as loading data from a network, persisting a
/// value, or computing a result in the background.
///
/// Conforming types provide an `execute` closure that performs the work.
/// Through the `callAsFunction` overloads, instances can be invoked like an
/// async function:
///
/// ```swift
/// let useCase = FetchUserUseCase(service: api)
/// let user = await useCase(userID)
/// ```
///
/// - SeeAlso: ``AsyncUsecaseable``
/// - Important: `AsyncUseCase` is intentionally minimal. Keep business logic
///   inside the conforming type and avoid side effects where possible.
/// - Tip: Use value semantics (structs) for simple use cases and classes when
///   you need reference semantics, such as sharing mutable dependencies.
public protocol AsyncUseCase: AsyncUsecaseable {
    /// The asynchronous operation that performs the use case.
    ///
    /// Implement this property to provide the core logic of the use case.
    /// The closure receives the `Parameter` and returns the `Result` asynchronously.
    ///
    /// Example
    /// ```swift
    /// struct FetchUserUseCase: AsyncUseCase {
    ///     typealias Parameter = UUID
    ///     typealias Result = User
    ///
    ///     let service: UserService
    ///
    ///     var execute: AsyncExecutable<Parameter, Result> {
    ///         { id in
    ///             try? await Task.sleep(nanoseconds: 50_000_000)
    ///             return await service.fetchUser(id: id)
    ///         }
    ///     }
    /// }
    /// ```
    var execute: AsyncExecutable<Parameter, Result> { get }
}

public extension AsyncUseCase {
    /// Invokes the use case with the given parameters.
    ///
    /// This overload forwards the call to ``execute`` and allows you to call
    /// the use case like a function:
    ///
    /// ```swift
    /// let result = await myUseCase(input)
    /// ```
    ///
    /// - Parameter parameters: The input value passed to the use case.
    /// - Returns: The result produced by the use case.
    /// - SeeAlso: ``callAsFunction()``
    func callAsFunction(_ parameters: Parameter) async -> Result {
        await execute(parameters)
    }

    /// Invokes the use case that does not require input.
    ///
    /// Use this overload when the use case's `Parameter` type is `Void`.
    /// It forwards the call to ``execute`` with an empty tuple.
    ///
    /// ```swift
    /// struct WarmUpCacheUseCase: AsyncUseCase {
    ///     typealias Parameter = Void
    ///     typealias Result = Bool
    ///
    ///     var execute: AsyncExecutable<Parameter, Result> { { _ in
    ///         await cache.warmUp()
    ///     } }
    /// }
    ///
    /// let success = await WarmUpCacheUseCase().callAsFunction()
    /// // or simply:
    /// let ok = await WarmUpCacheUseCase()()
    /// ```
    ///
    /// - Returns: The result produced by the use case.
    /// - SeeAlso: ``callAsFunction(_:)``
    func callAsFunction() async -> Result where Parameter == Void {
        await execute(())
    }
}

