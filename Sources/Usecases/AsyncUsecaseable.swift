/// A common base protocol for async use case abstractions.
///
/// ``AsyncUsecaseable`` defines the core requirements shared by higher-level
/// use case protocols in this package, including the `Parameter`, `Result`, and
/// `Execution` associated types and the `execute` requirement.
import Foundation

/// A lightweight foundation for modeling asynchronous operations.
///
/// This protocol is intentionally minimal, allowing specialized protocols like
/// ``AsyncUseCase`` and ``AsyncThrowingUseCase`` to refine the execution shape
/// with concrete closure aliases while sharing common associated types.
///
/// - Note: Conforming types should ensure that `Parameter`, `Result`, and
///   `Execution` are `Sendable` to be safely used across concurrency domains.
public protocol AsyncUsecaseable {
    /// The input type for the use case. Must conform to `Sendable`.
    associatedtype Parameter: Sendable
    /// The output type produced by the use case. Must conform to `Sendable`.
    associatedtype Result: Sendable
    /// The closure type that performs the work (e.g., ``AsyncExecutable`` or ``AsyncThrowingExecutable``).
    associatedtype Execution: Sendable
    /// The execution closure for the use case.
    ///
    /// Specialized protocols refine this to a concrete alias, for example
    /// ``AsyncUseCase/execute`` or ``AsyncThrowingUseCase/execute``.
    var execute: Execution { get }
}

