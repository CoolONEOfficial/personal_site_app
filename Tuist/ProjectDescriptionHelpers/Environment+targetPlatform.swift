import ProjectDescription

public func targetPlatform() -> Platform {
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
