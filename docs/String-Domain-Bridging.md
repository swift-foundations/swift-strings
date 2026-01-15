# Bridging Heterogeneous String Domains in Swift: A Type-Theoretic Approach

## Abstract

Modern systems programming requires interaction between multiple string representations with incompatible semantics: Swift's Unicode-correct `String`, ISO C's byte-oriented strings, and platform-specific path encodings. This paper presents a bridging architecture that enables safe, ergonomic conversion between these domains. We establish `swift-strings` as a high-level coordination layer that provides extension initializers for all cross-domain conversions, enforcing the principle that transformations should be expressed as `init` on the target type rather than methods on the source. Our design maintains type safety through Swift's ownership system while supporting non-copyable return types via manual allocation patterns that work around standard library limitations.

## 1. Introduction

String handling in systems programming involves navigation between fundamentally different representations:

**Swift.String**: A Unicode-correct, copy-on-write string type with value semantics. Internally uses UTF-8 storage (as of Swift 5) with efficient random access for ASCII content.

**ISO_9899.String**: Null-terminated byte sequences per ISO/IEC 9899, with `Char = UInt8` on all platforms. Represents the string model assumed by C standard library functions.

**String_Primitives.String**: Platform-native path strings with `Char = CChar` on POSIX and `Char = UInt16` on Windows. Matches operating system API expectations.

These types serve different purposes and have different invariants. Yet practical code frequently needs to move data between them:

```swift
let userInput: Swift.String = getUserInput()
let path = String_Primitives.String(userInput)  // For OS API
let cString = ISO_9899.String.Owned(userInput)  // For C library
```

This work presents a principled bridging layer that makes such conversions safe, explicit, and ergonomic.

## 2. Design Philosophy

### 2.1 Extension Initializers Over Methods

A core principle of our design is that type transformations should be expressed as initializers on the target type, not methods on the source type:

```swift
// Preferred: init on target
let owned = ISO_9899.String.Owned(swiftString)

// Avoided: method on source
let owned = swiftString.toISO9899Owned()  // NOT this pattern
```

This principle has several justifications:

**Discoverability**: Users looking to create an `ISO_9899.String.Owned` naturally look at that type's initializers, not methods scattered across other types.

**Consistency**: Swift's standard library uses this pattern (`Int(someDouble)`, `String(someInt)`).

**Extension Friendliness**: Extension initializers can be added to any type from any module. Extension methods would require access to the source type's module or `@retroactive` conformance.

**Type Direction**: The target type is syntactically prominent, making the intended result clear at the call site.

### 2.2 Explicit Over Implicit

Conversions between string domains are explicit operations requiring initializer calls. We deliberately avoid:

- Implicit conversions via `ExpressibleBy*Literal` conformances
- Automatic bridging in function parameters
- Conformance to `CustomStringConvertible` that could trigger unexpected conversions

Explicit conversion ensures developers understand when encoding transformation occurs and can reason about performance implications.

### 2.3 Typed Throws

Closure-based APIs use typed throws for maximum flexibility:

```swift
public func withISO9899View<R: ~Copyable, E: Swift.Error>(
    _ body: (borrowing ISO_9899.String.View) throws(E) -> R
) throws(E) -> R
```

This enables callers to:
- Use non-throwing closures (inferred `E = Never`)
- Propagate specific error types without boxing
- Return non-copyable types (via `R: ~Copyable`)

## 3. Bridging Architecture

### 3.1 Domain Relationships

```
                    Swift.String
                    (Unicode/UTF-8)
                         │
            ┌────────────┴────────────┐
            │                         │
            ▼                         ▼
    ISO_9899.String          String_Primitives.String
    (UInt8 bytes)            (CChar / UInt16)
            │                         │
            └──────────┬──────────────┘
                       │
               (POSIX only)
```

**Swift.String ↔ ISO_9899.String**: Always available. Swift.String's UTF-8 representation maps directly to ISO_9899's byte model.

**Swift.String ↔ String_Primitives.String**: Always available. On POSIX, uses UTF-8 bytes. On Windows, uses UTF-16.

**ISO_9899.String ↔ String_Primitives.String**: POSIX only. Both are byte-oriented on POSIX. On Windows, the representations are fundamentally incompatible (bytes vs UTF-16), requiring transit through Swift.String.

### 3.2 Conversion Matrix

| Source | Target | Availability | Encoding |
|--------|--------|--------------|----------|
| Swift.String | ISO_9899.String.Owned | All | UTF-8 bytes |
| ISO_9899.String.View | Swift.String | All | UTF-8 decode |
| ISO_9899.String.Owned | Swift.String | All | UTF-8 decode |
| Swift.String | String_Primitives.String | All | UTF-8 (POSIX) / UTF-16 (Windows) |
| String_Primitives.String.View | Swift.String | All | Platform decode |
| String_Primitives.String | Swift.String | All | Platform decode |
| String_Primitives.String.View | ISO_9899.String.Owned | POSIX | Byte copy |
| ISO_9899.String.View | String_Primitives.String | POSIX | Byte copy |

