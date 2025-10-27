import Foundation

/// A protocol that models a synchronous use case with a strongly typed input and output.
///
/// Conform to `UseCase` to represent a single unit of synchronous work in your
/// domain, such as computing a value, formatting data, or performing a quick
/// lookup.
///
/// Conforming types provide an `execute` closure that performs the work.
/// Through the `callAsFunction` overloads, instances can be invoked like a
/// function:
///
/// ```swift
/// let useCase = FormatDateUseCase()
/// let text = useCase(date)
/// ```
///
/// - SeeAlso: ``Usecaseable``
public protocol UseCase: Usecaseable {
    /// The synchronous operation that performs the use case.
    ///
    /// Implement this property to provide the core logic of the use case.
    /// The closure receives the `Parameter` and returns the `Result`.
    ///
    /// ## Example
    /// ```swift
    /// struct Increment: UseCase {
    ///     typealias Parameter = Int
    ///     typealias Result = Int
    ///     var execute: Executable<Int, Int> { { $0 + 1 } }
    /// }
    /// ```
    var execute: Executable<Parameter, Result> { get }
}

public extension UseCase {
    /// Invokes the use case with the given parameters.
    ///
    /// This overload forwards the call to ``execute`` and allows you to call
    /// the use case like a function:
    ///
    /// ```swift
    /// let value = myUseCase(input)
    /// ```
    ///
    /// - Parameter parameters: The input value passed to the use case.
    /// - Returns: The result produced by the use case.
    /// - SeeAlso: ``callAsFunction()``
    func callAsFunction(_ parameters: Parameter) -> Result {
        execute(parameters)
    }

    /// Invokes the use case that does not require input.
    ///
    /// Use this overload when the use case's `Parameter` type is `Void`.
    /// It forwards the call to ``execute`` with an empty tuple.
    ///
    /// ```swift
    /// struct WarmUp: UseCase {
    ///     typealias Parameter = Void
    ///     typealias Result = Bool
    ///     var execute: Executable<Void, Bool> { { _ in true } }
    /// }
    ///
    /// let ok = WarmUp()()
    /// ```
    ///
    /// - Returns: The result produced by the use case.
    /// - SeeAlso: ``callAsFunction(_:)``
    func callAsFunction() -> Result where Parameter == Void {
        execute(())
    }
}
