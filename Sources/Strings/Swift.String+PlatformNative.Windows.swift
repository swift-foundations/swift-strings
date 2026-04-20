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
        Swift.String.strictUTF16(codeUnits)
    }
}

#endif
