/// Synchronous executable type aliases used by use case protocols.
///
/// These aliases define the canonical closure shapes for synchronous operations
/// within the library.
import Foundation

/// A closure that transforms a `Parameter` into a `Result`.
///
/// Use `Executable` to declare the execution body of a ``UseCase``.
///
/// ## Example
/// ```swift
/// struct Increment: UseCase {
///     typealias Parameter = Int
///     typealias Result = Int
///     var execute: Executable<Int, Int> { { $0 + 1 } }
/// }
/// ```
public typealias Executable<Parameter, Result> = (Parameter) -> Result

/// A closure that may throw while transforming a `Parameter` into a `Result`.
///
/// Use `ThrowingExecutable` to declare the execution body of a
/// ``ThrowingUseCase``.
///
/// - Throws: Any error produced during execution.
///
/// ## Example
/// ```swift
/// struct Validate: ThrowingUseCase {
///     typealias Parameter = String
///     typealias Result = Void
///     var execute: ThrowingExecutable<String, Void> { { text in
///         if text.isEmpty { throw ValidationError.empty }
///     } }
/// }
/// ```
public typealias ThrowingExecutable<Parameter, Result> = (Parameter) throws -> Result
