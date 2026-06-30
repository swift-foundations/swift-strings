# swift-strings

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Bridges Swift's `String` to OS-native path strings, ISO C byte strings, and raw UTF-8/UTF-16 code units, with strict decoders that return `nil` on invalid input instead of substituting U+FFFD.

---

## Key Features

- **Strict Unicode decoding** — `strictUTF8` and `strictUTF16` return `nil` on any invalid sequence instead of substituting the U+FFFD replacement character.
- **Validated span construction** — build a `String` from a `Span<UInt8>` of UTF-8, throwing a typed `UTF8.ValidationError` on malformed input.
- **OS-native path bridging** — convert between `String` and `String_Primitives.String` (UTF-8 on POSIX, UTF-16 on Windows) by borrow, by consuming, or through a scoped `withPrimitivesView` closure.
- **ISO C string bridging** — convert between `String` and null-terminated `ISO_9899.String` byte strings, with a scoped `withISO9899View` closure for borrowed access.
- **Platform-native decode helpers** — `strict(platformNative:)` and `lossy(platformNative:)` collapse `#if os(Windows)` UTF-8/UTF-16 dispatch into a single call site.
- **Platform-native hex** — `platformNativeHex(uppercase:)` renders path code units as hex for diagnostics, widening UTF-16 units to big-endian bytes on Windows.

---

## Quick Start

`String(decoding:as:)` silently substitutes the U+FFFD replacement character for malformed bytes, corrupting data that should have been rejected. The strict decoders fail instead, so invalid input can be handled rather than mangled:

```swift
import Strings

// "Hi" followed by an invalid UTF-8 byte.
let utf8: [UInt8] = [0x48, 0x69, 0xFF]

// The standard library silently substitutes U+FFFD for the invalid byte:
Swift.String(decoding: utf8, as: UTF8.self)   // "Hi\u{FFFD}"

// strictUTF8 rejects the input instead of corrupting it:
Swift.String.strictUTF8(utf8)                 // nil
Swift.String.strictUTF8([0x48, 0x69])         // "Hi"

// strictUTF16 applies the same all-or-nothing rule — a lone surrogate
// fails instead of decoding to U+FFFD:
Swift.String.strictUTF16([0xD800])            // nil
Swift.String.strictUTF16([0x0048, 0x0069])    // "Hi"
```

The module re-exports `String_Primitives` and `ISO_9899`, so `import Strings` brings the bridged types into scope; qualify `Swift.String` explicitly, since `String_Primitives` also vends a `String` type.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-strings.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Strings", package: "swift-strings")
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
