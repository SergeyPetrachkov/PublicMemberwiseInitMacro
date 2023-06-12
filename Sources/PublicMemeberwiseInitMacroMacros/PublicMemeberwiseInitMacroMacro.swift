import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PublicMemberwiseInitMacro: MemberMacro {

    enum Errors: Swift.Error, CustomStringConvertible {
        case invalidInputType

        var description: String {
            "@PublicMemberwiseInitMacro is only applicable to structs or classes"
        }
    }

    public static func expansion(
        of attribute: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let storedProperties: [VariableDeclSyntax] = try {
            if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
                return classDeclaration.storedProperties()
            } else if let structDeclaration = declaration.as(StructDeclSyntax.self) {
                return structDeclaration.storedProperties()
            } else {
                throw Errors.invalidInputType
            }
        }()

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

        let initDeclSyntax = try InitializerDeclSyntax(
            PartialSyntaxNodeString(stringLiteral: "public init(\(initArguments.map { "\($0.name): \($0.type)" }.joined(separator: ", ")))"),
            bodyBuilder: {
                initBody
            }
        )

        let finalDeclaration = DeclSyntax(initDeclSyntax)

        return [finalDeclaration]
    }
}

extension VariableDeclSyntax {
    /// Check if this variable has the syntax of a stored property.
    var isStoredProperty: Bool {
        guard let binding = bindings.first,
              bindings.count == 1,
              !isLazyProperty,
              !isConstant else {
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

    var isLazyProperty: Bool {
        modifiers?.contains { $0.name.tokenKind == .keyword(Keyword.lazy) } ?? false
    }

    var isConstant: Bool {
        bindingKeyword.tokenKind == .keyword(Keyword.let) && bindings.first?.initializer != nil
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
