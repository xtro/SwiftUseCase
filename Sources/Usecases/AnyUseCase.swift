/// A protocol for type-erased use case objects that orchestrate asynchronous operations with optional cancellation, completion, and failure handling.
///
/// Conformers encapsulate use case logic into a uniform interface, facilitating composition and flexible dependency management.
///
/// You typically do not conform to `AnyUseCaseType` directly. Instead, use existing implementations such as ``AnyUseCase``.
///
/// This protocol defines common closures for cancellation, completion, and failure handling, as well as access to the use case's parameters.
///
/// ### Example
///
/// ```swift
/// let useCase: AnyUseCase<Int, String> = AnyUseCase { intParam in
///     print("Parameter: \(intParam)")
/// }
/// useCase.execute(42)
/// ```
public protocol AnyUseCaseType: Usecaseable {
    /// A closure type called to attempt cancellation.
    /// Returns `true` if the cancellation completed successfully, otherwise `false`.
    typealias Cancellation = () -> Bool
    
    /// A closure type called upon completion of the use case, with a `Result` parameter.
    typealias Completion = (Result) -> Void
    
    /// A closure type called when the use case execution fails, with an `Error` parameter.
    typealias Failure = (Error) -> Void

    /// Closure invoked to cancel the use case.
    ///
    /// Returns `true` if the cancellation was successful.
    ///
    /// You can set this property to provide custom cancellation behavior.
    var cancellation: Cancellation? { get set }
    
    /// Closure invoked when the use case execution fails.
    ///
    /// You can set this property to handle errors occurred during execution.
    var onFailure: Failure? { get set }
    
    /// Closure invoked upon completion of the use case execution.
    ///
    /// You can set this property to handle successful completion with the resulting value.
    var onComplete: Completion? { get set }
    
    /// The parameters passed to the use case.
    ///
    /// This property provides the input parameters for the use case execution, if any.
    var parameters: Parameter? { get }
}

/// A type-erased use case object that executes provided closures with optional cancellation, completion, and failure handling.
///
/// Use `AnyUseCase` when you want to encapsulate use case logic into a reusable, composable component without exposing its concrete type.
///
/// You initialize `AnyUseCase` with an execution closure that accepts parameters of type `Parameter`. Optionally, you can provide
/// cancellation behavior by setting the `cancellation` closure property.
///
/// The use case supports invocation via the `callAsFunction(_:)` method, enabling concise syntax.
///
/// ### Example
///
/// ```swift
/// let useCase = AnyUseCase<Int, Void> { param in
///     print("Executing use case with parameter: \(param)")
/// }
///
/// // Execute with parameter
/// useCase(10)
/// ```
///
/// You can also configure cancellation handling:
///
/// ```swift
/// useCase.cancellation = {
///     print("Cancellation requested")
///     return true
/// }
///
/// do {
///     let didCancel = try useCase.cancel()
///     print("Cancellation successful: \(didCancel)")
/// } catch {
///     print("Cancellation not supported")
/// }
/// ```
public class AnyUseCase<Parameter: Sendable, Result: Sendable>: AnyUseCaseType {
    /// The closure type for executing the use case logic.
    public typealias Execution = (Parameter) -> Void

    /// The closure invoked to execute the use case with the given parameters.
    public var execute: (Parameter) -> Void
    
    /// The closure invoked to attempt cancellation of the use case.
    ///
    /// Returns `true` if the cancellation succeeded.
    public var cancellation: Cancellation?
    
    /// The closure invoked when the use case execution fails.
    public var onFailure: Failure?
    
    /// The closure invoked when the use case completes successfully.
    public var onComplete: Completion?
    
    /// The parameters passed to the use case.
    ///
    /// This value is used as a default when executing the use case without an explicit parameter.
    public let parameters: Parameter?

    /// Executes the use case with the provided parameter or the stored parameter if none is provided.
    ///
    /// - Parameter parameters: The input parameter to pass to the use case execution closure. If `nil`, falls back to the stored parameters.
    ///
    /// If neither is available, this method will force cast an empty tuple to `Parameter`, which may cause a runtime error if `Parameter` is not `Void`.
    public func callAsFunction(_ parameters: Parameter? = nil) {
        execute(parameters ?? self.parameters ?? (() as! Parameter))
    }

    /// Creates an instance of `AnyUseCase`.
    ///
    /// - Parameters:
    ///   - execution: The execution closure that will be triggered when the use case is called.
    ///   - cancellation: An optional cancellation closure that will be triggered on cancellation attempts. Defaults to `nil`.
    ///
    /// Use this initializer to create a use case instance wrapping the provided execution closure.
    public init(_ execution: Execution? = nil, _: Cancellation? = nil) {
        execute = execution ?? { _ in }
        cancellation = nil
        parameters = nil
    }

    enum Error: Swift.Error {
        case unsupportedCancellation
    }

    /// Attempts to cancel the use case execution.
    ///
    /// - Returns: A Boolean value indicating whether the cancellation was successful.
    ///
    /// - Throws: `Error.unsupportedCancellation` if the cancellation closure is not defined.
    ///
    /// Call this method to request cancellation of the use case. If the `cancellation` closure is not set,
    /// this method throws an error.
    public func cancel() throws -> Bool {
        if let cancelled = cancellation?() {
            return cancelled
        }
        throw Error.unsupportedCancellation
    }
}
