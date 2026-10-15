# Code Style and Conventions

## Swift

### General Style
- Public structs for data models (not classes)
- Public enum with associated values for errors (`UICBarcodeError`)
- `MARK: -` comments to organize sections
- Properties are `public var` with optional types for ASN.1 optional/default fields
- No external dependencies - only Foundation and CryptoKit

### Naming
- Swift field names match Java field names exactly, including known Java typos:
  - `bordingOrArrival` (not `boardingOrArrival`)
  - `preferedLanguage` (not `preferredLanguage`)
  - `traveler` (not `travelers`)
- Exception: Swift `extension` keyword conflict → use `extensionData`
- Enum cases use camelCase: `TravelClassType.first`, `CodeTableType.stationUIC`
- Struct names match Java class names: `ReservationData`, `OpenTicketData`, `PassData`

### ASN.1 Decoding Pattern
Each struct conforming to `ASN1Decodable` implements `init(from decoder: inout UPERDecoder)` with:
1. Read extension bit (if `@HasExtensionMarker`)
2. Read presence bitmap for optional + default fields
3. Decode fields in order: mandatory fields inline, optional/default fields gated by presence bits
4. `@Asn1Default` fields get default value in `else` branch; `@Asn1Optional` fields stay nil

### File Organization
- `CommonTypes.swift` - All shared enums and small struct types
- `TicketTypes.swift` - All ticket document types (~2000 lines, single file matching Java package structure)
- `UicRailTicketData.swift` - Top-level container types (UicRailTicketData, IssuingData, TravelerData, etc.)

## Java
- Standard Java conventions with annotation-driven ASN.1: `@Asn1Optional`, `@Asn1Default`, `@HasExtensionMarker`
- `isOptional()` returns true for both `@Asn1Optional` and `@Asn1Default` annotations
