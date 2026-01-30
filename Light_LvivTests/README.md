# Test Infrastructure Setup

## Status: Test Files Created ✅

Test files are ready in `Light_LvivTests/` directory:
- `ExampleTest.swift` - Placeholder test to verify infrastructure

## Next Step: Add Test Target in Xcode

To complete the test infrastructure setup:

1. Open `Light_Lviv.xcodeproj` in Xcode
2. Select the project in Navigator (top level)
3. Click '+' under Targets
4. Select 'iOS Unit Testing Bundle'
5. Name it: `Light_LvivTests`
6. Set Target to be Tested: `Light_Lviv`
7. Click Finish

## After Adding Target

The test target will be automatically configured to:
- Run tests with Cmd+U
- Include all files in `Light_LvivTests/` directory
- Link against the main app target

## Verification

Run tests in Xcode:
```
Cmd+U
```

Or via command line:
```bash
xcodebuild -project Light_Lviv.xcodeproj -scheme Light_LvivTests -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Note

The test infrastructure is partially complete. The test files exist and are ready.
The test target needs to be added via Xcode UI to complete the setup.
