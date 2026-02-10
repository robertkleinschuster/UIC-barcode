# Task Completion Checklist

When a code modification task is completed, perform the following:

1. **Run Swift tests**: `cd UICBarcodeKit && swift test`
   - All 315 tests must pass with 0 failures
   - If build cache causes issues after renames, run `swift package clean` first

2. **Verify Java alignment** (if modifying Swift decoding logic):
   - Check the corresponding Java source in `src/main/java/org/uic/barcode/`
   - Verify field optionality (@Asn1Optional vs @Asn1Default) matches
   - Verify constraints match
   - Verify extension markers match

3. **Update tests**: If field names or decoding behavior changed, update all test files in `UICBarcodeKit/Tests/UICBarcodeKitTests/`
