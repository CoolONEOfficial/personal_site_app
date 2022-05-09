import ProjectDescription

struct Constants {
    static let organisationComponents: [String] = ["coolone", "ru"]
    
    static var organisationName: String { organisationComponents.joined(separator: ".") }
    static var bundlePrefix: String { organisationComponents.reversed().joined(separator: ".") }
}
