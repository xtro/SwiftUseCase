/// Async executable type aliases used by use case protocols.
///
/// These aliases define the canonical closure shapes for asynchronous
/// operations within the library, with `@Sendable` enforcement for safe
/// use across concurrency domains.
///
/// A sendable async closure that transforms a `Parameter` into a `Result`.
///
/// Use `AsyncExecutable` to declare the execution body of an ``AsyncUseCase``.
/// The closure runs asynchronously and must be `@Sendable` so it can execute
/// safely on concurrent executors.
///
/// - Parameters:
///   - Parameter: The input type, which must conform to `Sendable`.
///   - Result: The output type, which must conform to `Sendable`.
///
/// ## Example
/// ```swift
/// struct LoadProfile: AsyncUseCase {
///     typealias Parameter = UUID
///     typealias Result = Profile
///
///     var execute: AsyncExecutable<UUID, Profile> {
///         { id in
///             try? await Task.sleep(nanoseconds: 50_000_000)
///             return await api.loadProfile(id: id)
///         }
///     }
/// }
/// ```
public typealias AsyncExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async -> Result

/// A sendable async closure that may throw while transforming a `Parameter` into a `Result`.
///
/// Use `AsyncThrowingExecutable` to declare the execution body of an
/// ``AsyncThrowingUseCase``. The closure runs asynchronously and is marked
/// `@Sendable` for safe use across concurrency domains.
///
/// - Parameters:
///   - Parameter: The input type, which must conform to `Sendable`.
///   - Result: The output type, which must conform to `Sendable`.
///
/// - Throws: Any error produced during execution.
///
/// ## Example
/// ```swift
/// struct Download: AsyncThrowingUseCase {
///     typealias Parameter = URL
///     typealias Result = Data
///
///     var execute: AsyncThrowingExecutable<URL, Data> {
///         { url in try await client.download(url) }
///     }
/// }
/// ```
public typealias AsyncThrowingExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async throws -> Result

