# Suggested Commands

## Swift (UICBarcodeKit)

All Swift commands must be run from the `UICBarcodeKit/` directory.

```bash
# Build
cd UICBarcodeKit && swift build

# Run all tests (315 tests)
cd UICBarcodeKit && swift test

# Run a single test class
cd UICBarcodeKit && swift test --filter SSBFrameTests

# Run a single test method
cd UICBarcodeKit && swift test --filter SSBFrameTests/testNRTAlphaNumericDecoding

# Clean build artifacts (useful after directory renames)
cd UICBarcodeKit && swift package clean

# Resolve dependencies
cd UICBarcodeKit && swift package resolve
```

## Java (Reference Implementation)

```bash
# Build and test
mvn test

# Package
mvn package

# Run a single test class
mvn test -Dtest=DynamicFrameDoubleSignatureTest
```

## System Utilities (macOS / Darwin)

```bash
git status
git diff
git log --oneline -10
```
