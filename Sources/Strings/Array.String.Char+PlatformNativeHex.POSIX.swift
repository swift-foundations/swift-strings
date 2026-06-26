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

#if !os(Windows)

public import String_Primitives
public import ASCII_Hexadecimal_Serializer_Primitives

extension Array where Element == String_Primitives.String.Char {
    /// Returns the platform-native code units encoded as a hex string.
    ///
    /// Single entry point for hex-encoding platform-native filesystem / path
    /// code units for diagnostic output. Consumer code can write a single
    /// unconditional call site instead of a `#if os(Windows)` conditional
    /// that widens `UInt16` code units into big-endian bytes before
    /// delegating to a `[UInt8]`-oriented hex codec:
    ///
    /// ```swift
    /// // Before
    /// #if os(Windows)
    /// var bytes: [UInt8] = []
    /// bytes.reserveCapacity(codeUnits.count * 2)
    /// for codeUnit in codeUnits {
    ///     bytes.append(UInt8(codeUnit >> 8))
    ///     bytes.append(UInt8(codeUnit & 0xFF))
    /// }
    /// let hex = bytes.hex.encoded(uppercase: true)
    /// #else
    /// let hex = codeUnits.hex.encoded(uppercase: true)
    /// #endif
    ///
    /// // After
    /// let hex = codeUnits.platformNativeHex(uppercase: true)
    /// ```
    ///
    /// - POSIX (`String.Char == UInt8`): each byte becomes two hex digits.
    /// - Windows (`String.Char == UInt16`): each code unit becomes four hex
    ///   digits in big-endian order.
    ///
    /// - Parameter uppercase: Whether to use uppercase (`A–F`) or lowercase
    ///   (`a–f`) hex digits. Defaults to `true`.
    /// - Returns: The hex-encoded code units as a `Swift.String`.
    @inlinable
    public func platformNativeHex(uppercase: Bool = true) -> Swift.String {
        // Uppercase hex has no L1 serializer (the ASCII hexadecimal serializer
        // emits `a–f` only), so the uppercase nibble table stays hand-rolled.
        if uppercase {
            let digits: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                                   0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46]
            var result: [UInt8] = []
            result.reserveCapacity(count * 2)
            for byte in self {
                result.append(digits[Int(byte >> 4)])
                result.append(digits[Int(byte & 0xF)])
            }
            return Swift.String(decoding: result, as: UTF8.self)
        }

        // Lowercase path delegates the nibble→ASCII lookup to the L1 ASCII
        // hexadecimal serializer. Each nibble (0–15) serializes to exactly one
        // lowercase hex digit, preserving the fixed two-digits-per-byte width.
        let serializer = ASCII.Hexadecimal.Serializer<String_Primitives.String.Char>()
        var codes: [ASCII.Code] = []
        codes.reserveCapacity(count * 2)
        for byte in self {
            serializer.serialize(byte >> 4, into: &codes)
            serializer.serialize(byte & 0xF, into: &codes)
        }
        return Swift.String(decoding: codes.map(\.underlying), as: UTF8.self)
    }
}

#endif
