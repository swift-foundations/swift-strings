import Testing

@testable import Strings

extension Swift.String {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension Swift.String.Test.Unit {

    @Test
    func `lossyUTF16 decodes basic multilingual plane text`() {
        let units: [UInt16] = [0x0048, 0x0069]
        #expect(Swift.String.lossyUTF16(units) == "Hi")
    }

    @Test
    func `lossyUTF16 combines surrogate pairs into supplementary scalars`() {
        let units: [UInt16] = [0xD83C, 0xDF89]
        #expect(Swift.String.lossyUTF16(units) == "🎉")
    }

    @Test
    func `lossyUTF16 round-trips mixed BMP and supplementary text`() {
        let original = "path/🎉/日本語/👨‍👩‍👧‍👦"
        let units = Array(original.utf16)
        #expect(Swift.String.lossyUTF16(units) == original)
    }
}

extension Swift.String.Test.`Edge Case` {

    @Test
    func `lossyUTF16 replaces a lone high surrogate with U+FFFD instead of dropping it`() {
        let units: [UInt16] = [0x0041, 0xD800, 0x0042]
        #expect(Swift.String.lossyUTF16(units) == "A\u{FFFD}B")
    }

    @Test
    func `lossyUTF16 replaces a lone low surrogate with U+FFFD instead of dropping it`() {
        let units: [UInt16] = [0xDC00]
        #expect(Swift.String.lossyUTF16(units) == "\u{FFFD}")
    }

    @Test
    func `lossyUTF16 honors the full count including interior NUL`() {
        let units: [UInt16] = [0x0048, 0x0000, 0x0049]
        let decoded = Swift.String.lossyUTF16(units)

        #expect(decoded.unicodeScalars.count == 3)
        #expect(decoded == "H\u{0}I")
    }

    @Test
    func `lossyUTF16 of empty input is the empty string`() {
        #expect(Swift.String.lossyUTF16([]).isEmpty)
    }
}
