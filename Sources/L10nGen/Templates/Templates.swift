import Files
import Foundation

final class Templates {
    lazy var l10n: String = {
        """
        import Foundation

        // swiftformat:disable all
        // swiftlint:disable all

        public final class L10n {
            public typealias PluralNumberArg = SignedNumeric & CVarArg
        }

        {Content}
        """
    }()

    lazy var feature: String = {
        """
        extension L10n {
            public final class {Key} {
        {Content}
            }
        }
        """
    }()

    lazy var l10nKeys: String = {
        """
        import Foundation

        // swiftformat:disable all
        // swiftlint:disable all

        internal protocol L10nKey {
            var stringValue: String  { get }
        }

        extension RawRepresentable where Self: L10nKey, Self.RawValue == String {
            var stringValue: String { rawValue }
        }

        internal final class L10nKeys { }

        {Content}
        """
    }()

    lazy var featureKeys: String = {
        """
        extension L10nKeys {
            enum {Name}: String, L10nKey {
        {Cases}
            }
        }
        """
    }()

    lazy var basic: String = {
        """
                /// {Value}
                public static var {Key}: String {
                    return L10n.value(for: L10nKeys.{EnumKey})
                }
        """
    }()

    lazy var plural: String = {
        """
                /**
                 {Value}
                */
                public static func {Key}<T: PluralNumberArg>(withPlural plural: T?) -> String {
                    return L10n.value(for: L10nKeys.{EnumKey}, plural: plural)
                }
        """
    }()

    lazy var param: String = {
        """
                /**
                 {Value}
                */
                public static func {Key}({ArgInputs}) -> String {
                    return L10n.value(for: L10nKeys.{EnumKey}, args: {Args})
                }
        """
    }()

    lazy var pluralParam: String = {
        """
                /**
                 {Value}
                */
                public static func {Key}<T: PluralNumberArg>(withPlural plural: T?, {ArgInputs}) -> String {
                    return L10n.value(for: L10nKeys.{EnumKey}, args: {Args}, plural: plural)
                }
        """
    }()

    lazy var paramAttr: String = {
        """
                /**
                 {Value}
                */
                public static func {Key}({ArgInputs}) -> L10nAttributed {
                    return L10nAttributed.from(key: L10nKeys.{EnumKey}, args: {Args})
                }
        """
    }()

    lazy var pluralParamAttr: String = {
        """
                /**
                 {Value}
                */
                public static func {Key}<T: PluralNumberArg>(withPlural plural: T?, {ArgInputs}) -> L10nAttributed {
                    return L10nAttributed.from(key: L10nKeys.{EnumKey}, args: {Args}, plural: plural)
                }
        """
    }()
}
