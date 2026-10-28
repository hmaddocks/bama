# iCloud sync

How to make the Mac and iOS apps share one store through iCloud, the way
Cashflow does. The skeleton keeps a local store per device. Add sync only
when the app needs it, and write the decision in `CONTEXT.md` first:
sync adds a schema in CloudKit Console that can never lose a field.

Core Data mirrors the local SQLite store to the user's private CloudKit
database with `NSPersistentCloudKitContainer`. The app still reads and
writes only the local store. Mirroring exports and imports in the
background, so sync never slows the app down.

## 1. Make the model fit CloudKit

Mirroring refuses to load a model that breaks these rules, so fix them
before anything else:

- No unique constraints. Keep the `uuid` attribute and look objects up by
  it, and merge duplicates in code (step 6).
- Every attribute is optional or has a default.
- Every relationship is optional and has an inverse. No ordered
  relationships, and no "Deny" delete rule.

Check: `bin/test` passes, and the model has none of the above.

## 2. Turn on history in the store

In `<App>Core`'s `Store`, use `NSPersistentCloudKitContainer` and turn on
history tracking and remote change notifications for every on-disk store,
synced or not. A store that recorded history from the start can switch
sync on later; one that did not is opened read-only.

```swift
public static let cloudKitContainer = "iCloud.com.example.notes"

public init(url: URL?, syncEnabled: Bool = false) throws {
    container = NSPersistentCloudKitContainer(name: "NotesCore", managedObjectModel: Self.model)
    let description = NSPersistentStoreDescription(url: url ?? URL(fileURLWithPath: "/dev/null"))
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = true
    if url != nil {
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        if syncEnabled {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Self.cloudKitContainer)
        }
    }
    container.persistentStoreDescriptions = [description]
    var loadError: Error?
    container.loadPersistentStores { _, error in loadError = error }
    if let loadError { throw loadError }
    viewContext.automaticallyMergesChangesFromParent = true
    // Local edits in progress win over an import, field by field. The typed
    // initializer: the NSMergeByPropertyObjectTrumpMergePolicy global is a
    // non-Sendable var that Swift 6 rejects.
    viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
    viewContext.undoManager = UndoManager()
}
```

`container`'s type stays `NSPersistentContainer`, so nothing else changes.
The in-memory store for tests never syncs.

Check: `bin/test` passes, and the app opens its existing store.

## 3. Decide when it syncs

Sync is a user default, so a launch argument turns it off for one run:

```swift
/// `-CloudKitSyncEnabled NO` turns sync off for a run. Test runs never sync.
static var syncEnabled: Bool {
    if Store.isOverridden { return false }
    if UserDefaults.standard.object(forKey: "CloudKitSyncEnabled") != nil {
        return UserDefaults.standard.bool(forKey: "CloudKitSyncEnabled")
    }
    return true
}
```

Read it with `object(forKey:)` first: a launch argument stores the value as
the string "NO", which `as? Bool` misses. Every build you sign yourself
syncs to the Development environment (step 5), so development data never
reaches the user's Production data.

Check: a launch with `APP_STORE` set logs sync off.

## 4. Entitlements and signing

Each target gets an entitlements file with the same container:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.com.example.notes</string>
	</array>
	<!-- Silent push, so mirroring hears about other devices' changes.
	     Xcode writes production when it exports for distribution. -->
	<key>com.apple.developer.aps-environment</key>
	<string>development</string>
</dict>
</plist>
```

In `project.yml`, for both targets:

```yaml
settings:
  base:
    CODE_SIGN_ENTITLEMENTS: Notes/Notes.entitlements   # NotesiOS/NotesiOS.entitlements for iOS
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: V473N4HTC4
```

The Mac target also drops `CODE_SIGN_IDENTITY: "-"`, sets
`ENABLE_HARDENED_RUNTIME: YES`, and builds with `-allowProvisioningUpdates`.
iCloud does not work with ad hoc signing. In `build.sh`, delete the
`codesign --force` line: re-signing the installed copy drops the
entitlements, and the app crashes at launch when sync is on. The iOS target
adds `UIBackgroundModes: [remote-notification]` to its info, so changes
arrive while it is in the background.

Regenerate the project after the change (`touch project.yml`). A stale
project builds without the entitlement.

Check: `codesign -d --entitlements - ~/Applications/<App>.app` lists the
container, and the first build created it in the developer account.

## 5. Deploy the schema

CloudKit has two environments. Development-signed builds use Development.
A Developer ID export (Mac) or TestFlight and App Store builds (iOS) use
Production.

After every model change:

1. Launch a Debug build once with `-InitializeCloudKitSchema YES`. It calls
   `initializeCloudKitSchema()`, which creates every record type and field
   in Development, including optional fields that were always nil. It
   blocks and needs the network, so run it on request only:

   ```swift
   #if DEBUG
   if UserDefaults.standard.bool(forKey: "InitializeCloudKitSchema"),
      let cloudKit = store.container as? NSPersistentCloudKitContainer {
       do { try cloudKit.initializeCloudKitSchema() } catch { NSLog("schema: \(error)") }
   }
   #endif
   ```

2. In CloudKit Console, deploy the schema from Development to Production.
   Production can only be added to: a field once deployed stays forever.

Check: CloudKit Console shows a `CD_<Entity>` record type for every entity,
with every attribute.

## 6. The first sync

Mirroring matches records by object, not by `uuid`. A device with local
data joining an iCloud database that already holds data uploads a second
copy of everything. Pick one before shipping:

- Merge duplicates by `uuid` after each import, keeping the newest.
- Or check before loading with CloudKit options, as Cashflow's
  `FirstSyncCheck` does: when both sides hold data, ask the user which to
  keep.

Check: a second device with its own data joins without duplicates.

## 7. Test on two devices

CloudKit cannot be unit tested or run in snapshot mode. Test by hand, with
both devices signed in to the same Apple ID:

1. Add an object on the Mac. It appears on the iPhone within a minute.
2. Edit it on the iPhone. The Mac shows the edit.
3. Delete it on one, and undo. Both end with it back.

Sync errors show in Console.app: filter by the app's process and
"CloudKit". To show sync state in the app, observe
`NSPersistentCloudKitContainer.eventChangedNotification`; its
`NSPersistentCloudKitContainer.Event` carries the error.

Done when both devices show each other's changes, the Production schema
has every entity, and `CONTEXT.md` records the decision.
