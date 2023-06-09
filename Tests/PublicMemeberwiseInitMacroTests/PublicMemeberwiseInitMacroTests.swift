import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import PublicMemeberwiseInitMacroMacros

let testMacros: [String: Macro.Type] = [
    "publicMemberwiseInit": PublicMemberwiseInitMacro.self
]

final class PublicMemeberwiseInitMacroTests: XCTestCase {
    func testMacroForClass() {
        assertMacroExpansion(
            """
            @publicMemberwiseInit
            class Sample {
                var x: Int
                let y: Double

                var myComputedProperty: String {
                    "hello world"
                }

                private var _something: Bool

                var something: Bool {
                    get {
                        return _something
                    }
                    set {
                        _something = newValue
                    }
                }

                func sayHi() {

                }

                func sayBye() { }
            }
            """,
            expandedSource:
            """

            class Sample {
                var x: Int
                let y: Double

                var myComputedProperty: String {
                    "hello world"
                }

                private var _something: Bool

                var something: Bool {
                    get {
                        return _something
                    }
                    set {
                        _something = newValue
                    }
                }

                func sayHi() {

                }

                func sayBye() {
                }
                public init(x: Int, y: Double, _something: Bool) {
                    self.x = x
                    self.y = y
                    self._something = _something
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMacroForStruct() {
        assertMacroExpansion(
            """
            @publicMemberwiseInit
            struct Sample {
                var x: Int
                let y: Double

                var myComputedProperty: String {
                    "hello world"
                }

                private var _something: Bool

                var something: Bool {
                    get {
                        return _something
                    }
                    set {
                        _something = newValue
                    }
                }

                func sayHi() {

                }

                func sayBye() { }
            }
            """,
            expandedSource:
            """

            struct Sample {
                var x: Int
                let y: Double

                var myComputedProperty: String {
                    "hello world"
                }

                private var _something: Bool

                var something: Bool {
                    get {
                        return _something
                    }
                    set {
                        _something = newValue
                    }
                }

                func sayHi() {

                }

                func sayBye() {
                }
                public init(x: Int, y: Double, _something: Bool) {
                    self.x = x
                    self.y = y
                    self._something = _something
                }
            }
            """,
            macros: testMacros
        )
    }
}
