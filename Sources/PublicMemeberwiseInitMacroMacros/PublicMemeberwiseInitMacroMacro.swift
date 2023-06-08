import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PublicMemberwiseInitMacro: MemberMacro {
    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            return []
        }
        let storedProperties = classDeclaration
            .memberBlock
            .members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.bindings.first?.accessor == nil }

        let initArguments = storedProperties.compactMap { property -> (name: String, type: String)? in
            guard let patternBinding = property.bindings.first?.as(PatternBindingSyntax.self) else {
                return nil
            }

            guard let name = patternBinding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
                  let type = patternBinding.typeAnnotation?.as(TypeAnnotationSyntax.self)?.type.as(SimpleTypeIdentifierSyntax.self)?.name else {
                return nil
            }

            return (name: name.text, type: type.text)
        }

        let initBody: ExprSyntax = "\(raw: initArguments.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))"

        guard let initDeclSyntax = try? InitializerDeclSyntax(
            PartialSyntaxNodeString(stringLiteral: "init(\(initArguments.map { "\($0.name): \($0.type)" }.joined(separator: ", ")))"),
            bodyBuilder: {
                initBody
            }
        ),
              let finalDeclaration = DeclSyntax(initDeclSyntax)
        else {
            return []
        }
        return [finalDeclaration]
    }
}

@main
struct PublicMemeberwiseInitMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PublicMemberwiseInitMacro.self,
    ]
}
