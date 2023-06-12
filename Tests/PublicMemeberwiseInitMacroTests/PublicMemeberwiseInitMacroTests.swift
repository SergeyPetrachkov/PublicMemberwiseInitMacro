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

    func testLazyPropsAreTreatedProperly() {
        assertMacroExpansion(
            """
            @publicMemberwiseInit
            class Sample {
                lazy var x: Int = 1
                let y: Double
            }
            """,
            expandedSource:
            """

            class Sample {
                lazy var x: Int = 1
                let y: Double
                public init(y: Double) {
                    self.y = y
                }
            }
            """,
            macros: testMacros
        )
    }

    func testLetPropertiesWithValuesAreTreatedCorrectly() {
        assertMacroExpansion(
            """
            @publicMemberwiseInit
            class Sample {
                let y: Double = 0
            }
            """,
            expandedSource:
            """

            class Sample {
                let y: Double = 0
                public init() {
                }
            }
            """,
            macros: testMacros
        )
    }
}
