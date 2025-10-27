import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A Swift macro that generates use case boilerplate code for functions.
///
/// This macro analyzes a function declaration and automatically generates
/// a corresponding use case struct conforming to a specific protocol
/// based on the function's signature. It creates a `Parameter` typealias or
/// struct depending on the function's parameters, defines the `Result` typealias,
/// and provides an `execute` property with the appropriate executable type.
/// 
/// Use this macro to reduce repetitive use case code and improve consistency.
///
/// ```swift
/// @UsecaseMacro
/// func fetchUser(id: Int) async throws -> User { ... }
/// ```
/// Generates:
/// ```swift
/// struct FetchUserUsecase: AsyncThrowingUseCase {
///     public typealias Parameter = Int
///     public typealias Result = User
///
///     public let execute: AsyncThrowingExecutable<Parameter, Result> = { _ in
///          let id = $0.id
///          ...
///     }
/// }
/// ```
///
/// Example with multiple input parameters:
/// ```swift
/// @UsecaseMacro
/// func updateProfile(id: Int, name: String, age: Int) async throws -> User { ... }
/// ```
/// Generates:
/// ```swift
/// struct UpdateProfileUsecase: AsyncThrowingUseCase {
///     public struct Parameter {
///         public let id: Int
///         public let name: String
///         public let age: Int
///
///         public init(id: Int, name: String, age: Int) {
///             self.id = id
///             self.name = name
///             self.age = age
///         }
///     }
///     public typealias Result = User
///
///     public let execute: AsyncThrowingExecutable<Parameter, Result> = {
///         let id = $0.id
///         let name = $0.name
///         let age = $0.age
///         // ...
///     }
/// }
/// ```
public struct UsecaseMacro {}

extension UsecaseMacro: PeerMacro {
    /// Expands the `@UsecaseMacro` attribute on a function by generating
    /// a corresponding use case struct with properly typed `Parameter` and `Result`
    /// typealiases or structs, plus an `execute` property that wraps the function's
    /// body in an executable closure.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node representing this macro invocation.
    ///   - declaration: The function declaration to which the macro is applied.
    ///   - context: The macro expansion context.
    ///
    /// - Returns: An array of declarations representing the generated use case struct
    ///   and a static instance of it.
    public static func expansion(of node: AttributeSyntax,
                                 providingPeersOf declaration: some DeclSyntaxProtocol,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let function = declaration.as(FunctionDeclSyntax.self)!
        let parameters = function.signature.parameterClause.parameters.map {
            Variable(
                name: $0.firstName.text,
                type: "\($0.type.trimmedDescription)",
                default: $0.defaultValue?.trimmedDescription,
                modifier: $0.attributes.isEmpty ? nil : $0.attributes.trimmedDescription
            )
        }
        let hasParameter = !parameters.isEmpty
        func makeParameterTypeDefinition(from parameters: [Variable]) -> String {
            if parameters.isEmpty {
                return """
                public typealias Parameter = Void
                """
            } else if parameters.count == 1 {
                return """
                public typealias Parameter = \(parameters.first!.type)
                """
            } else {
                return makeParameterStruct(from: parameters)
            }
        }
        
        let isAsync = function.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrows = function.signature.effectSpecifiers?.throwsSpecifier != nil
        let returnType = function.signature.returnClause?.type.trimmedDescription ?? "Void"
        let originalName = "\(function.name.text)"
        let name = originalName.capitalizedFirstLetter
        let usecaseName: String = "\(name)Usecase"
        let usecaseType: String = "\(isAsync ? "Async":"")\(isThrows ? "Throwing":"")UseCase"
        let executableName: String = "\(isAsync ? "Async":"")\(isThrows ? "Throwing":"")Executable"
        
        return ["""
        public struct \(raw: usecaseName): \(raw: usecaseType) {
            \(raw: makeParameterTypeDefinition(from: parameters))
            public typealias Result = \(raw: returnType)
        
            public let execute: \(raw: executableName)<Parameter, Result> = { \(raw: hasParameter ? "" : "_ in")
                \(raw: parameters.render(mode: .equal(prefix:"let ", right: "$0", equalation: " = "), separator: .newline))
        
                // Original code:\(raw: function.body!.statements.description)
            }
        }
        public static let \(raw: originalName) = \(raw: name)Usecase()
        """]
    }
    
    // MARK: - Helper for Parameter Struct
    
    private static func makeParameterStruct(from parameters: [Variable]) -> String {
        """
        public struct Parameter {
            \(parameters.render(mode: .parameter(.list)))
        
            public init(\(parameters.render(mode: .parameter(.parameter), separator: .coma))) {
                \(parameters.render(mode: .equal(left: "self")))
            }
        }
        """
    }
}

typealias Variable = (name: String, type: String, default: String?, modifier: String?)

fileprivate extension String {
    var capitalizedFirstLetter: String {
        prefix(1).capitalized + dropFirst()
    }
}

fileprivate extension Array where Element == Variable {
    enum Modifiable: String {
        case constant = "let"
        case variable = "var"
    }
    enum Mode {
        case equal(prefix: String? = nil, left: String? = nil, right: String? = nil, equalation: String = " = ", handleCount: Bool = true)
        case parameter(ParameterMode)
    }
    enum ParameterMode {
        case list
        case parameter
    }
    func render(mode: Mode, separator: String = .newline) -> String {
        map {
            switch mode {
            case .equal(let prefix, let left, let right, let equalation, let handleCount):
                if self.count > 1 || !handleCount {
                    "\(prefix.defaultValue(""))\(left.withPeriod)\($0.name)\(equalation)\(right.withPeriod)\($0.name)"
                } else {
                    "\(prefix.defaultValue(""))\(left.withPeriod)\($0.name)\(equalation)\(right.map())"
                }
            case .parameter(let mode):
                switch mode {
                case .list:
                    "\($0.modifier.defaultValue("let") {"\($0) var"}) \($0.name): \($0.type)"
                case .parameter:
                    "\($0.name): \($0.type)\($0.default.defaultValue(""){ " \($0)" })"
                }
            }
        }.joined(separator: separator)
    }
}
fileprivate extension String {
    static let newline = "\n"
    static let coma = ", "
}

fileprivate extension Optional where Wrapped == String {
    var withPeriod: String {
        map(postfix: ".")
    }
    func map(prefix: String = "", postfix: String = "") -> String {
        switch self {
        case .some(let value):
            prefix+value+postfix
        default:
            ""
        }
    }
}

fileprivate extension Optional {
    func defaultValue(_ value: Wrapped) -> Wrapped {
        switch self {
        case .some(let value):
            value
        default:
            value
        }
    }
    func defaultValue(_ value: Wrapped, map: (Wrapped) -> Wrapped) -> Wrapped {
        switch self {
        case .some(let value):
            map(value)
        default:
            value
        }
    }
}

