// Swift.String+ISO_9899.swift
// swift-strings
//
// Bridges between Swift.String and ISO_9899.String

public import ISO_9899


// MARK: - Swift.String FROM ISO_9899.String

extension Swift.String {
    /// Creates a Swift String from an ISO C byte string view.
    ///
    /// Interprets the bytes as UTF-8.
    ///
    /// - Parameter view: A borrowed view of an ISO C byte string.
    /// - Note: Invalid UTF-8 sequences are replaced with the Unicode replacement character.
    @inlinable
    public init(_ view: borrowing ISO_9899.String.Borrowed) {
        self = unsafe Swift.String(cString: UnsafeRawPointer(view.pointer).assumingMemoryBound(to: CChar.self))
    }

    /// Creates a Swift String from an owned ISO C byte string.
    ///
    /// Interprets the bytes as UTF-8. Consumes the owned string.
    ///
    /// - Parameter owned: An owned ISO C byte string to consume.
    @inlinable
    public init(_ owned: consuming ISO_9899.String) {
        self = unsafe Swift.String(cString: UnsafeRawPointer(owned.view.pointer).assumingMemoryBound(to: CChar.self))
    }
}

// MARK: - ISO_9899.String FROM Swift.String

extension ISO_9899.String {
    /// Creates an owned ISO C byte string from a Swift String.
    ///
    /// Encodes the string as UTF-8.
    ///
    /// - Parameter string: The Swift String to convert.
    @inlinable
    public init(_ string: Swift.String) {
        let utf8 = Array(string.utf8) + [0]  // null-terminated
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            unsafe (buffer[i] = byte)
        }
        unsafe self.init(adopting: buffer, count: utf8.count - 1)
    }
}

// MARK: - Borrowing Access

extension Swift.String {
    /// Executes a closure with a borrowed ISO C byte string view.
    ///
    /// The view is valid only for the duration of the closure.
    /// The string is encoded as UTF-8.
    ///
    /// - Parameter body: A closure that receives the borrowed view.
    /// - Returns: The value returned by the closure.
    /// - Throws: Rethrows any error thrown by the closure.
    // WORKAROUND: @_optimize(none) — CopyPropagation false positive on ~Escapable ISO_9899.String.Borrowed.
    // Same compiler bug as Property.Inout (mark_dependence classified as PointerEscape), but this
    // type's ~Escapable cannot be removed (it's in swift-standards, not under our control for this fix).
    // WHEN TO REMOVE: When swiftlang/swift fixes mark_dependence canonicalization (OSSACanonicalizeOwned.cpp:40-46)
    @_optimize(none)
    @inlinable
    public func withISO9899View<R: ~Copyable, E: Swift.Error>(
        _ body: (borrowing ISO_9899.String.Borrowed) throws(E) -> R
    ) throws(E) -> R {
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: count + 1)
        defer { unsafe buffer.deallocate() }
        for (i, byte) in utf8Array.enumerated() {
            unsafe (buffer[i] = byte)
        }
        unsafe (buffer[count] = 0)  // null-terminate
        let view = unsafe ISO_9899.String.Borrowed(UnsafePointer(buffer), count: count)
        return try body(view)
    }
}
