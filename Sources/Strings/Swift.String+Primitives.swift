// Swift.String+Primitives.swift
// swift-strings
//
// Bridges between Swift.String and String_Primitives.String

public import String_Primitives


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
        // Windows: UTF-16
        var chars: [Unicode.Scalar] = []
        var current = unsafe view.pointer
        while unsafe current.pointee != 0 {
            if let scalar = unsafe Unicode.Scalar(current.pointee) {
                chars.append(scalar)
            }
            unsafe (current = current.successor())
        }
        self = Swift.String(Swift.String.UnicodeScalarView(chars))
        #else
        // POSIX: UTF-8 via CChar
        self = unsafe Swift.String(cString: view.pointer)
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
        // Windows: UTF-16
        var chars: [Unicode.Scalar] = []
        var current = unsafe owned.view.pointer
        while unsafe current.pointee != 0 {
            if let scalar = unsafe Unicode.Scalar(current.pointee) {
                chars.append(scalar)
            }
            unsafe (current = current.successor())
        }
        self = Swift.String(Swift.String.UnicodeScalarView(chars))
        #else
        // POSIX: UTF-8 via CChar
        self = unsafe Swift.String(cString: owned.view.pointer)
        #endif
    }
}

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
        // POSIX: UTF-8 (both utf8 and String.Char are UInt8)
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            buffer[i] = byte
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
    // WORKAROUND: @_optimize(none) — CopyPropagation false positive on ~Escapable String_Primitives.String.View.
    // Same compiler bug as Property.View (mark_dependence classified as PointerEscape), but this
    // type's ~Escapable cannot be removed (it's in swift-primitives string layer).
    // WHEN TO REMOVE: When swiftlang/swift fixes mark_dependence canonicalization (OSSACanonicalizeOwned.cpp:40-46)
    @_optimize(none)
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
        let view = String_Primitives.String.View(UnsafePointer(buffer), count: count)
        return try body(view)
        #else
        // POSIX: UTF-8 (both utf8 and String.Char are UInt8)
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: count + 1)
        defer { buffer.deallocate() }
        for (i, byte) in utf8Array.enumerated() {
            buffer[i] = byte
        }
        buffer[count] = 0  // null-terminate
        let view = String_Primitives.String.View(UnsafePointer(buffer), count: count)
        return try body(view)
        #endif
    }
}
