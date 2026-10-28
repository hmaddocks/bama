import CoreData
import Foundation
import __APP_NAME__Core

/// Everything an agent can do in __CLI_NAME__. Add a command here and the CLI,
/// `help`, and the MCP tools all get it. Each `run` is on the main actor
/// with the app's store, like a button in the window. Call the same code the
/// window's actions call; never copy logic here.
@MainActor
enum AgentCommands {
    static let all: [AgentCommand] = [
        AgentCommand(name: "status", summary: "Show that the app runs, and how many of each object it holds.",
                     example: "__CLI_NAME__ status --json", readOnly: true) { _, store in
            var counts: JSONObject = [:]
            for entity in Store.model.entities {
                guard let name = entity.name else { continue }
                counts[name] = try store.viewContext.count(for: NSFetchRequest<NSManagedObject>(entityName: name))
            }
            return ["running": true, "counts": counts]
        },
        // Add the app's own commands, one per thing a person does. For a
        // Note entity (bama-swift appkit-recipes.md), with
        //     extension Note { var agentJSON: JSONObject { ["id": String(AgentCommands.agentID(self).prefix(8)), "title": title] } }
        //
        // AgentCommand(name: "notes list", summary: "List notes, newest first.",
        //              params: [.init(name: "limit", kind: .integer, help: "at most this many (default 50)"),
        //                       .init(name: "offset", kind: .integer, help: "skip this many, for the next page")],
        //              example: "__CLI_NAME__ notes list --limit 10 --json", readOnly: true) { args, store in
        //     let request = Note.fetchRequest()
        //     request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        //     let notes = try store.viewContext.fetch(request)
        //     let limit = try args.int("limit", default: 50)
        //     let offset = try args.int("offset", default: 0)
        //     let page = notes.dropFirst(offset).prefix(limit)
        //     var result: JSONObject = ["notes": page.map(\.agentJSON), "total": notes.count]
        //     if offset + page.count < notes.count { result["nextOffset"] = offset + page.count }
        //     return result
        // },
        // AgentCommand(name: "notes add", summary: "Add a note.",
        //              params: [.init(name: "title", required: true, help: "the title")],
        //              example: "__CLI_NAME__ notes add --title \"Buy milk\" --json") { args, store in
        //     let note = Note.insert(title: try args.required("title"), into: store.viewContext)
        //     store.viewContext.undoManager?.setActionName("Add Note")
        //     try store.save()
        //     return note.agentJSON
        // },
        // AgentCommand(name: "notes delete", summary: "Delete a note.",
        //              params: [.init(name: "id", required: true, positional: true, help: "the note's id")],
        //              example: "__CLI_NAME__ notes delete 3f2a9c1e --yes --json", destructive: true) { args, store in
        //     let note: Note = try find(try args.required("id"), entity: "Note", in: store)
        //     let shown = note.agentJSON
        //     guard args.confirmed else { return ["deleted": false, "wouldDelete": shown, "hint": "add --yes to delete it"] }
        //     store.viewContext.delete(note)
        //     try store.save()
        //     return ["deleted": true, "note": shown]
        // },
    ]

    /// An object by its uuid, or the start of it, for commands that take an id.
    static func find<T: NSManagedObject>(_ id: String, entity: String, in store: Store) throws -> T {
        let request = NSFetchRequest<T>(entityName: entity)
        let objects = try store.viewContext.fetch(request)
        let matches = objects.filter { agentID($0).hasPrefix(id.lowercased()) }
        guard let object = matches.first else { throw AgentError.notFound("no \(entity.lowercased()) with id \(id)") }
        guard matches.count == 1 else { throw AgentError.usage("\(matches.count) objects start with \(id). Give more characters") }
        return object
    }

    /// A stable id for agents: the object's `uuid`, lowercase, without dashes.
    static func agentID(_ object: NSManagedObject) -> String {
        ((object.value(forKey: "uuid") as? UUID)?.uuidString ?? "").lowercased().replacingOccurrences(of: "-", with: "")
    }
}
