extension Swift.String {

    @inlinable
    public init(_ span: Swift.Span<UInt8>) throws(UTF8.ValidationError) {
        self = Swift.String(copying: try UTF8Span(validating: span))
    }
}
