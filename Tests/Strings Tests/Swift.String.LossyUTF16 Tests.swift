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

@testable import Strings

// MARK: - Suite Scaffolding

extension Swift.String {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit Tests (fable-448 F-001 regression)
//
// The Windows String_Primitives bridge previously decoded UTF-16 by mapping
// each code unit to `Unicode.Scalar(UInt16)` individually, silently DROPPING
// surrogate pairs and malformed units. These tests lock the real UTF-16
// decoding policy of `Swift.String.lossyUTF16`, which the Windows bridge
// initializers now delegate to.

extension Swift.String.Test.Unit {

    @Test
    func `lossyUTF16 decodes basic multilingual plane text`() {
        let units: [UInt16] = [0x0048, 0x0069]  // "Hi"
        #expect(Swift.String.lossyUTF16(units) == "Hi")
    }

    @Test
    func `lossyUTF16 combines surrogate pairs into supplementary scalars`() {
        let units: [UInt16] = [0xD83C, 0xDF89]  // "🎉" (U+1F389)
        #expect(Swift.String.lossyUTF16(units) == "🎉")
    }

    @Test
    func `lossyUTF16 round-trips mixed BMP and supplementary text`() {
        let original = "path/🎉/日本語/👨‍👩‍👧‍👦"
        let units = Array(original.utf16)
        #expect(Swift.String.lossyUTF16(units) == original)
    }
}

// MARK: - Edge Cases

extension Swift.String.Test.`Edge Case` {

    @Test
    func `lossyUTF16 replaces a lone high surrogate with U+FFFD instead of dropping it`() {
        let units: [UInt16] = [0x0041, 0xD800, 0x0042]  // "A", lone high surrogate, "B"
        #expect(Swift.String.lossyUTF16(units) == "A\u{FFFD}B")
    }

    @Test
    func `lossyUTF16 replaces a lone low surrogate with U+FFFD instead of dropping it`() {
        let units: [UInt16] = [0xDC00]  // lone low surrogate
        #expect(Swift.String.lossyUTF16(units) == "\u{FFFD}")
    }

    @Test
    func `lossyUTF16 honors the full count including interior NUL`() {
        let units: [UInt16] = [0x0048, 0x0000, 0x0049]  // "H", NUL, "I"
        let decoded = Swift.String.lossyUTF16(units)
        #expect(decoded.unicodeScalars.count == 3)
        #expect(decoded == "H\u{0}I")
    }

    @Test
    func `lossyUTF16 of empty input is the empty string`() {
        #expect(Swift.String.lossyUTF16([]) == "")
    }
}
