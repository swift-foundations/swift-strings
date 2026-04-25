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

extension Array where Element == String_Primitives.String.Char {
    /// Encodes platform-native code units as UTF-8 bytes.
    ///
    /// Single entry point for transcoding platform-native filesystem /
    /// path code units to a stable cross-platform UTF-8 byte form (e.g.
    /// for `Binary.Serializable` payloads, network-stable formats, or
    /// any consumer that expects `[UInt8]` UTF-8 regardless of source
    /// platform). Consumer code can write a single unconditional call
    /// site instead of a `#if os(Windows)` decode-then-UTF8-encode loop:
    ///
    /// ```swift
    /// // Before
    /// var bytes: [UInt8] = []
    /// #if os(Windows)
    /// for scalar in Swift.String(decoding: codeUnits, as: UTF16.self).unicodeScalars {
    ///     UTF8.encode(scalar) { bytes.append($0) }
    /// }
    /// #else
    /// bytes.append(contentsOf: codeUnits)
    /// #endif
    ///
    /// // After
    /// let bytes = codeUnits.utf8Bytes
    /// ```
    ///
    /// - POSIX (`String.Char == UInt8`): zero-cost identity — `self` is
    ///   already UTF-8 bytes.
    /// - Windows (`String.Char == UInt16`): scalar-loop UTF-16 → UTF-8.
    ///
    /// This is the canonical sibling shape paired with
    /// ``Strings/Array/appendUTF8(into:)`` (buffer-append optimization
    /// for `Binary.Serializable` / streaming consumers). Both wrap the
    /// same underlying transcoding; choose based on call-site shape:
    /// owned-return for closure / property consumers, buffer-append for
    /// `RangeReplaceableCollection`-protocol consumers.
    ///
    /// Lossy-decode-style behavior at the encoding boundary: invalid
    /// UTF-16 sequences on Windows propagate via stdlib's lossy
    /// `Swift.String(decoding:as:)` — they become U+FFFD scalars in the
    /// intermediate `Swift.String` and then encode as 3-byte UTF-8
    /// `EF BF BD` in the output. Strings containing replacement
    /// characters cannot round-trip back to source code units; use
    /// ``Swift/String/strict(platformNative:)`` upstream and handle the
    /// `nil` case if round-trip safety matters.
    ///
    /// - Returns: The UTF-8-encoded bytes.
    @inlinable
    public var utf8Bytes: [UInt8] {
        self
    }

    /// Appends platform-native code units as UTF-8 bytes into a buffer.
    ///
    /// Buffer-append sibling of ``Strings/Array/utf8Bytes``: same
    /// underlying transcoding, but writes directly into a caller-owned
    /// `RangeReplaceableCollection<UInt8>` for streaming /
    /// `Binary.Serializable` consumers that want to avoid the owned-array
    /// allocation. Match the shape to your call site:
    /// owned-return for closure / property consumers, buffer-append for
    /// `serialize(_:into:)` / streaming.
    ///
    /// ```swift
    /// // Binary.Serializable consumer (buffer-append shape)
    /// public static func serialize<Buffer: RangeReplaceableCollection>(
    ///     _ value: Self,
    ///     into buffer: inout Buffer
    /// ) where Buffer.Element == UInt8 {
    ///     value.rawBytes.appendUTF8(into: &buffer)
    /// }
    /// ```
    ///
    /// - POSIX: zero-cost append-contents-of (`self` is already UTF-8).
    /// - Windows: scalar-loop UTF-16 → UTF-8 with per-byte append.
    ///
    /// - Parameter buffer: The buffer to append to. Caller may reserve
    ///   capacity in advance for known-bounded output sizes; on Windows
    ///   the worst-case UTF-8 expansion is `count * 3` bytes
    ///   (BMP scalars; supplementary scalars amortize).
    @inlinable
    public func appendUTF8<Buffer: RangeReplaceableCollection>(
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: self)
    }
}

#endif
