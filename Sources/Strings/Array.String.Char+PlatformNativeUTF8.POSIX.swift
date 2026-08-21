#if !os(Windows)

    public import String_Primitives

    extension Array where Element == String_Primitives.String.Char {

        @inlinable
        public var utf8Bytes: [UInt8] {
            self
        }

        @inlinable
        public func appendUTF8<Buffer: RangeReplaceableCollection>(
            into buffer: inout Buffer
        ) where Buffer.Element == UInt8 {
            buffer.append(contentsOf: self)
        }
    }

#endif