## 4. Implementation

### 4.1 Swift.String to ISO_9899.String

```swift
extension ISO_9899.String.Owned {
    @inlinable
    public init(_ string: Swift.String) {
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            buffer[i] = byte
        }
        self.init(adopting: buffer, count: utf8.count - 1)
    }
}
```

This conversion:
1. Extracts UTF-8 bytes from Swift.String
2. Appends null terminator
3. Allocates buffer for ISO_9899 ownership model
4. Copies bytes (UInt8, matching ISO_9899.String.Char)

### 4.2 ISO_9899.String to Swift.String

```swift
extension Swift.String {
    @inlinable
    public init(_ view: borrowing ISO_9899.String.View) {
        self = view.withUnsafePointer { ptr in
            Swift.String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }
    }
}
```

This uses Swift.String's `init(cString:)` which interprets bytes as UTF-8. Invalid sequences are replaced with the Unicode replacement character (U+FFFD).

### 4.3 Platform-Conditional Primitives Conversion

```swift
extension String_Primitives.String {
    @inlinable
    public init(_ string: Swift.String) {
        #if os(Windows)
        let utf16 = Array(string.utf16) + [0]
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf16.count)
        for (i, unit) in utf16.enumerated() {
            buffer[i] = unit
        }
        self.init(adopting: buffer, count: utf16.count - 1)
        #else
        let utf8 = Array(string.utf8) + [0]
        let buffer = UnsafeMutablePointer<String_Primitives.String.Char>.allocate(capacity: utf8.count)
        for (i, byte) in utf8.enumerated() {
            buffer[i] = String_Primitives.String.Char(bitPattern: byte)
        }
        self.init(adopting: buffer, count: utf8.count - 1)
        #endif
    }
}
```

On POSIX, UTF-8 bytes are copied with bitcast from `UInt8` to `CChar` (same representation, possibly different signedness). On Windows, UTF-16 code units are copied directly.

### 4.4 Borrowing Access Patterns

For temporary access without allocation, we provide `with*View` methods:

```swift
extension Swift.String {
    @inlinable
    public func withISO9899View<R: ~Copyable, E: Swift.Error>(
        _ body: (borrowing ISO_9899.String.View) throws(E) -> R
    ) throws(E) -> R {
        let utf8Array = Array(self.utf8)
        let count = utf8Array.count
        let buffer = UnsafeMutablePointer<ISO_9899.String.Char>.allocate(capacity: count + 1)
        defer { buffer.deallocate() }
        for (i, byte) in utf8Array.enumerated() {
            buffer[i] = byte
        }
        buffer[count] = 0
        let view = ISO_9899.String.View(UnsafePointer(buffer))
        return try body(view)
    }
}
```

This pattern:
1. Allocates temporary buffer
2. Copies string content with null terminator
3. Creates view (lifetime bounded by closure)
4. Deallocates on exit (defer)

The manual allocation is necessary because Swift.String's `withCString` requires `R: Copyable`, incompatible with our `R: ~Copyable` requirement.

## 5. The Non-Copyable Challenge

### 5.1 Standard Library Limitations

Swift's standard library closure APIs generally require `Copyable` return types:

```swift
// Swift.String.withCString signature (simplified)
func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result
// Implicit: Result: Copyable
```

This prevents directly returning `~Copyable` types from these closures.

### 5.2 Our Solution

We work around this limitation through manual allocation:

```swift
public func withISO9899View<R: ~Copyable, E: Swift.Error>(
    _ body: (borrowing ISO_9899.String.View) throws(E) -> R
) throws(E) -> R {
    // Manual buffer management instead of withCString
    let buffer = UnsafeMutablePointer<...>.allocate(...)
    defer { buffer.deallocate() }
    // ... populate buffer ...
    return try body(view)
}
```

This enables returning `~Copyable` types while maintaining memory safety through `defer`-based cleanup.

### 5.3 Trade-offs

The manual approach has costs:
- Additional allocation (vs potential in-place access with `withCString`)
- More code complexity
- Cannot leverage Swift.String's internal optimization for contiguous ASCII

However, it enables the full generality of `~Copyable` returns, essential for composing with non-copyable types in the wider ecosystem.

## 6. Error Handling Design

### 6.1 Swift.Error Disambiguation

The `ISO_9899` package re-exports `Error_Primitives.Error`, a type that shadows Swift's `Error` protocol. In bridging code, we must use `Swift.Error` explicitly:

```swift
public func withISO9899View<R: ~Copyable, E: Swift.Error>(  // Swift.Error, not Error
    _ body: (borrowing ISO_9899.String.View) throws(E) -> R
) throws(E) -> R
```

This ensures the constraint refers to the protocol, not the shadowing type.

### 6.2 Typed Throw Benefits

