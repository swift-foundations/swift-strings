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

#if os(Windows)

public import String_Primitives

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
        let digits: [UInt8] = uppercase
            ? [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
               0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46]
            : [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
               0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
        var result: [UInt8] = []
        result.reserveCapacity(count * 4)
        for codeUnit in self {
            result.append(digits[Int((codeUnit >> 12) & 0xF)])
            result.append(digits[Int((codeUnit >> 8) & 0xF)])
            result.append(digits[Int((codeUnit >> 4) & 0xF)])
            result.append(digits[Int(codeUnit & 0xF)])
        }
        return Swift.String(decoding: result, as: UTF8.self)
    }
}

#endif
