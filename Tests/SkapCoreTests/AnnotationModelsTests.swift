import Testing
@testable import SkapCore

@Test func annotationToolsExposeStableIdentifiers() {
    #expect(AnnotationTool.arrow.id == "arrow")
    #expect(AnnotationTool.redact.id == "redact")
}
