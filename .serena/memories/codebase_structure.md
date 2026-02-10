# Codebase Structure

```
UIC-barcode/
├── UICBarcodeKit/                    # Swift Package Manager library
│   ├── Package.swift
│   ├── Sources/UICBarcodeKit/
│   │   ├── UICBarcode.swift          # Public API (UICBarcodeDecoder)
│   │   ├── Core/
│   │   │   ├── BarcodeDecoder.swift  # Internal decoder, frame auto-detection
│   │   │   ├── BitBuffer.swift       # Bit-level read/write buffer
│   │   │   └── Errors.swift          # UICBarcodeError enum
│   │   ├── ASN1/
│   │   │   ├── UPERDecoder.swift     # ASN.1 UPER decoder
│   │   │   └── ASN1Decodable.swift   # Protocol for UPER-decodable types
│   │   ├── FCB/Models/
│   │   │   ├── UicRailTicketData.swift    # Top-level: UicRailTicketData, IssuingData, TravelerData, etc.
│   │   │   ├── Common/CommonTypes.swift   # Shared enums and small types
│   │   │   └── Tickets/TicketTypes.swift  # All ticket types (~2000 lines)
│   │   ├── Frames/
│   │   │   ├── DynamicFrame/         # DOSIPAS U1/U2 decoder + DynamicContent
│   │   │   ├── SSBFrame/             # 114-byte fixed SSB decoder
│   │   │   └── StaticFrame/          # #UT header, U_HEAD/U_TLAY/U_FLEX records
│   │   ├── Security/
│   │   │   ├── SignatureVerifier.swift # ECDSA verification (P-256/P-384/P-521)
│   │   │   └── DERParser.swift        # DER format parser for keys/signatures
│   │   └── Utilities/
│   │       └── Compression.swift      # DEFLATE compress/decompress
│   └── Tests/UICBarcodeKitTests/
│       ├── TestData/TestTicketsV3.swift   # Hex-encoded test ticket data
│       ├── TicketTests/                   # Per-ticket-type decode tests
│       ├── SSBFrameTests.swift
│       ├── DynamicFrameTests.swift
│       ├── StaticFrameTests.swift
│       ├── UPERDecoderTests.swift
│       └── ...
├── src/                              # Java reference implementation
│   ├── main/java/org/uic/barcode/
│   │   ├── ticket/                   # Ticket types with ASN.1 annotations
│   │   ├── dynamicFrame/             # Dynamic frame
│   │   ├── staticFrame/              # Static frame
│   │   ├── ssbFrame/                 # SSB frame
│   │   └── asn1/                     # ASN.1 UPER codec
│   └── test/
├── misc/                             # ASN.1 schema files (.asn)
├── docs/                             # Specification documentation
└── pom.xml                           # Maven build for Java
```
