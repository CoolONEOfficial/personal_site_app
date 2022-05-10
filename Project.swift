import ProjectDescription
import ProjectDescriptionHelpers

/*
                +-------------+
                |             |
                |     App     | Contains PersonalSiteApp App target and PersonalSiteApp unit-test target
                |             |
         +------+-------------+-------+
         |         depends on         |
         |                            |
 +----v-----+                   +-----v-----+
 |          |                   |           |
 |   Kit    |                   |     UI    |   Two independent frameworks to share code and start modularising your app
 |          |                   |           |
 +----------+                   +-----------+

 */

// MARK: - Project

// Creates our project using a helper function defined in ProjectDescriptionHelpers
let project = Project.app(
    name: "PersonalSiteApp",
    platforms: [ targetPlatform() ], //[.macOS, .iOS], TODO: multiplatform
    additionalTargets: ["PersonalSiteAppKit", "PersonalSiteAppUI"],
    externalDependencies: [
        "Kingfisher",
        "Alamofire",
        "Zip",
        "Introspect",
        "HighlightedTextEditor",
        "Ink",
        "PortfolioSite",
        "Telegraph",
        "OAuthSwift",
        "KeychainSwift",
    ]
)
