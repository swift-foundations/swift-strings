#if os(Windows)

    public import String_Primitives
    public import ASCII_Hexadecimal_Serializer_Primitives

    extension Array where Element == String_Primitives.String.Char {

        @inlinable
        public func platformNativeHex(uppercase: Bool = true) -> Swift.String {

            if uppercase {
                let digits: [UInt8] = [
                    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
                    0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46,
                ]
                var result: [UInt8] = []
                result.reserveCapacity(count * 4)
                for codeUnit in self {
                    result.append(digits[Int((codeUnit >> 12) & 0xF)])
                    result.append(digits[Int((codeUnit >> 8) & 0xF)])
                    result.append(digits[Int((codeUnit >> 4) & 0xF)])
                    result.append(digits[Int(codeUnit & 0xF)])
                }
                return Swift.String(decoding: result, as: UTF8.self)
            }

            let serializer = ASCII.Hexadecimal.Serializer<String_Primitives.String.Char>()
            var codes: [ASCII.Code] = []
            codes.reserveCapacity(count * 4)
            for codeUnit in self {
                serializer.serialize((codeUnit >> 12) & 0xF, into: &codes)
                serializer.serialize((codeUnit >> 8) & 0xF, into: &codes)
                serializer.serialize((codeUnit >> 4) & 0xF, into: &codes)
                serializer.serialize(codeUnit & 0xF, into: &codes)
            }
            return Swift.String(decoding: codes.map(\.underlying), as: UTF8.self)
        }
    }

#endif
