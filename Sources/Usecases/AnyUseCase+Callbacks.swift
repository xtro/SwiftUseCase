import Combine

public extension AnyUseCase {
    /// Executes the use case with the provided parameters and registers completion and failure handlers.
    ///
    /// This method initiates the execution of the use case, invoking the supplied callbacks upon
    /// either successful completion or failure. It returns an `AnyCancellable` instance that can be
    /// used to cancel the ongoing operation if needed.
    ///
    /// - Parameters:
    ///   - parameters: The input parameters required by the use case. If `nil`, a default empty parameter is used.
    ///   - onFailure: A closure that is called if the use case execution fails, receiving the error.
    ///   - onComplete: A closure that is called upon successful completion of the use case.
    ///
    /// - Returns: An `AnyCancellable` instance that cancels the use case execution when deallocated or explicitly cancelled.
    ///
    /// - Example:
    ///   ```swift
    ///   let useCase = AnyUseCase<YourParameterType, YourResultType>()
    ///   let cancellable = useCase.execute(parameters, onFailure: { error in
    ///       print("Use case failed with error: \(error)")
    ///   }, onComplete: {
    ///       print("Use case completed successfully")
    ///   })
    ///   ```
    func execute(_ parameters: Parameter? = nil, onFailure: @escaping Failure, onComplete: @escaping Completion) -> AnyCancellable {
        let usecase = self
        usecase.onComplete = onComplete
        usecase.onFailure = onFailure
        usecase.execute(parameters ?? (() as! Parameter))
        return AnyCancellable { [usecase] in
            _ = usecase.cancellation?()
        }
    }
}
