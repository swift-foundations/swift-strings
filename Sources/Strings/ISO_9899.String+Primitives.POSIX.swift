#if !os(Windows)

    public import ISO_9899
    public import String_Primitives

    extension ISO_9899.String {

        @inlinable
        public init(_ view: borrowing String_Primitives.String.Borrowed) {
            let length = unsafe String_Primitives.String.length(of: view.pointer)
            let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: length + 1)

            let src = unsafe view.pointer
            unsafe buffer.update(from: src, count: length + 1)

            unsafe self.init(adopting: buffer, count: length)
        }
    }

    extension String_Primitives.String {

        @inlinable
        public init(_ view: borrowing ISO_9899.String.Borrowed) {
            let length = view.length
            let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(
                capacity: length + 1
            )

            let src = unsafe view.pointer
            unsafe buffer.update(from: src, count: length + 1)

            unsafe self.init(adopting: buffer, count: length)
        }
    }

#endif
