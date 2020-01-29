import Files
import Foundation

final class Templates {
    lazy var l10n: String = {
        """
        import Foundation

        // swiftlint:disable all

        public final class L10n {
        {Content}
        }
        """
    }()

    lazy var keys: String = {
        """
        import Foundation

        // swiftlint:disable all

        public enum {Name:Type} {
        {Cases}
        }
        """
    }()

    lazy var basic: String = {
        """
            public static var {Key}: String {
                return self.value(for: L10nKeys.{Key})
            }
        """
    }()

    lazy var plural: String = {
        """
            public static func {Key}<T: SignedInteger>(withPlural plural: T?, options: [L10nPluralOption] = L10nPluralOption.allCases) -> String {
                return self.value(for: L10nKeys.{Key}, plural: plural, options: options)
            }
        """
    }()

    lazy var param: String = {
        """
            public static func {Key}({ArgInputs}) -> String {
                return self.value(for: L10nKeys.{Key}, args: {Args})
            }
        """
    }()

    lazy var pluralParam: String = {
        """
            public static func {Key}<T: SignedInteger>(withPlural plural: T?, {ArgInputs}, options: [L10nPluralOption] = L10nPluralOption.allCases) -> String {
                return self.value(for: L10nKeys.{Key}, args: {Args}, plural: plural, options: options)
            }
        """
    }()

    lazy var paramAttr: String = {
        """
            public static func {Key}({ArgInputs}) -> L10nAttributed {
                return L10nAttributed.from(key: L10nKeys.{Key}, args: {Args})
            }
        """
    }()

    lazy var pluralParamAttr: String = {
        """
            public static func {Key}<T: SignedInteger>(withPlural plural: T?, {ArgInputs}, options: [L10nPluralOption] = L10nPluralOption.allCases) -> L10nAttributed {
                return L10nAttributed.from(key: L10nKeys.{Key}, args: {Args}, plural: plural, options: options)
            }
        """
    }()
}
