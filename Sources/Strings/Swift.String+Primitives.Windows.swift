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

    // MARK: - Swift.String FROM String_Primitives.String (Windows: UTF-16)

    extension Swift.String {
        /// Creates a Swift String from an OS-native path string view.
        ///
        /// Decodes the view as UTF-16 code units (Windows convention) with
        /// lossy replacement: surrogate pairs combine into their
        /// supplementary-plane scalar, and malformed sequences (such as lone
        /// surrogates) become U+FFFD. All `view.count` code units are decoded.
        /// This mirrors the lossy UTF-8 policy of the POSIX twin
        /// (`Swift.String(cString:)`).
        ///
        /// - Parameter view: A borrowed view of an OS-native path string.
        @inlinable
        public init(_ view: borrowing String_Primitives.String.Borrowed) {
            let units = unsafe Array(UnsafeBufferPointer(start: view.pointer, count: view.count))
            self = Swift.String.lossyUTF16(units)
        }

        /// Creates a Swift String from an owned OS-native path string.
        ///
        /// Consumes the owned string, decoding its code units as UTF-16
        /// (Windows convention) with lossy replacement: surrogate pairs
        /// combine into their supplementary-plane scalar, and malformed
        /// sequences (such as lone surrogates) become U+FFFD. All
        /// `view.count` code units are decoded. This mirrors the lossy UTF-8
        /// policy of the POSIX twin (`Swift.String(cString:)`).
        ///
        /// - Parameter owned: An owned OS-native path string to consume.
        @inlinable
        public init(_ owned: consuming String_Primitives.String) {
            let units = unsafe Array(
                UnsafeBufferPointer(start: owned.view.pointer, count: owned.view.count)
            )
            self = Swift.String.lossyUTF16(units)
        }
    }

    // MARK: - String_Primitives.String FROM Swift.String (Windows: UTF-16)

    extension String_Primitives.String {
        /// Creates an owned OS-native path string from a Swift String.
        ///
        /// Encodes as UTF-16 (Windows convention); `String_Primitives.String.Char`
        /// is `UInt16` on Windows.
        ///
        /// - Parameter string: The Swift String to convert.
        @inlinable
        public init(_ string: Swift.String) {
            let contentLength = string.utf16.count
            let utf16 = Array(string.utf16) + [0]  // null-terminated
            let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(
                capacity: utf16.count
            )
            for (i, unit) in utf16.enumerated() {
                buffer[i] = unit
            }
            self.init(adopting: buffer, count: contentLength)
        }
    }

    // MARK: - Borrowing Access

    extension Swift.String {
        // WORKAROUND: @_optimize(none) — CopyPropagation false positive on ~Escapable String_Primitives.String.Borrowed.
        // WHY: Same compiler bug as Property.Inout (mark_dependence classified as PointerEscape), but this
        //   type's ~Escapable cannot be removed (it's in swift-primitives string layer).
        // WHEN TO REMOVE: When swiftlang/swift fixes mark_dependence canonicalization (OSSACanonicalizeOwned.cpp:40-46).
        // TRACKING: swiftlang/swift mark_dependence canonicalization (OSSACanonicalizeOwned.cpp:40-46); not filed upstream.
        /// Executes a closure with a borrowed OS-native path string view.
        ///
        /// The view is encoded as UTF-16 (Windows convention) and is valid only
        /// for the duration of the closure.
        ///
        /// - Parameter body: A closure that receives the borrowed view.
        /// - Returns: The value returned by the closure.
        /// - Throws: Rethrows any error thrown by the closure.
        @_optimize(none)
        @inlinable
        public func withPrimitivesView<R: ~Copyable, E: Swift.Error>(
            _ body: (borrowing String_Primitives.String.Borrowed) throws(E) -> R
        ) throws(E) -> R {
            let utf16Array = Array(self.utf16)
            let count = utf16Array.count
            let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(
                capacity: count + 1
            )
            defer { buffer.deallocate() }
            for (i, unit) in utf16Array.enumerated() {
                buffer[i] = unit
            }
            buffer[count] = 0  // null-terminate
            let view = String_Primitives.String.Borrowed(UnsafePointer(buffer), count: count)
            return try body(view)
        }
    }

#endif  // os(Windows)
