/// A common base protocol for synchronous use case abstractions.
///
/// ``Usecaseable`` defines the core requirements shared by higher-level
/// synchronous use case protocols, including the `Parameter`, `Result`, and
/// `Execution` associated types and the `execute` requirement.
import Foundation

/// A lightweight foundation for modeling synchronous operations.
///
/// This protocol is intentionally minimal, allowing specialized protocols like
/// ``UseCase`` and ``ThrowingUseCase`` to refine the execution shape while
/// sharing common associated types.
public protocol Usecaseable {
    /// The input type for the use case.
    associatedtype Parameter
    
    /// The output type produced by the use case.
    associatedtype Result
    
    /// The closure type that performs the work (e.g., a function of `Parameter -> Result`).
    associatedtype Execution
    
    /// The execution closure for the use case.
    ///
    /// Specialized protocols refine this to a concrete alias, for example
    /// ``UseCase/execute`` or ``ThrowingUseCase/execute``.
    var execute: Execution { get }
}
