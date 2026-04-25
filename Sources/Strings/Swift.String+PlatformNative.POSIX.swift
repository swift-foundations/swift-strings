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

extension Swift.String {
    /// Strictly decodes platform-native code units, returning `nil` on any
    /// invalid sequence.
    ///
    /// Single entry point for decoding platform-native filesystem / path code
    /// units to `Swift.String`. Consumer code can write a single
    /// unconditional call site instead of a `#if os(Windows)` /
    /// `strictUTF8` / `strictUTF16` hand-dispatch:
    ///
    /// ```swift
    /// // Before
    /// #if os(Windows)
    /// guard let s = Swift.String.strictUTF16(codeUnits) else { return nil }
    /// #else
    /// guard let s = Swift.String.strictUTF8(codeUnits) else { return nil }
    /// #endif
    ///
    /// // After
    /// guard let s = Swift.String.strict(platformNative: codeUnits) else { return nil }
    /// ```
    ///
    /// - POSIX: delegates to ``Swift/String/strictUTF8(_:)``.
    /// - Windows: delegates to ``Swift/String/strictUTF16(_:)``.
    ///
    /// - Parameter codeUnits: Platform-native code units
    ///   (`String.Char` — `UInt8` on POSIX, `UInt16` on Windows).
    /// - Returns: The decoded string, or `nil` if the code units contain
    ///   any invalid sequence for the platform-native encoding.
    @inlinable
    public static func strict(
        platformNative codeUnits: [String_Primitives.String.Char]
    ) -> Swift.String? {
        Swift.String.strictUTF8(codeUnits)
    }

    /// Lossily decodes platform-native code units, substituting U+FFFD
    /// (Unicode replacement character) for any invalid sequence.
    ///
    /// Sibling of ``Swift/String/strict(platformNative:)``: same input
    /// shape, same dispatch direction, but always succeeds — invalid
    /// sequences become U+FFFD instead of returning `nil`. Single entry
    /// point for lossy-decoding platform-native filesystem / path code
    /// units to `Swift.String`. Consumer code can write a single
    /// unconditional call site instead of a `#if os(Windows)` /
    /// `Swift.String(decoding: codeUnits, as: UTF16.self)` /
    /// `Swift.String(decoding: codeUnits, as: UTF8.self)` hand-dispatch:
    ///
    /// ```swift
    /// // Before
    /// #if os(Windows)
    /// let s = Swift.String(decoding: codeUnits, as: UTF16.self)
    /// #else
    /// let s = Swift.String(decoding: codeUnits, as: UTF8.self)
    /// #endif
    ///
    /// // After
    /// let s = Swift.String.lossy(platformNative: codeUnits)
    /// ```
    ///
    /// - POSIX: delegates to `Swift.String(decoding: codeUnits, as: UTF8.self)`.
    /// - Windows: delegates to `Swift.String(decoding: codeUnits, as: UTF16.self)`.
    ///
    /// Both branches are stdlib's lossy decoder — invalid sequences
    /// become U+FFFD per the
    /// [string-type-ecosystem-model.md](https://github.com/swift-institute/swift-institute/blob/main/Research/string-type-ecosystem-model.md)
    /// (line 387) "standard library's lossy UTF-8 decoder" semantics.
    /// Strings containing replacement characters cannot round-trip back
    /// to the source code units; for round-trip-safe diagnostics use
    /// ``Swift/String/strict(platformNative:)`` and handle the `nil`
    /// case with raw-byte preservation.
    ///
    /// - Parameter codeUnits: Platform-native code units
    ///   (`String.Char` — `UInt8` on POSIX, `UInt16` on Windows).
    /// - Returns: The decoded string. Always succeeds; invalid sequences
    ///   substituted with U+FFFD.
    @inlinable
    public static func lossy(
        platformNative codeUnits: [String_Primitives.String.Char]
    ) -> Swift.String {
        Swift.String(decoding: codeUnits, as: UTF8.self)
    }
}

#endif
