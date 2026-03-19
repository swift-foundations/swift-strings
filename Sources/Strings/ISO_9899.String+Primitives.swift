// ISO_9899.String+Primitives.swift
// swift-strings
//
// Bridges between ISO_9899.String and String_Primitives.String

public import ISO_9899
public import String_Primitives


// MARK: - ISO_9899.String FROM String_Primitives.String (POSIX only)

#if !os(Windows)

extension ISO_9899.String {
    /// Creates an owned ISO C byte string from an OS-native path string view.
    ///
    /// Available only on POSIX platforms where both use byte-oriented strings.
    /// On Windows, String_Primitives uses UTF-16 which cannot be directly
    /// converted to ISO C byte strings without encoding policy.
    ///
    /// - Parameter view: A borrowed view of an OS-native path string.
    @inlinable
    public init(_ view: borrowing String_Primitives.String.View) {
        let length = unsafe String_Primitives.String.length(of: view.pointer)
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: length + 1)

        // Copy bytes (both are UInt8 on POSIX)
        let src = unsafe view.pointer
        for i in 0...length {
            unsafe (buffer[i] = src[i])
        }

        self.init(adopting: buffer, count: length)
    }
}

extension String_Primitives.String {
    /// Creates an owned OS-native path string from an ISO C byte string view.
    ///
    /// Available only on POSIX platforms where both use byte-oriented strings.
    ///
    /// - Parameter view: A borrowed view of an ISO C byte string.
    @inlinable
    public init(_ view: borrowing ISO_9899.String.View) {
        let length = view.length
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: length + 1)

        // Copy bytes (both are UInt8 on POSIX)
        let src = view.pointer
        for i in 0...length {
            unsafe (buffer[i] = src[i])
        }

        self.init(adopting: buffer, count: length)
    }
}

#endif

// MARK: - Documentation for Windows

#if os(Windows)

// On Windows, direct conversion between ISO_9899.String (UInt8 bytes) and
// String_Primitives.String (UInt16 UTF-16) requires encoding decisions:
//
// - ISO_9899 → Primitives: Need to decode bytes as some encoding, then encode as UTF-16
// - Primitives → ISO_9899: Need to decode UTF-16, then encode as some byte encoding
//
// These conversions should go through Swift.String which handles Unicode properly:
//
//   let iso: ISO_9899.String = ...
//   let swiftString = Swift.String(iso)
//   let primitives = String_Primitives.String(swiftString)
//
// This makes the encoding policy explicit rather than hidden.

#endif
