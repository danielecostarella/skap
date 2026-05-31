import CoreGraphics
import Foundation
import Testing
@testable import SkapCore

@Test func savedCaptureAreaRoundTripsThroughDisk() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("saved-area.json")
    let store = SavedCaptureAreaStore(fileURL: url)
    let rect = CGRect(x: 10, y: 20, width: 300, height: 200)

    store.savedArea = rect

    #expect(store.savedArea == rect)

    store.savedArea = nil

    #expect(store.savedArea == nil)
}
