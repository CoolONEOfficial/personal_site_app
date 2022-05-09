import ProjectDescription

func targetPlatform() -> Platform {
    switch Environment.platform.getString(default: "none") {
    case "iOS":
        return .iOS
        
    case "macOS":
        return .macOS
        
    case "none":
        debugPrint("WARNING: platform not handled, fallback to iOS")
        return .iOS
        
    default:
        fatalError()
    }
}

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(url: "https://github.com/Alamofire/Alamofire", requirement: .upToNextMajor(from: "5.0.0")),
        .remote(url: "https://github.com/siteline/SwiftUI-Introspect", requirement: .branch("master")),
        .remote(url: "https://github.com/kyle-n/HighlightedTextEditor", requirement: .upToNextMajor(from: "2.0.0")),
        .remote(url: "https://github.com/JohnSundell/Ink", requirement: .upToNextMajor(from: "0.5.1")),
        .remote(url: "https://github.com/marmelroy/Zip", requirement: .upToNextMajor(from: "2.0.0")),
        .remote(url: "https://github.com/onevcat/Kingfisher", requirement: .upToNextMajor(from: "7.0.0")),
        .remote(url: "https://github.com/CoolONEOfficial/personal_site", requirement: .branch("mobile")),
        .remote(url: "https://github.com/Building42/Telegraph.git", requirement: .upToNextMajor(from: "0.29")),
    ],
    platforms: [ targetPlatform() ] // TODO: multiplatform
)


