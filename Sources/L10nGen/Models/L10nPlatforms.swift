enum L10nPlatforms: String {
    case android = "__Android"
    case backend = "__Backend"
    case web = "__Web"
    case iOS = "__iOS"

    static let unsupported: [L10nPlatforms] = [.android, .backend, .web]
}
