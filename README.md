# UIC-barcode
Implementation of FCB barcode for rail tickets as specified in the IRS 90918-9.

The implementation provides a java API for the ticket an encoding / decoding functions to convert 
the ticket to and from the ASN.1/UPER encoded byte array specified in IRS 90918-9 for the FCB (flexible content barcode).

Covered barcode types:

  - Static barcode (Fixed length structure, Version 1 and Version 2)
     - TLB (Ticket Layout Barcode content)
     - FCB (Flexible Content Barcode) version 1
     - FCB (Flexible Content Barcode) version 2 (not used by railways)
     - FCB (Flexible Content Barcode) version 3
  - Dynamic barcode (DOSIPAS)
     - FCB (Flexible Content Barcode) version 1
     - FCB (Flexible Content Barcode) version 2 (not used by railways)
     - FCB (Flexible Content Barcode) version 3
  - SSB (Small Structured Barcode)
    

Documentation is available in the wiki: https://github.com/UnionInternationalCheminsdeFer/UIC-barcode/wiki

The maven repo is available at: https://github.com/orgs/UnionInternationalCheminsdeFer/packages?repo_name=UIC-barcode

## Swift Port (UICBarcodeKit)

A Swift implementation of the UIC barcode decoder is included in this repository as a Swift Package (`UICBarcodeKit`). It is a direct port of the Java reference implementation covering all barcode types listed above.

### Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/robertkleinschuster/UIC-barcode.git", branch: "master")
]
```

Then add `UICBarcodeKit` as a dependency of your target:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "UICBarcodeKit", package: "UIC-barcode")
])
```

### Usage

```swift
import UICBarcodeKit

let barcodeData: Data = ... // raw barcode bytes
let decoder = UICBarcodeDecoder()
let barcode = try decoder.decode(barcodeData)

// Frame type detection
switch barcode.frameType {
case .staticFrame(let version):
    print("Static frame \(version)")
case .dynamicFrame(let version):
    print("Dynamic frame \(version)")
case .ssbFrame:
    print("SSB frame")
case .unknown:
    print("Unknown frame type")
}

// Access FCB ticket data (available for FCB v1, v2, and v3)
if let ticket = barcode.ticket {
    print("Issuer: \(ticket.issuingDetail.issuerName ?? "unknown")")
    print("Year: \(ticket.issuingDetail.issuingYear)")

    if let docs = ticket.transportDocument {
        for doc in docs {
            switch doc.ticket.ticketType {
            case .reservation(let r):
                print("Reservation: \(r.fromStationNum ?? 0) -> \(r.toStationNum ?? 0)")
            case .openTicket(let o):
                print("Open ticket: \(o.fromStationNum ?? 0) -> \(o.toStationNum ?? 0)")
            case .pass(let p):
                print("Pass: type \(p.passType ?? 0)")
            default:
                break
            }
        }
    }
}

// Access SSB data
if let ssb = barcode.ssbFrame {
    print("Issuer: \(ssb.issuerCode)")
    print("Ticket type: \(ssb.ticketType)")
}

// Signature verification
if let signatureData = barcode.signatureData {
    print("Key ID: \(signatureData.keyId ?? "unknown")")
}
```

### Supported Formats

| Format | Decoding | Signature Verification |
|--------|----------|----------------------|
| Static Frame v1 (`#UT01`) | Yes | ECDSA |
| Static Frame v2 (`#UT02`) | Yes | ECDSA |
| Dynamic Frame (DOSIPAS) | Yes | ECDSA |
| SSB (Small Structured Barcode) | Yes | N/A |
| FCB v1 (UPER) | Yes | - |
| FCB v2 (UPER) | Yes | - |
| FCB v3 (UPER) | Yes | - |
| TLB (Ticket Layout) | Parsed | - |

### Requirements

- Swift 5.10+
- iOS 17+ / macOS 14+

### Building and Testing

```bash
# Build
swift build

# Run all tests
swift test

# Run a specific test
swift test --filter RealTicketTests
```

-------------------------------------------------
Upcoming UIC barcode [specifications.](https://unioninternationalcheminsdefer.github.io/UIC-barcode/)
