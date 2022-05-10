# Personal site app

## Get started

Add secrets.xcconfig at root of the project with:

```
CONSUMER_SECRET=<key>
```

1) `tuist fetch`
2) `tuist generate`

## How to switch between iOS and macOS versions of app?

Unfortunately tuist doesn't support multiplatform targets or dependencies (via SPM as I know) so use that command to switch to macOS or iOS:

### Switch to macos:
 `export TUIST_PLATFORM=macOS`
 `tuist clean && tuist fetch && tuist generate`

### Switch to iOS:
 `export TUIST_PLATFORM=iOS` (optional because iOS is default)
 `tuist clean && tuist fetch && tuist generate`
