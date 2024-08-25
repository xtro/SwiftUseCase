import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UsecaseMacro {}
extension UsecaseMacro: PeerMacro {
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
        let parameterText: String
        let hasParameter = !parameters.isEmpty
        let hasManyParameters = parameters.count > 1
        if !hasParameter {
            parameterText = """
            public typealias Parameter = Void
            """
        } else if !hasManyParameters {
            parameterText = """
            public typealias Parameter = \(parameters.first!.type)
            """
        } else {
            parameterText = """
            public struct Parameter {
                \(parameters.render(mode: .parameter(.list)))
            
                public init(\(parameters.render(mode: .parameter(.parameter), separator: .coma))) {
                    \(parameters.render(mode: .equal(left: "self")))
                }
            }
            """
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
            \(raw: parameterText)
            public typealias Result = \(raw: returnType)
        
            public let execute: \(raw: executableName)<Parameter, Result> = { \(raw: hasParameter ? "" : "_ in")
                \(raw: parameters.render(mode: .equal(prefix:"let ", right: "$0", equalation: " = "), separator: .newline))
        
                // Original code:\(raw: function.body!.statements.description)
            }
        }
        public static let \(raw: originalName) = \(raw: name)Usecase()
        """]
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
