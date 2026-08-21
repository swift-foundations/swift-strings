#if os(Windows)

    public import String_Primitives

    extension Swift.String {

        @inlinable
        public static func strict(
            platformNative codeUnits: [String_Primitives.String.Char]
        ) -> Swift.String? {
            Self.strictUTF16(codeUnits)
        }

        @inlinable
        public static func lossy(
            platformNative codeUnits: [String_Primitives.String.Char]
        ) -> Swift.String {
            Swift.String(decoding: codeUnits, as: UTF16.self)
        }
    }

#endif
