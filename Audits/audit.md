# Audit: swift-strings

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/platform-compliance-audit.md (2026-03-19)

**Skill**: platform — [PLAT-ARCH-001-010], [PATTERN-001], [PATTERN-004a], [PATTERN-005]

| # | Severity | Rule | Location | Finding | Status |
|---|----------|------|----------|---------|--------|
| H-41 | HIGH | [PLAT-ARCH-008] | Swift.String+Primitives.swift:20,44,73,110 | `#if os(Windows)` for UTF-16 vs UTF-8 string conversion. Fix: Use `String.Char` (from swift-string-primitives) which already encapsulates the platform character width. | OPEN — Verify String.Char provides sufficient abstraction |
| H-42 | HIGH | [PLAT-ARCH-008] | ISO_9899.String+Primitives.swift:62 | `#if os(Windows)` in documentation block. | OPEN |
