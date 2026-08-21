extension Swift.String {

    @inlinable
    public static func strictUTF8(_ bytes: [UInt8]) -> Swift.String? {
        var utf8 = UTF8()
        var iterator = bytes.makeIterator()
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(bytes.count)

        while true {
            switch utf8.decode(&iterator) {
            case .scalarValue(let scalar):
                scalars.append(scalar)

            case .emptyInput:
                return Swift.String(Self.UnicodeScalarView(scalars))

            case .error:
                return nil
            }
        }
    }

    @inlinable
    public static func strictUTF16(_ codeUnits: [UInt16]) -> Swift.String? {
        var utf16 = UTF16()
        var iterator = codeUnits.makeIterator()
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(codeUnits.count)

        while true {
            switch utf16.decode(&iterator) {
            case .scalarValue(let scalar):
                scalars.append(scalar)

            case .emptyInput:
                return Swift.String(Self.UnicodeScalarView(scalars))

            case .error:
                return nil
            }
        }
    }
}

extension Swift.String {

    @inlinable
    public static func lossyUTF16(_ codeUnits: [UInt16]) -> Swift.String {
        Swift.String(decoding: codeUnits, as: UTF16.self)
    }
}
