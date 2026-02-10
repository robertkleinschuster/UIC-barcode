# Project Overview

## Purpose
UIC-barcode is a library for encoding/decoding UIC railway barcode data (IRS 90918-9 specification). It contains two implementations:

1. **Java reference implementation** (`src/`) - The upstream library maintained by UIC (Union Internationale des Chemins de fer)
2. **Swift port** (`UICBarcodeKit/`) - A Swift Package Manager library ported from the Java reference

## Supported Barcode Types
- **Static Frame** - Fixed-length `#UT` header format (v1/v2), containing U_HEAD, U_TLAY, U_FLEX data records
- **Dynamic Frame** - DOSIPAS U1/U2 format with ASN.1 UPER-encoded Level1Data/Level2Data
- **SSB Frame** - 114-byte fixed-length Small Structured Barcode

## Tech Stack
- **Java**: Maven (pom.xml), JUnit 4, Bouncy Castle (test only), Java 8+
- **Swift**: Swift Package Manager, swift-tools-version 5.10, platforms iOS 17+ / macOS 14+, XCTest, CryptoKit (no external dependencies)

## Key Relationship
The Swift implementation must stay aligned with the Java reference. Field names, optionality, constraints, and @Asn1Default handling must match Java exactly (including Java typos like `bordingOrArrival`, `preferedLanguage`).
