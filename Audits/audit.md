# Audit: swift-strings

## Platform — 2026-04-21

### Scope

- **Target**: swift-strings (L3 — cross-platform unifier; domain: strings)
- **Skill**: platform — [PLAT-ARCH-001/002], [PLAT-ARCH-008/008a/008c/008d], [PLAT-ARCH-010/011/012], [PATTERN-005/009]
- **Files**: 9 source files under `Sources/Strings/`

### Findings

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| P-01 | HIGH | [PLAT-ARCH-008c] | Swift.String+Primitives.swift:20, 44, 88, 130 | Four in-body `#if os(Windows)` blocks encode UTF-16 vs UTF-8 dispatch inside method bodies (Swift.String inits from `String_Primitives.String.View`, from consuming `String_Primitives.String`, init of `String_Primitives.String` from `Swift.String`, and `withPrimitivesView`). The newer `Swift.String+PlatformNative.{POSIX,Windows}.swift` files demonstrate the correct pattern (file-level guard + unified `strict(platformNative:)` entry). This file still carries the legacy H-41 shape. Fix: split into `Swift.String+Primitives.POSIX.swift` / `.Windows.swift` with file-level `#if !os(Windows)` / `#if os(Windows)` guards; inside each file the bodies are unconditional. | OPEN |
| P-02 | LOW | [PLAT-ARCH-008c] | ISO_9899.String+Primitives.swift:12, 62 | File contains two top-level `#if` blocks: a POSIX-only implementation guarded by `#if !os(Windows)` and a Windows-only documentation block guarded by `#if os(Windows)` (policy: "go via Swift.String for encoding"). The doc block compiles to nothing on Windows and serves only as a placeholder comment; the POSIX-half is already file-level-guarded correctly. Fix: rename file to `ISO_9899.String+Primitives.POSIX.swift`, keep the POSIX-only contents, and delete the Windows documentation block (the information belongs in DocC or a Research note, not in `#if os(Windows)`-guarded dead source). | OPEN |

### Summary

2 findings: 0 critical, 1 high, 0 medium, 1 low. Legacy consolidation: Y (H-41/H-42 from the 2026-03-19 institute-wide platform audit superseded by P-01/P-02 and removed from the legacy section).

Systemic picture: swift-strings correctly holds L3-unifier DOMAIN AUTHORITY per [PLAT-ARCH-008a] — UTF-8 vs UTF-16 decode is POLICY the consumer observes per [PLAT-ARCH-008d] (different character widths, different validation semantics). No raw platform imports (`import Darwin`/`Glibc`/`Musl`/`WinSDK`) — the hard line of [PLAT-ARCH-008a] is clean. No L2/L3-tier-skipping. The unified entry points `Swift.String.strict(platformNative:)` and `[String.Char].platformNativeHex(uppercase:)` are implemented correctly via the per-platform-file pattern of [PLAT-ARCH-008c]. The remaining work is stylistic consistency: migrate the two in-body-`#if` files to the per-platform-file pattern the rest of the package already uses. Package.swift conforms to [PATTERN-005] (Swift 6.3, swiftLanguageModes v6, full Apple platform matrix with `.v26`).
