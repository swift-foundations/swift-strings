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

// MARK: - Swift.String FROM String_Primitives.String (POSIX: UTF-8)

extension Swift.String {
    /// Creates a Swift String from an OS-native path string view.
    ///
    /// Interprets the view as UTF-8 bytes (POSIX convention).
    ///
    /// - Parameter view: A borrowed view of an OS-native path string.
    @inlinable
    public init(_ view: borrowing String_Primitives.String.View) {
        self = unsafe Swift.String(cString: view.pointer)
    }

    /// Creates a Swift String from an owned OS-native path string.
    ///
    /// Consumes the owned string, interpreting its bytes as UTF-8.
    ///
    /// - Parameter owned: An owned OS-native path string to consume.
    @inlinable
    public init(_ owned: consuming String_Primitives.String) {
        self = unsafe Swift.String(cString: owned.view.pointer)
    }
}

// MARK: - String_Primitives.String FROM Swift.String (POSIX: UTF-8)

extension String_Primitives.String {
    /// Creates an owned OS-native path string from a Swift String.
    ///
    /// Encodes as UTF-8 (POSIX convention); `String_Primitives.String.Char`
    /// and `UInt8` are the same type on POSIX.
    ///
    /// - Parameter string: The Swift String to convert.
    @inlinable
    public init(_ string: Swift.String) {
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            unsafe (buffer[i] = byte)
        }
        unsafe self.init(adopting: buffer, count: utf8.count - 1)
    }
}

// MARK: - Borrowing Access

extension Swift.String {
    /// Executes a closure with a borrowed OS-native path string view.
    ///
    /// The view is encoded as UTF-8 (POSIX convention) and is valid only
    /// for the duration of the closure.
    ///
    /// - Parameter body: A closure that receives the borrowed view.
    /// - Returns: The value returned by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    // WORKAROUND: @_optimize(none) — CopyPropagation false positive on ~Escapable String_Primitives.String.View.
    // Same compiler bug as Property.View (mark_dependence classified as PointerEscape), but this
    // type's ~Escapable cannot be removed (it's in swift-primitives string layer).
    // WHEN TO REMOVE: When swiftlang/swift fixes mark_dependence canonicalization (OSSACanonicalizeOwned.cpp:40-46)
    @_optimize(none)
    @inlinable
    public func withPrimitivesView<R: ~Copyable, E: Swift.Error>(
        _ body: (borrowing String_Primitives.String.View) throws(E) -> R
    ) throws(E) -> R {
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: count + 1)
        defer { unsafe buffer.deallocate() }
        for (i, byte) in utf8Array.enumerated() {
            unsafe (buffer[i] = byte)
        }
        unsafe (buffer[count] = 0)  // null-terminate
        let view = unsafe String_Primitives.String.View(UnsafePointer(buffer), count: count)
        return try body(view)
    }
}

#endif // !os(Windows)
