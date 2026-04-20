// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-strings open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-strings project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Testing
import ISO_9899
import String_Primitives

@testable import Strings

// MARK: - Wave 0 Safeguards: Bridge Round-Trip Equivalence
//
// Locks the byte-level round-trip contract across the four bridge types
// before later string-correction-cycle waves can drift the implementations.
// Each suite covers one bridge edge from Research/string-type-ecosystem-model.md
// (§3 conversion graph, edges E1, E5, E12, E14).
//
// Any future change that breaks one of these tests indicates a divergence
// between an L3 bridge and the underlying L1 owning type's content semantics.

// MARK: - Swift.String ↔ Primitives.String

@Suite("Swift.String ↔ Primitives.String round-trips")
struct PrimitivesStringRoundTrip {

    /// All fixtures combined for parameterized tests. Hand-written + UTF-8 multi-byte
    /// + seeded-random ASCII for stochastic coverage. No interior NUL (rejected by
    /// owning types).
    static let fixtures: [Swift.String] = Self.handWritten + Self.utf8MultiByte + Self.randomASCII

    static let handWritten: [Swift.String] = [
        "",
        "a",
        "abc",
        "Hello, world!",
        "The quick brown fox jumps over the lazy dog.",
        Swift.String(repeating: "x", count: 1024),
    ]

    /// On Windows, these traverse UTF-8 → UTF-16 → UTF-8 at the bridge boundaries;
    /// round-trip must still be byte-identical at the `Swift.String` layer.
    static let utf8MultiByte: [Swift.String] = [
        "café",
        "naïve",
        "日本語",
        "한국어",
        "Здравствуйте",
        "🎉",
        "👨‍👩‍👧‍👦",
    ]

    /// Seeded pseudo-random ASCII fixtures for stochastic coverage.
    static let randomASCII: [Swift.String] = generateASCII(count: 64, seed: 0xC0DE_F00D_DEAD_BEEF)

    @Test("via init + Swift.String(_ owned:)", arguments: fixtures)
    func roundTripOwned(fixture: Swift.String) {
        let primitives = String_Primitives.String(fixture)
        let recovered = Swift.String(primitives)
        #expect(recovered == fixture)
    }

    @Test("via init + Swift.String(_ view:)", arguments: fixtures)
    func roundTripView(fixture: Swift.String) {
        let primitives = String_Primitives.String(fixture)
        let recovered = Swift.String(primitives.view)
        #expect(recovered == fixture)
    }

    @Test("via withPrimitivesView", arguments: fixtures)
    func roundTripWithPrimitivesView(fixture: Swift.String) {
        let recovered = fixture.withPrimitivesView { view in
            Swift.String(view)
        }
        #expect(recovered == fixture)
    }
}

// MARK: - Swift.String ↔ ISO_9899.String

@Suite("Swift.String ↔ ISO_9899.String round-trips")
struct ISO9899StringRoundTrip {

    static let fixtures: [Swift.String] = handWritten + utf8MultiByte + randomASCII

    static let handWritten: [Swift.String] = PrimitivesStringRoundTrip.handWritten

    static let utf8MultiByte: [Swift.String] = PrimitivesStringRoundTrip.utf8MultiByte

    static let randomASCII: [Swift.String] = PrimitivesStringRoundTrip.randomASCII

    @Test("via init + Swift.String(_ owned:)", arguments: fixtures)
    func roundTripOwned(fixture: Swift.String) {
        let iso = ISO_9899.String(fixture)
        let recovered = Swift.String(iso)
        #expect(recovered == fixture)
    }

    @Test("via init + Swift.String(_ view:)", arguments: fixtures)
    func roundTripView(fixture: Swift.String) {
        let iso = ISO_9899.String(fixture)
        let recovered = Swift.String(iso.view)
        #expect(recovered == fixture)
    }

    @Test("via withISO9899View", arguments: fixtures)
    func roundTripWithISO9899View(fixture: Swift.String) {
        let recovered = fixture.withISO9899View { view in
            Swift.String(view)
        }
        #expect(recovered == fixture)
    }
}

// MARK: - Cross-L1 conversions (POSIX only)
//
// Primitives.String.Char and ISO_9899.String.Char are both UInt8 on POSIX,
// so cross-conversion is byte-identical. On Windows, Primitives.String.Char
// is UInt16 (UTF-16) while ISO_9899.String.Char is UInt8 always — direct
// cross-conversion is not provided as public API and the test is gated.

#if !os(Windows)
    @Suite("Cross-L1 conversions (POSIX)")
    struct CrossL1POSIX {

        static let fixtures: [Swift.String] = handWritten + utf8MultiByte + randomASCII

    static let handWritten: [Swift.String] = PrimitivesStringRoundTrip.handWritten

    static let utf8MultiByte: [Swift.String] = PrimitivesStringRoundTrip.utf8MultiByte

    static let randomASCII: [Swift.String] = PrimitivesStringRoundTrip.randomASCII

        @Test("Primitives → ISO_9899 → Primitives", arguments: fixtures)
        func primitivesToISOAndBack(fixture: Swift.String) {
            let primitives = String_Primitives.String(fixture)
            let iso = ISO_9899.String(primitives.view)
            let recovered = String_Primitives.String(iso.view)
            // Compare via Swift.String round-trip to fixture (avoids consuming
            // the owned ~Copyable values inside the #expect macro closure).
            let recoveredSwift = Swift.String(recovered)
            #expect(recoveredSwift == fixture)
        }

        @Test("ISO_9899 → Primitives → ISO_9899", arguments: fixtures)
        func isoToPrimitivesAndBack(fixture: Swift.String) {
            let iso = ISO_9899.String(fixture)
            let primitives = String_Primitives.String(iso.view)
            let recovered = ISO_9899.String(primitives.view)
            let recoveredSwift = Swift.String(recovered)
            #expect(recoveredSwift == fixture)
        }
    }
#endif

// MARK: - SplitMix64 PRNG
//
// Seeded 64-bit PRNG for reproducible fixture generation. Mirror of
// swift-paths' Cross Layer Equivalence test infrastructure.

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Generates `count` printable-ASCII strings (length 1–64).
/// Avoids 0x00 (interior NUL forbidden) and limits to printable
/// range so the result is valid input for every owning type.
private func generateASCII(count: Int, seed: UInt64) -> [Swift.String] {
    var rng = SplitMix64(seed: seed)
    var result: [Swift.String] = []
    result.reserveCapacity(count)
    for _ in 0..<count {
        let length = Int(rng.next() % 64) + 1
        var bytes: [UInt8] = []
        bytes.reserveCapacity(length)
        for _ in 0..<length {
            // Printable ASCII range 0x20-0x7E inclusive. Excludes 0x00 (NUL),
            // 0x01-0x1F (control), 0x7F (DEL).
            bytes.append(UInt8(rng.next() % 95) + 0x20)
        }
        result.append(Swift.String(decoding: bytes, as: UTF8.self))
    }
    return result
}
