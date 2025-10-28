# SwiftUseCase

[![Swift](https://img.shields.io/badge/Swift-5.10+-FF4A00.svg)](https://swift.org)  
![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20watchOS%206%2B%20%7C%20tvOS%2013%2B%20%7C%20macOS%2010.15%2B-333333)  
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)  
![License](https://img.shields.io/github/license/xtro/SwiftUseCase)

A lightweight, strongly typed use‑case layer for Swift. Cleanly separate **what the app does** from **how it is shown**. Ships with a macro that generates the boilerplate for you, plus clean concurrency‑first executables.

---

## Why SwiftUseCase

Application features are easiest to reason about when **business actions** are modeled explicitly. A use case is a single, named operation with a typed input and a typed output. This library gives you that modeling surface with minimal ceremony, so your code reads like intent, not plumbing.

### What problems it solves
- **Massive ViewModels / Massive Interactors:** view and presentation layers accumulate fetching, validation, mapping, feature flags and side effects. Use cases pull that back into thin, composable units.
- **Hidden coupling:** implicit dependencies burrow into closures and singletons. A use case exposes its dependency boundary via `Parameter` and the injected `execute` closure.
- **Inconsistent async/throwing handling:** different teams pick different conventions. Here every shape has a canonical protocol and executable type, so the call sites are uniform.
- **Hard‑to‑test logic:** with logic smeared across layers, tests become UI‑driven and brittle. A use case is a tiny function you can call directly, stub, or wrap in `AnyUseCase`.

### Why not just services or helpers?
Services are long‑lived bags of methods. They encourage temporal coupling and often leak transport details into call sites. A **use case** is **short‑lived**, **single‑purpose**, and **named after the intent**. You compose use cases to form flows, not the other way around. The result is clearer boundaries, easier replacement, and stronger invariants.

### Design guarantees you get
- **Typed contract:** `Parameter` and `Result` are explicit. Multiple inputs are auto‑wrapped into a generated `Parameter` struct, zero inputs become `Void`.
- **Uniform execution:** `UseCase`, `ThrowingUseCase`, `AsyncUseCase`, `AsyncThrowingUseCase` share the same ergonomics, including `callAsFunction`.
- **Cancellation‑safety:** async variants play well with `Task` cancellation; bridging patterns are shown in the docs.
- **Macro ergonomics when you want them:** annotate a function with `@Usecase` (inside a type), get a concrete type plus a ready‑made static instance. No reflection, no magic at runtime.

### When to introduce a use case
- The operation represents a **domain action**: FetchUser, UpdateProfile, ValidatePurchase.
- The logic needs **isolated tests** or to be **reused** across app and widgets/extensions.
- You want to **decouple transport** (URLSession, CoreData, CloudKit) from the intent.
- A team agreement is to keep ViewModels dumb: compose use cases there, don’t implement them there.

### Testing and evolution
- Inject `execute` to stub, spy, or time‑travel. You can also erase to `AnyUseCase` for higher‑order composition.
- Start without the macro to establish the contract; add `@Usecase` later to reduce boilerplate. Or do the reverse. The protocols stay stable either way.

### Performance and safety
- Use cases compile down to plain functions and closures. No dynamic dispatch is required beyond what you opt into.
- Protocols are small and composable; Swift’s inlining does the rest. You pay only for what you write.

In short: if you want clean, explicit, concurrency‑friendly business logic with first‑class testability, there isn’t a better path. This is the simple, boring foundation you’ll be glad you picked six months from now.

## Requirements

- Swift 5.10+
- iOS 13+ / watchOS 6+ / tvOS 13+ / macOS 10.15+

---

## Installation (Swift Package Manager)

```swift
.package(url: "https://github.com/xtro/SwiftUseCase.git", from: "1.0.0")
```

Targets:

```swift
.target(
  name: "App",
  dependencies: [
    .product(name: "SwiftUseCase", package: "SwiftUseCase"),
    .product(name: "SwiftUseCaseMacro", package: "SwiftUseCase") // if you use the macro
  ]
)
```

---

## Quick Start with `@Usecase`

Define your use case **inside a namespace type**. An `enum` is a good fit.

```swift
import SwiftUseCase

enum AppUsecases {}

extension AppUsecases {
  @Usecase
  static func fetchUser(id: Int, session: URLSession) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, _) = try await session.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
  }
}
```

The macro generates next to it:

- `struct FetchUserUsecase: AsyncThrowingUseCase` with `Parameter` and `Result`
- `public static let fetchUser = FetchUserUsecase()` on `AppUsecases`

### Using the generated API

Prefer the static instance for clarity:

```swift
let user = try await AppUsecases.fetchUser(.init(id: 1, session: .shared))
```

Or access the concrete type directly:

```swift
let uc = AppUsecases.FetchUserUsecase()
let user = try await uc(.init(id: 1, session: .shared))
```

Multiple parameters are automatically wrapped into a `Parameter` struct. No parameters result in `Parameter == Void` and you can call `uc()` with no arguments.

---

## Without the macro

You can write the same thing explicitly:

```swift
struct ValidateEmail: ThrowingUseCase {
  typealias Parameter = String
  typealias Result = Void
  var execute: ThrowingExecutable<Parameter, Result> { { email in
    guard email.contains("@") else { throw ValidationError.invalid }
  } }
}

try ValidateEmail()("me@example.com")
```

---

## Cancellation‑aware bridging example

A more realistic modern scenario: uploading data with progress and retry policy. The macro handles the boilerplate, you focus on intent.

```swift
extension AppUsecases {
  @Usecase
  static func uploadImage(_ image: UIImage, to url: URL, session: URLSession) async throws -> URLResponse {
    let data = image.jpegData(compressionQuality: 0.8)!

    for attempt in 1...3 {
      do {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (responseData, response) = try await session.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
          throw URLError(.badServerResponse)
        }
        print("✅ Upload success after attempt #\(attempt)")
        return http
      } catch {
        print("⚠️ Upload attempt #\(attempt) failed: \(error)")
        if attempt == 3 { throw error }
        try await Task.sleep(for: .seconds(Double(attempt))) // exponential-ish backoff
      }
    }

    throw URLError(.cannotConnectToHost)
  }
}
```

This example showcases async/throwing flow control, retry logic, and cancellation safety without clutter. The macro turns it into a fully‑typed, testable `AsyncThrowingUseCase` with a static `uploadImage` instance ready to call.

---

## Testing

Inject a custom `execute` for stubs and spies.

```swift
let stub = AppUsecases.FetchUserUsecase { _ in .init(id: 0, name: "Stub") }
let user = try await stub(.init(id: 42, session: .shared))
```

You can also erase types:

```swift
let any: AnyUseCase<AppUsecases.FetchUserUsecase.Parameter, AppUsecases.FetchUserUsecase.Result>
  = .init(AppUsecases.FetchUserUsecase())
```

Combine publishers and callback helpers live in `AnyUseCase+Combine` and `*+Callbacks`.

---

## API Surface

The library exposes four main protocol families, each covering one execution flavor so your business logic can express exactly what it needs—no more, no less.

- **`UseCase` / `Executable<Parameter, Result>`** — for synchronous, pure functions. Ideal for lightweight computations or formatting.
- **`ThrowingUseCase` / `ThrowingExecutable<Parameter, Result>`** — same as above but can throw. Use when validation or failure paths are part of the contract.
- **`AsyncUseCase` / `AsyncExecutable<Parameter, Result>`** — asynchronous but non‑throwing. Fits I/O or concurrent jobs that always succeed logically.
- **`AsyncThrowingUseCase` / `AsyncThrowingExecutable<Parameter, Result>`** — the full async + error model; your network or database boundaries usually live here.
- **`AnyUseCase`** — type erasure wrapper that hides generics so you can store heterogeneous use cases in arrays, dependency containers, or pass them around dynamically.

Each protocol shares the same shape and ergonomics: a `Parameter`, a `Result`, and an `execute` closure. The uniformity means once you know one, you know them all.

---

## Documentation

DocC catalog included at `Documentation/SwiftUseCase.docc`. In Xcode use Product → Build Documentation.

---

## License

MIT. See `LICENSE`.

