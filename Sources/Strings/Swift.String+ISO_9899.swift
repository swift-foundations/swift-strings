public import ISO_9899

extension Swift.String {

    @inlinable
    public init(_ view: borrowing ISO_9899.String.Borrowed) {
        self = unsafe Swift.String(
            cString: UnsafeRawPointer(view.pointer).assumingMemoryBound(to: CChar.self)
        )
    }

    @inlinable
    public init(_ owned: consuming ISO_9899.String) {
        self = unsafe Swift.String(
            cString: UnsafeRawPointer(owned.view.pointer).assumingMemoryBound(to: CChar.self)
        )
    }
}

extension ISO_9899.String {

    @inlinable
    public init(_ string: Swift.String) {
        let contentLength = string.utf8.count
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: utf8.count)
        utf8.withUnsafeBufferPointer { src in
            unsafe buffer.update(from: src.baseAddress!, count: src.count)
        }
        unsafe self.init(adopting: buffer, count: contentLength)
    }
}

extension Swift.String {

    @_optimize(none)
    @inlinable
    public func withISO9899View<R: ~Copyable, E: Swift.Error>(
        _ body: (borrowing ISO_9899.String.Borrowed) throws(E) -> R
    ) throws(E) -> R {
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: count + 1)
        defer { unsafe buffer.deallocate() }
        utf8Array.withUnsafeBufferPointer { src in
            if let base = src.baseAddress {
                unsafe buffer.update(from: base, count: src.count)
            }
        }
        unsafe (buffer[count] = 0)
        let view = unsafe ISO_9899.String.Borrowed(UnsafePointer(buffer), count: count)
        return try body(view)
    }
}
