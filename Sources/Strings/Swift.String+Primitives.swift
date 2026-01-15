// Swift.String+Primitives.swift
// swift-strings
//
// Bridges between Swift.String and String_Primitives.String

import String_Primitives

// MARK: - Swift.String FROM String_Primitives.String

extension Swift.String {
    /// Creates a Swift String from an OS-native path string view.
    ///
    /// - POSIX: Interprets as UTF-8 bytes
    /// - Windows: Interprets as UTF-16 code units
    ///
    /// - Parameter view: A borrowed view of an OS-native path string.
    @inlinable
    public init(_ view: borrowing String_Primitives.String.View) {
        #if os(Windows)
        self = view.withUnsafePointer { ptr in
            // Windows: UTF-16
            var chars: [Unicode.Scalar] = []
            var current = ptr
            while current.pointee != 0 {
                if let scalar = Unicode.Scalar(current.pointee) {
                    chars.append(scalar)
                }
                current = current.successor()
            }
            return Swift.String(Swift.String.UnicodeScalarView(chars))
        }
        #else
        self = view.withUnsafePointer { ptr in
            // POSIX: UTF-8 via CChar
            Swift.String(cString: ptr)
        }
        #endif
    }

    /// Creates a Swift String from an owned OS-native path string.
    ///
    /// Consumes the owned string.
    ///
    /// - Parameter owned: An owned OS-native path string to consume.
    @inlinable
    public init(_ owned: consuming String_Primitives.String) {
        #if os(Windows)
        self = owned.withUnsafePointer { ptr in
            var chars: [Unicode.Scalar] = []
            var current = ptr
            while current.pointee != 0 {
                if let scalar = Unicode.Scalar(current.pointee) {
                    chars.append(scalar)
                }
                current = current.successor()
            }
            return Swift.String(Swift.String.UnicodeScalarView(chars))
        }
        #else
        self = owned.withUnsafePointer { ptr in
            Swift.String(cString: ptr)
        }
        #endif
    }
}

// MARK: - String_Primitives.String FROM Swift.String

extension String_Primitives.String {
    /// Creates an owned OS-native path string from a Swift String.
    ///
    /// - POSIX: Encodes as UTF-8
    /// - Windows: Encodes as UTF-16
    ///
    /// - Parameter string: The Swift String to convert.
    @inlinable
    public init(_ string: Swift.String) {
        #if os(Windows)
        // Windows: UTF-16
        let utf16 = Array(string.utf16) + [0]  // null-terminated
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf16.count)
        for (i, unit) in utf16.enumerated() {
            buffer[i] = unit
        }
        self.init(adopting: buffer, count: utf16.count - 1)
        #else
        // POSIX: UTF-8 via CChar
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            buffer[i] = String_Primitives.String.Char(bitPattern: byte)
        }
        self.init(adopting: buffer, count: utf8.count - 1)
        #endif
    }
}

// MARK: - Borrowing Access

extension Swift.String {
    /// Executes a closure with a borrowed OS-native path string view.
    ///
    /// The view is valid only for the duration of the closure.
    ///
    /// - POSIX: String is encoded as UTF-8
    /// - Windows: String is encoded as UTF-16
    ///
    /// - Parameter body: A closure that receives the borrowed view.
    /// - Returns: The value returned by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    @inlinable
    public func withPrimitivesView<R: ~Copyable, E: Swift.Error>(
        _ body: (borrowing String_Primitives.String.View) throws(E) -> R
    ) throws(E) -> R {
        #if os(Windows)
        // Windows: UTF-16
        let utf16Array = Array(self.utf16)
        let count = utf16Array.count
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: count + 1)
        defer { buffer.deallocate() }
        for (i, unit) in utf16Array.enumerated() {
            buffer[i] = unit
        }
        buffer[count] = 0  // null-terminate
        let view = String_Primitives.String.View(UnsafePointer(buffer))
        return try body(view)
        #else
        // POSIX: UTF-8 via CChar
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: count + 1)
        defer { buffer.deallocate() }
        for (i, byte) in utf8Array.enumerated() {
            buffer[i] = String_Primitives.String.Char(bitPattern: byte)
        }
        buffer[count] = 0  // null-terminate
        let view = String_Primitives.String.View(UnsafePointer(buffer))
        return try body(view)
        #endif
    }
}
