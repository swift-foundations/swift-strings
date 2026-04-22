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

// Bridges between ISO_9899.String and String_Primitives.String.
//
// POSIX-only: both types use byte-oriented strings (UInt8) on POSIX, so
// the bridge is a direct byte copy. On Windows, String_Primitives.String
// uses UTF-16 (UInt16) which cannot be directly converted to ISO C byte
// strings without an encoding policy — consumers should route through
// `Swift.String` explicitly in that case:
//
//     let swiftString = Swift.String(iso)
//     let primitives = String_Primitives.String(swiftString)
//
// This makes the encoding policy explicit rather than hidden.

#if !os(Windows)

public import ISO_9899
public import String_Primitives

// MARK: - ISO_9899.String FROM String_Primitives.String

extension ISO_9899.String {
    /// Creates an owned ISO C byte string from an OS-native path string view.
    ///
    /// - Parameter view: A borrowed view of an OS-native path string.
    @inlinable
    public init(_ view: borrowing String_Primitives.String.Borrowed) {
        let length = unsafe String_Primitives.String.length(of: view.pointer)
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: length + 1)

        // Copy bytes (both are UInt8 on POSIX)
        let src = unsafe view.pointer
        for i in 0...length {
            unsafe (buffer[i] = src[i])
        }

        unsafe self.init(adopting: buffer, count: length)
    }
}

// MARK: - String_Primitives.String FROM ISO_9899.String

extension String_Primitives.String {
    /// Creates an owned OS-native path string from an ISO C byte string view.
    ///
    /// - Parameter view: A borrowed view of an ISO C byte string.
    @inlinable
    public init(_ view: borrowing ISO_9899.String.View) {
        let length = view.length
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: length + 1)

        // Copy bytes (both are UInt8 on POSIX)
        let src = unsafe view.pointer
        for i in 0...length {
            unsafe (buffer[i] = src[i])
        }

        unsafe self.init(adopting: buffer, count: length)
    }
}

#endif // !os(Windows)
