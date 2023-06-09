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

        let storedProperties = declaration.as(ClassDeclSyntax.self)?.storedProperties()
        ?? declaration.as(StructDeclSyntax.self)?.storedProperties()

        guard let storedProperties = storedProperties else {
            return []
        }

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
            PartialSyntaxNodeString(stringLiteral: "public init(\(initArguments.map { "\($0.name): \($0.type)" }.joined(separator: ", ")))"),
            bodyBuilder: {
                initBody
            }
        ),
              let finalDeclaration = DeclSyntax(initDeclSyntax) else {
            return []
        }
        return [finalDeclaration]
    }
}

extension VariableDeclSyntax {
    /// Check if this variable has the syntax of a stored property.
    var isStoredProperty: Bool {
        guard let binding = bindings.first, bindings.count == 1 else {
            return false
        }

        switch binding.accessor {
        case .none:
            return true
        case .accessors(let node):
            // traverse accessors
            for accessor in node.accessors {
                switch accessor.accessorKind.tokenKind {
                case .keyword(.willSet), .keyword(.didSet):
                    // stored properties can have observers
                    break
                default:
                    // everything else makes it a computed property
                    return false
                }
            }
            return true
        case .getter:
            return false
        }
    }
}

extension DeclGroupSyntax {
    /// Get the stored properties from the declaration based on syntax.
    func storedProperties() -> [VariableDeclSyntax] {
        return memberBlock.members.compactMap { member in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  variable.isStoredProperty else {
                return nil
            }

            return variable
        }
    }
}

@main
struct PublicMemeberwiseInitMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PublicMemberwiseInitMacro.self,
    ]
}