Typed throws (`throws(E)`) provide several benefits:

**Type Preservation**: Callers receive the specific error type without boxing in `any Error`.

**Non-Throwing Specialization**: When `E = Never`, the compiler can optimize away error handling paths.

**Composition**: Error types compose naturally with other typed-throw APIs in the ecosystem.

## 7. POSIX-Only Direct Conversion

### 7.1 Rationale

Direct conversion between `ISO_9899.String` and `String_Primitives.String` is available only on POSIX:

```swift
#if !os(Windows)
extension ISO_9899.String.Owned {
    public init(_ view: borrowing String_Primitives.String.View) { ... }
}

extension String_Primitives.String {
    public init(_ view: borrowing ISO_9899.String.View) { ... }
}
#endif
```

On POSIX, both types are byte-oriented:
- `ISO_9899.String.Char = UInt8`
- `String_Primitives.String.Char = CChar`

These have identical representation (8-bit values), differing only in signedness interpretation. Conversion is a simple byte copy with bitcast.

### 7.2 Windows Exclusion

On Windows:
- `ISO_9899.String.Char = UInt8` (bytes)
- `String_Primitives.String.Char = UInt16` (UTF-16)

These are fundamentally different representations. Direct conversion would require encoding decisions:
- ISO_9899 → Primitives: What encoding are the bytes? UTF-8? ACP? Latin-1?
- Primitives → ISO_9899: Encode UTF-16 as what? UTF-8? ACP?

Rather than make implicit encoding choices, we require explicit transit through Swift.String:

```swift
// Windows: explicit encoding via Swift.String
let iso: ISO_9899.String.Owned = ...
let swift = Swift.String(iso)  // UTF-8 decode
let primitives = String_Primitives.String(swift)  // UTF-16 encode
```

This makes encoding policy visible at the call site.

## 8. Usage Patterns

### 8.1 C Library Interop

```swift
import Strings
import ISO_9899

func readFile(at path: Swift.String) throws -> Data {
    // Convert to ISO C string for fopen
    let cPath = ISO_9899.String.Owned(path)

    guard let file = fopen(cPath.pointer, "r") else {
        throw FileError.notFound
    }
    defer { fclose(file) }

    // ... read file ...
}
```

### 8.2 Platform API Interop

```swift
import Strings
import String_Primitives

func openFile(at path: Swift.String) throws -> FileHandle {
    let nativePath = String_Primitives.String(path)

    #if os(Windows)
    let handle = CreateFileW(nativePath.pointer, ...)
    #else
    let fd = open(nativePath.pointer, O_RDONLY)
    #endif

    // ... wrap handle ...
}
```

### 8.3 Temporary Borrowing

```swift
import Strings

func processWithCLibrary(_ string: Swift.String) {
    string.withISO9899View { view in
        // view is borrowed, valid only in this closure
        some_c_function(view.pointer)
    }
    // view is gone, buffer deallocated
}
```

## 9. Performance Considerations

### 9.1 Allocation Costs

Each conversion to an owned type allocates:
- `ISO_9899.String.Owned(swift)`: One allocation for UTF-8 bytes
- `String_Primitives.String(swift)`: One allocation for UTF-8 or UTF-16

For hot paths, consider:
- Caching converted strings
- Using `with*View` for temporary access
- Pre-allocating buffers with custom allocators

### 9.2 Copy Costs

Conversions copy string content:
- UTF-8 extraction from Swift.String
- Byte/code-unit copy to target buffer

For large strings, this may be significant. The explicit conversion model makes these costs visible.

### 9.3 Inline Optimization

All conversions are marked `@inlinable`, enabling cross-module optimization. The compiler can inline conversion code and potentially eliminate intermediate allocations in some cases.

## 10. Limitations and Future Work

**Standard Library Evolution**: When Swift's standard library closure APIs support `~Copyable` returns, the manual allocation workarounds can be simplified.

**Streaming Conversion**: Large strings could benefit from streaming conversion rather than full materialization.

**Encoding Validation**: Conversions currently assume well-formed UTF-8/UTF-16. Validation options could be added.

**Custom Allocators**: Support for arena allocation or memory pools would benefit high-frequency conversion scenarios.

## 11. Conclusion

We have presented a bridging architecture for heterogeneous string domains that:

1. Uses extension initializers for all transformations, following Swift conventions.
2. Maintains type safety through ownership annotations.
3. Supports non-copyable types via manual allocation patterns.
4. Makes encoding policy explicit, especially for Windows where domains diverge.
5. Provides both owned conversions and borrowing access patterns.

The design demonstrates that cross-domain string handling can be made safe and ergonomic through careful API design and principled use of Swift's type system.

## References

1. swift-iso-9899: ISO C byte string representation.
2. swift-string-primitives: OS-native path string representation.
3. The Swift Programming Language: Ownership.
4. The Swift Programming Language: Generics (typed throws).
5. Unicode Technical Report #17: Character Encoding Model.
