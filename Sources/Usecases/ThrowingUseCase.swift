import Foundation

/// A protocol that models a synchronous use case which can throw errors.
///
/// Conform to `ThrowingUseCase` to represent a single unit of work in your
/// domain that might fail, such as validating input or performing a blocking
/// operation that can error.
///
/// Conforming types provide an `execute` closure that performs the work.
/// Through the `callAsFunction` overloads, instances can be invoked like a
/// throwing function:
///
/// ```swift
/// let value = try validate(input)
/// ```
///
/// - SeeAlso: ``Usecaseable``
public protocol ThrowingUseCase: Usecaseable {
    /// The error type produced by this use case. Defaults to ``Swift/Error``.
    associatedtype Failure = Error

    /// The synchronous, throwing operation that performs the use case.
    ///
    /// Implement this property to provide the core logic of the use case.
    /// The closure receives the `Parameter` and either returns the `Result`
    /// or throws an error.
    ///
    /// ## Example
    /// ```swift
    /// struct Validate: ThrowingUseCase {
    ///     typealias Parameter = String
    ///     typealias Result = Void
    ///     func callAsFunction(_ text: String) throws { if text.isEmpty { throw ValidationError.empty } }
    ///     var execute: ThrowingExecutable<String, Void> { { try self($0) } }
    /// }
    /// ```
    var execute: ThrowingExecutable<Parameter, Result> { get }
}

public extension ThrowingUseCase {
    /// Invokes the use case with the given parameters.
    ///
    /// This overload forwards the call to ``execute`` and allows you to call
    /// the use case like a throwing function:
    ///
    /// ```swift
    /// let value = try myUseCase(input)
    /// ```
    ///
    /// - Parameter parameters: The input value passed to the use case.
    /// - Returns: The result produced by the use case.
    /// - Throws: An error thrown by the use case.
    /// - SeeAlso: ``callAsFunction()``
    func callAsFunction(_ parameters: Parameter) throws -> Result {
        try execute(parameters)
    }

    /// Invokes the use case that does not require input.
    ///
    /// Use this overload when the use case's `Parameter` type is `Void`.
    /// It forwards the call to ``execute`` with an empty tuple.
    ///
    /// ```swift
    /// struct WarmUp: ThrowingUseCase {
    ///     typealias Parameter = Void
    ///     typealias Result = Bool
    ///     func callAsFunction() throws -> Bool { true }
    ///     var execute: ThrowingExecutable<Void, Bool> { { _ in try self.callAsFunction() } }
    /// }
    ///
    /// let ok = try WarmUp()()
    /// ```
    ///
    /// - Returns: The result produced by the use case.
    /// - Throws: An error thrown by the use case.
    /// - SeeAlso: ``callAsFunction(_:)``
    func callAsFunction() throws -> Result where Parameter == Void {
        try execute(())
    }
}
