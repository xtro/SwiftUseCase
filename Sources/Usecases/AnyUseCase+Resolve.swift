import Foundation

/// Type-erasure helpers for converting concrete use cases into ``AnyUseCase``.
///
/// These extensions provide convenient properties and initializers to wrap
/// concrete use case implementations (synchronous, asynchronous, throwing,
/// and async-throwing) into the type-erased ``AnyUseCase`` container. This
/// enables uniform handling from UI layers and composition points without
/// exposing generic parameters.
public extension UseCase {
    /// Erases this ``UseCase`` to a type-erased ``AnyUseCase``.
    ///
    /// Use this property to adapt a concrete, synchronous use case for APIs
    /// that operate on ``AnyUseCase``. The returned wrapper forwards execution
    /// to the underlying use case and publishes the result via
    /// ``AnyUseCase/onComplete``.
    ///
    /// - Returns: An ``AnyUseCase`` wrapping this ``UseCase``.
    ///
    /// ## Example
    /// ```swift
    /// struct AddToCart: UseCase {
    ///     typealias Parameter = Product.ID
    ///     typealias Result = Bool
    ///     func callAsFunction(_ id: Product.ID) -> Bool { cart.add(id) }
    /// }
    ///
    /// let any = AddToCart().eraseToAnyUseCase
    /// any.onComplete = { success in print(success) }
    /// any.execute(Product.ID(42))
    /// ```
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

/// Extensions for erasing an `AsyncUseCase` to an `AnyUseCase`.
public extension AsyncUseCase {
    /// Erases this ``AsyncUseCase`` to a type-erased ``AnyUseCase``.
    ///
    /// The returned wrapper executes the async use case on demand and
    /// publishes the result to ``AnyUseCase/onComplete`` on the main actor.
    ///
    /// - Returns: An ``AnyUseCase`` wrapping this ``AsyncUseCase``.
    ///
    /// ## Example
    /// ```swift
    /// struct LoadProfile: AsyncUseCase {
    ///     typealias Parameter = UUID
    ///     typealias Result = Profile
    ///     var execute: AsyncExecutable<UUID, Profile> { { id in await api.load(id) } }
    /// }
    ///
    /// let any = LoadProfile().eraseToAnyUseCase
    /// any.onComplete = { profile in render(profile) }
    /// any.execute(userID)
    /// ```
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

/// Extensions for erasing a `ThrowingUseCase` to an `AnyUseCase`.
public extension ThrowingUseCase {
    /// Erases this ``ThrowingUseCase`` to a type-erased ``AnyUseCase``.
    ///
    /// The returned wrapper executes the throwing use case and forwards either
    /// the successful value to ``AnyUseCase/onComplete`` or the error to
    /// ``AnyUseCase/onFailure``.
    ///
    /// - Returns: An ``AnyUseCase`` wrapping this ``ThrowingUseCase``.
    ///
    /// ## Example
    /// ```swift
    /// struct Validate: ThrowingUseCase {
    ///     typealias Parameter = String
    ///     typealias Result = Void
    ///     func callAsFunction(_ text: String) throws { if text.isEmpty { throw ValidationError.empty } }
    /// }
    ///
    /// let any = Validate().eraseToAnyUseCase
    /// any.onFailure = { print($0) }
    /// any.execute("")
    /// ```
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

/// Extensions for erasing an `AsyncThrowingUseCase` to an `AnyUseCase`.
public extension AsyncThrowingUseCase {
    /// Erases this ``AsyncThrowingUseCase`` to a type-erased ``AnyUseCase``.
    ///
    /// The returned wrapper runs the async throwing use case in a detached task,
    /// publishing the result to ``AnyUseCase/onComplete`` or the error to
    /// ``AnyUseCase/onFailure`` on the main actor.
    ///
    /// - Returns: An ``AnyUseCase`` wrapping this ``AsyncThrowingUseCase``.
    ///
    /// - Note: The wrapper supports cooperative cancellation via
    ///   ``AnyUseCase/cancellation``.
    ///
    /// ## Example
    /// ```swift
    /// struct Download: AsyncThrowingUseCase {
    ///     typealias Parameter = URL
    ///     typealias Result = Data
    ///     func callAsFunction(_ url: URL) async throws -> Data { try await client.download(url) }
    /// }
    ///
    /// let any = Download().eraseToAnyUseCase
    /// any.onComplete = { data in print("bytes: \(data.count)") }
    /// any.onFailure = { error in print("error: \(error)") }
    /// any.execute(fileURL)
    /// ```
    var eraseToAnyUseCase: AnyUseCase<Parameter, Result> {
        AnyUseCase(usecase: self)
    }
}

/// Extensions to construct `AnyUseCase` from different use case protocols.
public extension AnyUseCase {
    /// Creates an ``AnyUseCase`` wrapping a synchronous ``UseCase``.
    ///
    /// When executed, the wrapper invokes the underlying use case immediately
    /// on the calling context and forwards the result to ``onComplete``.
    ///
    /// - Parameter usecase: A synchronous ``UseCase`` implementation to wrap.
    ///
    /// ## Discussion
    /// This initializer is useful when you need to pass a use case through APIs
    /// that expect a non-generic type while preserving behavior.
    ///
    /// ## Example
    /// ```swift
    /// let any = AnyUseCase(usecase: AddToCart())
    /// any.onComplete = { print($0) }
    /// any.execute(123)
    /// ```
    convenience init<U: UseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        execute = { [weak self] parameters in
            guard let self else { return }
            onComplete?(usecase(parameters))
        }
    }
}

public extension AnyUseCase {
    /// Creates an ``AnyUseCase`` wrapping an asynchronous ``AsyncUseCase``.
    ///
    /// The wrapper executes the async use case in a detached task and posts the
    /// result to ``onComplete`` on the main actor.
    ///
    /// - Parameter usecase: An asynchronous ``AsyncUseCase`` implementation to wrap.
    ///
    /// - Note: A `cancellation` handler is provided to cancel the underlying task.
    ///
    /// ## Example
    /// ```swift
    /// let any = AnyUseCase(usecase: LoadProfile())
    /// any.onComplete = { profile in render(profile) }
    /// any.execute(userID)
    /// ```
    convenience init<U: AsyncUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        execute = { parameters in
            task = Task.detached { [usecase] in
                let result = await usecase(parameters)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    onComplete?(result)
                }
            }
        }
        cancellation = {
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}

public extension AnyUseCase {
    /// Creates an ``AnyUseCase`` wrapping a throwing ``ThrowingUseCase``.
    ///
    /// The wrapper executes the use case and forwards either the result to
    /// ``onComplete`` or the error to ``onFailure``.
    ///
    /// - Parameter usecase: A throwing ``ThrowingUseCase`` implementation to wrap.
    ///
    /// ## Example
    /// ```swift
    /// let any = AnyUseCase(usecase: Validate())
    /// any.onFailure = { print($0) }
    /// any.execute(input)
    /// ```
    convenience init<U: ThrowingUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        execute = { [weak self] parameters in
            guard let self else { return }
            do {
                let result = try usecase(parameters)
                onComplete?(result)
            } catch {
                onFailure?(error)
            }
        }
    }
}

public extension AnyUseCase {
    /// Creates an ``AnyUseCase`` wrapping an asynchronous throwing ``AsyncThrowingUseCase``.
    ///
    /// The wrapper runs the use case in a detached task, checks for cancellation,
    /// and posts callbacks on the main actor.
    ///
    /// - Parameter usecase: An asynchronous throwing ``AsyncThrowingUseCase`` implementation to wrap.
    ///
    /// - Important: Cancellation is cooperative. Ensure the underlying use case
    ///   regularly checks for cancellation to stop early when appropriate.
    ///
    /// ## Example
    /// ```swift
    /// let any = AnyUseCase(usecase: Download())
    /// any.onComplete = { data in print(data.count) }
    /// any.onFailure = { error in print(error) }
    /// any.execute(url)
    /// ```
    convenience init<U: AsyncThrowingUseCase>(usecase: U) where U.Parameter == Parameter, U.Result == Result {
        self.init()
        var task: Task<Void, Never>?
        execute = { parameters in
            task = Task.detached { [usecase] in
                do {
                    let result = try await usecase(parameters)
                    try Task.checkCancellation()
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        onComplete?(result)
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        onFailure?(error)
                    }
                }
            }
        }
        cancellation = { [task] in
            task?.cancel()
            return task?.isCancelled ?? false
        }
    }
}

