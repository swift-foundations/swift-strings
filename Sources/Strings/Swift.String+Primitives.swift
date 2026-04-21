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

// Cross-platform bridges between Swift.String and String_Primitives.String.
// Platform-sensitive bridges (UTF-8 vs UTF-16 dispatch) live in the
// per-platform sibling files `Swift.String+Primitives.POSIX.swift` and
// `Swift.String+Primitives.Windows.swift` per [PLAT-ARCH-008c].

// MARK: - Swift.String FROM Span<UInt8>

extension Swift.String {
    /// Creates a Swift String from a span of UTF-8 bytes.
    ///
    /// Validates the bytes as UTF-8 and copies them into an owned String.
    ///
    /// - Parameter span: A span of UTF-8 code units.
    /// - Throws: `UTF8.ValidationError` if the bytes are not valid UTF-8.
    @inlinable
    public init(_ span: Span<UInt8>) throws(UTF8.ValidationError) {
        self = Swift.String(copying: try UTF8Span(validating: span))
    }
}
