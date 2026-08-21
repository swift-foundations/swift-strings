#if !os(Windows)

    public import String_Primitives

    extension Swift.String {

        @inlinable
        public init(_ view: borrowing String_Primitives.String.Borrowed) {
            self = unsafe Swift.String(cString: view.pointer)
        }

        @inlinable
        public init(_ owned: consuming String_Primitives.String) {
            self = unsafe Swift.String(cString: owned.view.pointer)
        }
    }

    extension String_Primitives.String {

        @inlinable
        public init(_ string: Swift.String) {
            let contentLength = string.utf8.count
            let utf8 = Array(string.utf8) + [0]
            let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(
                capacity: utf8.count
            )
            for (i, byte) in utf8.enumerated() {
                unsafe (buffer[i] = byte)
            }
            unsafe self.init(adopting: buffer, count: contentLength)
        }
    }

    extension Swift.String {

        @_optimize(none)
        @inlinable
        public func withPrimitivesView<R: ~Copyable, E: Swift.Error>(
            _ body: (borrowing String_Primitives.String.Borrowed) throws(E) -> R
        ) throws(E) -> R {
            let utf8Array = Array(self.utf8)
            let count = utf8Array.count
            let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(
                capacity: count + 1
            )
            defer { unsafe buffer.deallocate() }
            for (i, byte) in utf8Array.enumerated() {
                unsafe (buffer[i] = byte)
            }
            unsafe (buffer[count] = 0)
            let view = unsafe String_Primitives.String.Borrowed(UnsafePointer(buffer), count: count)
            return try body(view)
        }
    }

#endif
