import CoreData
import Testing
@testable import __APP_NAME__Core

/// Store-level tests may use the in-memory store. Logic tests use plain
/// values or protocol-based fakes, never a persistent store.
@MainActor
@Test("The model loads and an in-memory store opens")
func storeOpens() throws {
    let store = try Store(url: nil)
    #expect(store.viewContext.undoManager != nil)
    #expect(Store.model.entities.isEmpty)
}
