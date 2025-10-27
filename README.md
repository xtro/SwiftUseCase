# SwiftUseCase

[![Swift](https://github.com/xtro/SwiftUseCase/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/xtro/SwiftUseCase/actions/workflows/swift.yml)  
![platforms](https://img.shields.io/badge/platform-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS-333333)  
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)  
![GitHub](https://img.shields.io/github/license/xtro/SwiftUseCase)  
![Current version](https://img.shields.io/github/v/tag/xtro/SwiftUseCase)

**SwiftUseCase** is a lightweight yet powerful library for structuring your app’s business logic into independent, testable, and reusable *use cases*.  
It provides a unified execution API that supports both synchronous and asynchronous operations, including Combine and Swift Concurrency.

---

## 💡 Why SwiftUseCase?

Modern iOS apps often suffer from “massive” view models or tangled service layers. SwiftUseCase helps you isolate **what the app does** from **how the app presents it**.  
Each *use case* represents a single, clearly defined piece of logic—fetching data, validating input, processing images, or saving user preferences.

With this structure:
- You can easily **unit test** each operation in isolation.  
- You can **reuse** business logic across platforms (iOS, macOS, watchOS, tvOS).  
- You can **simplify** your view models and make them fully reactive.

**Example scenarios:**
- `FetchUserProfileUseCase` retrieves user data from an API.
- `UploadAvatarUseCase` handles image uploads with retry logic.
- `SaveUserSettingsUseCase` writes data to local storage.
- `ValidatePasswordUseCase` checks password strength before signup.

All of them share the same simple execution pattern.

---

## ⚙️ Installation

You can integrate the library using **Swift Package Manager** by adding the following dependency:

```swift
.package(url: "https://github.com/xtro/SwiftUseCase.git", .upToNextMajor(from: "0.0.1"))
```

Alternatively, in Xcode go to  
`File → Add Packages...` and search for the repository URL.

---

## 🧠 Core Concepts

A *UseCase* defines three things:
1. **Parameter** — the input type.
2. **Result** — the output type.
3. **Execution** — the actual callable implementation.

```swift
public protocol UseCaseable {
    associatedtype Parameter: Sendable
    associatedtype Result: Sendable
    associatedtype Execution: Sendable
    var execute: Execution { get }
}
```

SwiftUseCase provides four types of executions, covering all async/sync and throwing combinations:

```swift
public typealias Executable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) -> Result
public typealias AsyncExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async -> Result
public typealias ThrowingExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) throws -> Result
public typealias AsyncThrowingExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async throws -> Result
```

---

## 🚀 Getting Started

Here’s a practical example: creating an asynchronous network request using Swift Concurrency.

```swift
import SwiftUseCase

public enum Network {
    @Usecase
    private var dataTask(request: URLRequest, session: URLSession) async throws -> (response: HTTPURLResponse, data: Data) {
        class CancellableWrapper {
            var dataTask: URLSessionDataTask?
        }
        let wrapper = CancellableWrapper()
        return try await withTaskCancellationHandler {
            try await withUnsafeThrowingContinuation { continuation in
                wrapper.dataTask = session.dataTask(with: request) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let data = data, let response = response as? HTTPURLResponse else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                        return
                    }
                    continuation.resume(returning: (response, data))
                }
                wrapper.dataTask?.resume()
            }
        } onCancel: {
            wrapper.dataTask?.cancel()
        }
    }
}
```

---

## 🧬 Simplifying Usage

Creating parameters manually for each call can get verbose.  
You can make things cleaner with small helper extensions:

```swift
extension Network.DataTask.Parameter {
    static func get(_ path: String, session: URLSession? = nil) -> Self {
        .init(
            request: URLRequest(url: URL(string: path)!),
            session: session ?? .shared
        )
    }
}
```

Now your code reads beautifully and stays consistent across use cases:

```swift
// Combine
Network.dataTask
    .publisher(.get("https://api.coincap.io/v2/assets"))
    .sink(receiveCompletion: { print($0) },
          receiveValue: { print($1) })

// Callback
Network.dataTask(.get("https://api.coincap.io/v2/assets")) { result in
    print(result)
}

// Swift Concurrency
let result = try await Network.dataTask(.get("https://api.coincap.io/v2/assets"))
```

---

## 🧱 Type Erasure

Every `UseCase` can be converted into an `AnyUseCase` — a type-erased form that lets you store and execute heterogeneous use cases uniformly.

```swift
let usecase = MyUseCase().eraseToAnyUseCase
usecase.onComplete = { print("Result: \($0)") }
usecase.onFailure = { print("Error: \($0)") }
usecase(parameter)
```

This is particularly useful when you want to keep a collection of different use cases or pass them through dependency injection containers without generic constraints.

---

## ❤️ Sponsors

SwiftUseCase is an open-source project licensed under MIT.  
Its ongoing development is made possible by contributors and sponsors who believe in clean, testable architecture for Swift apps.  
If you find it helpful, please consider **supporting** its continued growth.

---

## 🤝 Contributing

Contributions are very welcome.  
Please open an issue before submitting major changes and ensure all new features include proper tests and documentation updates.

---

## 📄 License

SwiftUseCase is available under the [MIT License](https://choosealicense.com/licenses/mit/).  
See `LICENSE` for full details.

