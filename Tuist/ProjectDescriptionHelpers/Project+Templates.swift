import ProjectDescription

/// Project helpers are functions that simplify the way you define your project.
/// Share code to create targets, settings, dependencies,
/// Create your own conventions, e.g: a func that makes sure all shared targets are "static frameworks"
/// See https://docs.tuist.io/guides/helpers/

extension Project {
    /// Helper function to create the Project for this ExampleApp
    public static func app(name: String, platforms: [Platform], additionalTargets: [String], externalDependencies: [String]) -> Project {
        var targets = makeAppTargets(
            name: name,
            platforms: platforms,
            targetDependencies: additionalTargets,
            otherDependencies: externalDependencies.map { name in .external(name: name) }
        )
        targets += platforms.flatMap { platform in
            additionalTargets.flatMap { name in
                makeFrameworkTargets(name: name, platform: platform)
            }
        }
        return Project(name: name,
                       organizationName: Constants.organisationName,
                       targets: targets)
    }

    // MARK: - Private

    /// Helper function to create a framework target and an associated unit test target
    private static func makeFrameworkTargets(name: String, platform: Platform) -> [Target] {
        let nameWithPlatform = "\(name)_\(platform.rawValue)"
        let sources = Target(name: nameWithPlatform,
                platform: platform,
                product: .framework,
                bundleId: "\(Constants.bundlePrefix).\(name)",
                infoPlist: .default,
                sources: ["Targets/\(name)/Sources/**"],
                resources: [],
                dependencies: [])
        let tests = Target(name: "\(name)Tests_\(platform.rawValue)",
                platform: platform,
                product: .unitTests,
                bundleId: "\(Constants.bundlePrefix).\(name)Tests",
                infoPlist: .default,
                sources: ["Targets/\(name)/Tests/**"],
                resources: [],
                dependencies: [.target(name: nameWithPlatform)])
        return [sources, tests]
    }

    /// Helper function to create the application target and the unit test target.
    private static func makeAppTargets(
        name: String,
        platforms: [Platform],
        targetDependencies: [String],
        otherDependencies: [TargetDependency]
    ) -> [Target] {
        var targets: [Target] = []
        for platform in platforms {
            let nameWithPlatform = "\(name)_\(platform.rawValue)"
            let infoPlist: [String: InfoPlist.Value]
            let secretsPlistPart = SecretKeys.allCases.map(\.rawValue).reduce( [String: InfoPlist.Value]()) { dict, key in
                var dict = dict
                dict[key] = "$(\(key)"
                return dict
            }
            
            switch platform {
            case .iOS:
                infoPlist = [
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "CFBundleURLTypes": [
                        [
                            "CFBundleTypeRole": "Editor",
                            "CFBundleURLSchemes": ["personal-site-app"]
                        ]
                    ],
                    "UIMainStoryboardFile": "",
                    "UILaunchStoryboardName": "LaunchScreen"
                ].merging(secretsPlistPart) { first, _ in first }
                
            case .macOS:
                infoPlist = [
                    "CFBundleShortVersionString": "1.0",
                    "CFBundleVersion": "1",
                    "NSMainStoryboardFile": "",
                    "UILaunchStoryboardName": "LaunchScreen"
                ].merging(secretsPlistPart) { first, _ in first }
            
            default:
                fatalError("plist not provided for \(platform.rawValue)")
            }
            
            let mainTarget = Target(
                name: nameWithPlatform,
                platform: platform,
                product: .app,
                bundleId: "\(Constants.bundlePrefix).\(name)",
                infoPlist: .extendingDefault(with: infoPlist),
                sources: ["Targets/\(name)/Sources/**"],
                resources: ["Targets/\(name)/Resources/**"],
                dependencies: otherDependencies
                + targetDependencies.map { name in .target(name: name + "_\(platform.rawValue)") }, settings: .settings(configurations: [ .debug(name: .debug, xcconfig: "secrets.xcconfig") ])
            )
            
            targets.append(mainTarget)

            let testTarget = Target(
                name: "\(name)Tests_\(platform.rawValue)",
                platform: platform,
                product: .unitTests,
                bundleId: "\(Constants.bundlePrefix).\(name)Tests",
                infoPlist: .default,
                sources: ["Targets/\(name)/Tests/**"],
                dependencies: [
                    .target(name: nameWithPlatform)
            ])
            
            targets.append(testTarget)
        }
        return targets
    }
}
