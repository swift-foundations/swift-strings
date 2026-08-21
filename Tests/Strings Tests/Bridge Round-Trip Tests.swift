import ISO_9899
import String_Primitives
import Testing

@testable import Strings

@Suite
struct `Swift.String ↔ Primitives.String round-trips` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}

    @Suite struct Integration {}

    static let fixtures: [Swift.String] = Self.curated + Self.multibyte + Self.randomized

    static let curated: [Swift.String] = [
        "",
        "a",
        "abc",
        "Hello, world!",
        "The quick brown fox jumps over the lazy dog.",
        Swift.String(repeating: "x", count: 1024),
    ]

    static let multibyte: [Swift.String] = [
        "café",
        "naïve",
        "日本語",
        "한국어",
        "Здравствуйте",
        "🎉",
        "👨‍👩‍👧‍👦",
    ]

    static let randomized: [Swift.String] = generateASCII(count: 64, seed: 0xC0DE_F00D_DEAD_BEEF)
}

extension `Swift.String ↔ Primitives.String round-trips`.Integration {
    typealias Fixtures = `Swift.String ↔ Primitives.String round-trips`

    @Test(arguments: Fixtures.fixtures)
    func `via init + Swift.String(_ owned:)`(fixture: Swift.String) {
        let primitives = String_Primitives.String(fixture)
        let recovered = Swift.String(primitives)
        #expect(recovered == fixture)
    }

    @Test(arguments: Fixtures.fixtures)
    func `via init + Swift.String(_ view:)`(fixture: Swift.String) {
        let primitives = String_Primitives.String(fixture)
        let recovered = Swift.String(primitives.view)
        #expect(recovered == fixture)
    }

    @Test(arguments: Fixtures.fixtures)
    func `via withPrimitivesView`(fixture: Swift.String) {
        let recovered = fixture.withPrimitivesView { view in
            Swift.String(view)
        }
        #expect(recovered == fixture)
    }
}

@Suite
struct `Swift.String ↔ ISO_9899.String round-trips` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}

    static let fixtures: [Swift.String] = curated + multibyte + randomized

    static let curated: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`.curated

    static let multibyte: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`.multibyte

    static let randomized: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`
        .randomized
}

extension `Swift.String ↔ ISO_9899.String round-trips`.Integration {
    typealias Fixtures = `Swift.String ↔ ISO_9899.String round-trips`

    @Test(arguments: Fixtures.fixtures)
    func `via init + Swift.String(_ owned:)`(fixture: Swift.String) {
        let iso = ISO_9899.String(fixture)
        let recovered = Swift.String(iso)
        #expect(recovered == fixture)
    }

    @Test(arguments: Fixtures.fixtures)
    func `via init + Swift.String(_ view:)`(fixture: Swift.String) {
        let iso = ISO_9899.String(fixture)
        let recovered = Swift.String(iso.view)
        #expect(recovered == fixture)
    }

    @Test(arguments: Fixtures.fixtures)
    func `via withISO9899View`(fixture: Swift.String) {
        let recovered = fixture.withISO9899View { view in
            Swift.String(view)
        }
        #expect(recovered == fixture)
    }
}

#if !os(Windows)
    @Suite
    struct `Cross-L1 conversions (POSIX)` {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}

        static let fixtures: [Swift.String] = curated + multibyte + randomized

        static let curated: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`.curated

        static let multibyte: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`
            .multibyte

        static let randomized: [Swift.String] = `Swift.String ↔ Primitives.String round-trips`
            .randomized
    }

    extension `Cross-L1 conversions (POSIX)`.Integration {
        typealias Fixtures = `Cross-L1 conversions (POSIX)`

        @Test(arguments: Fixtures.fixtures)
        func `Primitives → ISO_9899 → Primitives`(fixture: Swift.String) {
            let primitives = String_Primitives.String(fixture)
            let iso = ISO_9899.String(primitives.view)
            let recovered = String_Primitives.String(iso.view)

            let recoveredSwift = Swift.String(recovered)
            #expect(recoveredSwift == fixture)
        }

        @Test(arguments: Fixtures.fixtures)
        func `ISO_9899 → Primitives → ISO_9899`(fixture: Swift.String) {
            let iso = ISO_9899.String(fixture)
            let primitives = String_Primitives.String(iso.view)
            let recovered = ISO_9899.String(primitives.view)
            let recoveredSwift = Swift.String(recovered)
            #expect(recoveredSwift == fixture)
        }
    }
#endif

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }
}

extension SplitMix64 {
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

private func generateASCII(count: Int, seed: UInt64) -> [Swift.String] {
    var rng = SplitMix64(seed: seed)
    var result: [Swift.String] = []
    result.reserveCapacity(count)
    for _ in 0..<count {
        let length = Int(rng.next() % 64) + 1
        var bytes: [UInt8] = []
        bytes.reserveCapacity(length)
        for _ in 0..<length {

            bytes.append(UInt8(rng.next() % 95) + 0x20)
        }
        result.append(Swift.String(decoding: bytes, as: UTF8.self))
    }
    return result
}
