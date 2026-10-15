# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repo contains **two implementations** of the UIC railway barcode specification (IRS 90918-9):

1. **Java reference implementation** (`src/`) - the upstream library from UIC
2. **Swift port** (`UICBarcodeKit/`) - a Swift Package Manager library ported from the Java reference

The Swift implementation must stay aligned with the Java reference. When modifying the Swift code, always verify behavior against the corresponding Java source.

## Build & Test Commands

### Swift (UICBarcodeKit)
```bash
# Run all tests (must be run from UICBarcodeKit directory)
cd UICBarcodeKit && swift test

# Run a single test class
cd UICBarcodeKit && swift test --filter SSBFrameTests

# Run a single test method
cd UICBarcodeKit && swift test --filter SSBFrameTests/testNRTAlphaNumericDecoding

# Build only (no tests)
cd UICBarcodeKit && swift build
```

### Java (reference implementation)
```bash
mvn test
mvn package
```

## Architecture

### Swift Package Structure (`UICBarcodeKit/`)

- **`UICBarcode.swift`** - Public API entry point. `UICBarcodeDecoder` is the main struct consumers use. Also contains convenience extensions on `DecodedBarcode`.
- **`UICBarcodeEncoder.swift`** - Top-level encoder for creating UIC barcodes.
- **`ASN1/`** - `UPERDecoder`/`UPEREncoder` (ASN.1 Unaligned PER codec), `ASN1Decodable`/`ASN1Encodable` protocols
- **`Core/`** - `BarcodeDecoder` (internal decoder that auto-detects frame type), `BitBuffer` (bit-level read/write), `Constants`, `Errors`, `Compression`, `DataExtensions`
- **`DynamicFrame/`** - DOSIPAS U1/U2 format, decodes/encodes Level1Data/Level2Data via UPER
- **`DynamicContent/`** - Dynamic content data (FDC1) and timestamp utilities
- **`StaticFrame/`** - `#UT` header format (v1/v2), parses U_HEAD/U_TLAY/U_FLEX data records
- **`SSBFrame/`** - 114-byte fixed-length Small Structured Barcode
- **`Ticket/`** - Ticket data models and API abstraction layer (mirrors Java `ticket/` package):
  - `FCBVersionDecoder.swift` / `FCBVersionEncoder.swift` - Version-specific FCB codec dispatch
  - `UicRailTicketCoder.swift` - High-level ticket encode/decode API
  - `API/ASN/OMV1/` - FCB v1 ASN.1 data model (Common/ + Tickets/)
  - `API/ASN/OMV2/` - FCB v2 ASN.1 data model (Common/ + Tickets/)
  - `API/ASN/OMV3/` - FCB v3 ASN.1 data model (Common/ + Tickets/)
  - `API/Spec/` - Version-independent ticket API protocols and types
  - `API/Impl/` - Concrete API implementations (SimpleTicket)
  - `API/Utils/` - ASN-to-API converters, API-to-ASN encoders, DateTimeUtils
- **`Utils/`** - Cryptographic utilities: `SignatureVerifier`, `SignatureSigner`, `DERParser`, `DSAVerifier`, `AlgorithmResolver`, `BigUInt`

### Java Reference Structure (`src/`)

- `src/main/java/org/uic/barcode/ticket/` - Ticket types with ASN.1 annotations
- `src/main/java/org/uic/barcode/dynamicFrame/` - Dynamic frame (DOSIPAS)
- `src/main/java/org/uic/barcode/staticFrame/` - Static frame
- `src/main/java/org/uic/barcode/ssbFrame/` - SSB frame
- `src/main/java/org/uic/barcode/asn1/` - ASN.1 UPER codec with annotation-driven encoding

### ASN.1 Schemas

`misc/` contains the ASN.1 schema files. The primary ones for the current implementation:
- `uicRailTicketData_v3.0.5.asn` - FCB v3 ticket data
- `uicBarcodeHeader_v2.0.1.asn` - Dynamic frame header
- `uicDynamicContentData_v1.0.5.asn` - Dynamic content (FDC1)

## Critical Implementation Rules for the Swift Port

### ASN.1 UPER Encoding
- **Mandatory fields** do NOT get presence bits in SEQUENCE encoding
- **OPTIONAL and @Asn1Default fields** both get presence bits (Java `isOptional()` returns true for both)
- **@Asn1Default fields**: when presence bit is 0, assign the default value in an `else` branch. **@Asn1Optional fields**: when presence bit is 0, leave as nil (no else branch).
- **Extension markers**: only add extension bit read at SEQUENCE start when Java has `@HasExtensionMarker` AND ASN.1 has `...`
- Presence bitmap count = number of OPTIONAL + @Asn1Default fields only

### Naming Convention
Swift field names must match Java field names exactly, including known Java typos (e.g., `bordingOrArrival`, `preferedLanguage`). The only exception is Swift's `extension` keyword conflict, where the field is named `extensionData`.

### SSB Frame Decoding
- `alphaNumeric` is a 1-bit flag read first (not a code table value)
- If alphanumeric: 30+30 bit char6 strings for stations, no code table
- If numeric: 4-bit code table + 28+28 bit station numbers

### Constraints
- `productIdNum`: always constrained 0..65535
- Station numbers: always constrained 1..9999999
- `IA5String` with `@SizeRange` passes constraint to decoder for bit-efficient length encoding
