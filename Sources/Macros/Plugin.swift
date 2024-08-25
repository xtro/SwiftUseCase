import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftUseCaseMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [UsecaseMacro.self]
}
