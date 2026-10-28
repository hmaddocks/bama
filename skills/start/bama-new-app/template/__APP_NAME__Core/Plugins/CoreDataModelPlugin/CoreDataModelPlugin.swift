import Foundation
import PackagePlugin

/// Compiles `.xcdatamodeld` resources to `.momd` with `momc` at build time.
///
/// Plain `swift build`/`swift test` (unlike Xcode's own build system) does not
/// compile Core Data models automatically — it just copies the raw XML
/// source into the resource bundle, which `NSManagedObjectModel` cannot load.
/// This plugin closes that gap so `swift test` works standalone for this
/// package, as AGENTS.md says.
///
/// The model is looked up by a fixed path, not `target.sourceFiles`: the
/// target's `exclude` list (see Package.swift) removes it from SwiftPM's own
/// source/resource classification on purpose. Both SwiftPM's and Xcode's
/// native build systems apply their own automatic `.xcdatamodeld` handling
/// to any file they classify as a target resource, which collides with this
/// plugin's own `momc` invocation ("Multiple commands produce
/// __APP_NAME__Core.momd") the moment the app target (built through Xcode, not
/// `swift build`) depends on this package. Excluding the file removes it
/// from that classification in both build systems; this plugin then reaches
/// it directly by path, bypassing target file discovery entirely.
@main
struct CoreDataModelPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let modelURL = target.directoryURL.appending(path: "Persistence/__APP_NAME__Core.xcdatamodeld")
        guard FileManager.default.fileExists(atPath: modelURL.path) else { return [] }

        let momc = try locateMomc()

        let modelName = modelURL.deletingPathExtension().lastPathComponent
        let outputURL = context.pluginWorkDirectoryURL.appending(path: "\(modelName).momd")

        return [
            .buildCommand(
                displayName: "Compiling Core Data model \(modelName)",
                executable: momc,
                arguments: [modelURL.path, outputURL.path],
                // The inner `contents` file as well as the bundle directory:
                // editing `contents` in place with a plain text editor does
                // not change the directory's mtime, so listing only the
                // directory lets a stale `.momd` be reused. (Xcode's atomic
                // saves do touch the directory, which is why this has not
                // bitten yet.)
                inputFiles: [modelURL, modelURL.appending(path: ".xccurrentversion")]
                    + modelVersionContents(in: modelURL),
                outputFiles: [outputURL]
            )
        ]
    }

    /// Every version's `contents` file, so a new model version, or an edit
    /// to an old one, rebuilds the `.momd`.
    private func modelVersionContents(in modelURL: URL) -> [URL] {
        let versions = (try? FileManager.default.contentsOfDirectory(atPath: modelURL.path)) ?? []
        return versions.sorted()
            .filter { $0.hasSuffix(".xcdatamodel") }
            .map { modelURL.appending(path: "\($0)/contents") }
    }

    /// `momc` ships with Xcode, not the Command Line Tools, and isn't on
    /// `PATH` by default. `xcrun --find` resolves against the *active*
    /// developer directory (`xcode-select -p`), which on a fresh machine, or
    /// one that's only ever installed the Command Line Tools, points
    /// somewhere that doesn't have `momc` at all — `xcrun` can't find what
    /// isn't there, no matter how it's invoked. Fall back to scanning
    /// `/Applications` for any Xcode install, so a contributor who hasn't
    /// run `xcode-select -s` isn't stuck.
    private func locateMomc() throws -> URL {
        if let url = try? momcViaXcrun() {
            return url
        }
        if let url = momcInApplications() {
            return url
        }
        throw PluginError.momcNotFound
    }

    private func momcViaXcrun() throws -> URL {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["--find", "momc"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // discard xcrun's "unable to find utility" noise
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PluginError.momcNotFound
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let path, !path.isEmpty else {
            throw PluginError.momcNotFound
        }
        return URL(fileURLWithPath: path)
    }

    private func momcInApplications() -> URL? {
        let apps = (try? FileManager.default.contentsOfDirectory(atPath: "/Applications")) ?? []
        // Xcode.app first: a plain alphabetical scan picks Xcode-beta.app
        // over the release install.
        let ordered = ["Xcode.app"] + apps.sorted().filter { $0 != "Xcode.app" }
        for app in ordered where app.hasSuffix(".app") {
            let candidate = URL(fileURLWithPath: "/Applications")
                .appendingPathComponent(app)
                .appendingPathComponent("Contents/Developer/usr/bin/momc")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}

enum PluginError: Error, CustomStringConvertible {
    case momcNotFound

    var description: String {
        """
        Could not locate momc. Neither `xcrun --find momc` nor scanning \
        /Applications for an Xcode install found it. Install Xcode (the \
        Command Line Tools alone don't include momc), and if `xcode-select -p` \
        doesn't already point at it, run: \
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        """
    }
}
