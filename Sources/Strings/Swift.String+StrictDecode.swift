// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-strings open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-strings project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Strict Unicode Decoding

extension Swift.String {
    /// Strictly decodes UTF-8 bytes, returning `nil` on any invalid sequence.
    ///
    /// Unlike `String(decoding:as:)` which replaces invalid sequences with
    /// the Unicode replacement character (U+FFFD), this method returns `nil`
    /// if any invalid UTF-8 sequence is encountered.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let valid: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  // "Hello"
    /// let invalid: [UInt8] = [0xFF, 0xFE]  // Invalid UTF-8
    ///
    /// String.strictUTF8(valid)   // "Hello"
    /// String.strictUTF8(invalid) // nil
    /// ```
    ///
    /// - Parameter bytes: A sequence of UTF-8 bytes to decode.
    /// - Returns: The decoded string, or `nil` if the bytes contain invalid UTF-8.
    @inlinable
    public static func strictUTF8(_ bytes: [UInt8]) -> Swift.String? {
        var utf8 = UTF8()
        var iterator = bytes.makeIterator()
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(bytes.count)

        while true {
            switch utf8.decode(&iterator) {
            case .scalarValue(let scalar):
                scalars.append(scalar)
            case .emptyInput:
                return Swift.String(Swift.String.UnicodeScalarView(scalars))
            case .error:
                return nil
            }
        }
    }

    /// Strictly decodes UTF-16 code units, returning `nil` on any invalid sequence.
    ///
    /// Unlike `String(decoding:as:)` which replaces invalid sequences with
    /// the Unicode replacement character (U+FFFD), this method returns `nil`
    /// if any invalid UTF-16 sequence is encountered (such as lone surrogates).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let valid: [UInt16] = [0x0048, 0x0069]  // "Hi"
    /// let invalid: [UInt16] = [0xD800]  // Lone high surrogate
    ///
    /// String.strictUTF16(valid)   // "Hi"
    /// String.strictUTF16(invalid) // nil
    /// ```
    ///
    /// - Parameter codeUnits: A sequence of UTF-16 code units to decode.
    /// - Returns: The decoded string, or `nil` if the code units contain invalid UTF-16.
    @inlinable
    public static func strictUTF16(_ codeUnits: [UInt16]) -> Swift.String? {
        var utf16 = UTF16()
        var iterator = codeUnits.makeIterator()
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(codeUnits.count)

        while true {
            switch utf16.decode(&iterator) {
            case .scalarValue(let scalar):
                scalars.append(scalar)
            case .emptyInput:
                return Swift.String(Swift.String.UnicodeScalarView(scalars))
            case .error:
                return nil
            }
        }
    }
}
