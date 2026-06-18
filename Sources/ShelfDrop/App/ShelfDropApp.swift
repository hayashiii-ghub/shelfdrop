import AppKit
import OSLog

private let finderImportLogger = Logger(
    subsystem: "work.hayashigoto.ShelfDrop",
    category: "FinderImport"
)

@main
final class ShelfDropApplication: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let bundleIdentifier = "work.hayashigoto.ShelfDrop"
    private static let shared = ShelfDropApplication()
    private static var singleInstanceGuard: SingleInstanceGuard?
    private static let latestDownloadURL = URL(
        string: "https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.zip"
    )!
    private static let releasesURL = URL(
        string: "https://github.com/hayashiii-ghub/shelfdrop/releases/latest"
    )!

    private let store = ShelfStore()
    private let finderSelectionReader = FinderSelectionReader()
    private lazy var shelfWindowController = ShelfWindowController(store: store)
    private var shakeDetector: ShakeDetector?
    private var addFinderSelectionHotKey: GlobalHotKey?
    private var statusItem: NSStatusItem?
    private var copyMenuItem: NSMenuItem?
    private var moveMenuItem: NSMenuItem?
    private var zipMenuItem: NSMenuItem?
    private var clearMenuItem: NSMenuItem?
    private var shakeMenuItem: NSMenuItem?

    static func main() {
        guard let instanceGuard = SingleInstanceGuard(identifier: bundleIdentifier) else {
            activateRunningInstance()
            return
        }
        singleInstanceGuard = instanceGuard

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = shared
        terminateLegacyInstances()
        app.run()
    }

    private static func activateRunningInstance() {
        let runningInstance = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == bundleIdentifier
        }
        runningInstance?.activate(options: [])
    }

    private static func terminateLegacyInstances() {
        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        for application in NSWorkspace.shared.runningApplications where
            application.processIdentifier != currentProcessIdentifier
            && (application.bundleIdentifier == bundleIdentifier || application.localizedName == "ShelfDrop") {
            application.terminate()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["shakeDetectionEnabled": true])

        configureStatusItem()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostApplicationDidChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        updateFinderSelectionHotKey(
            frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        )

        let detector = ShakeDetector { [weak self] in
            self?.shelfWindowController.showShelf()
        }
        detector.start()
        shakeDetector = detector

        if CommandLine.arguments.contains("--simulate-shake-on-launch") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                detector.triggerForVerification()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                detector.triggerForVerification()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        addFinderSelectionHotKey = nil
        shakeDetector?.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        let hasItems = !store.items.isEmpty
        let canManageItems = hasItems && !store.isExporting
        copyMenuItem?.isEnabled = canManageItems
        moveMenuItem?.isEnabled = canManageItems
        zipMenuItem?.isEnabled = canManageItems
        clearMenuItem?.isEnabled = canManageItems
        shakeMenuItem?.state = UserDefaults.standard.bool(forKey: "shakeDetectionEnabled") ? .on : .off
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "ShelfDrop")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.delegate = self

        let addSelectionItem = NSMenuItem(
            title: "Add Finder Selection",
            action: #selector(addFinderSelection),
            keyEquivalent: "\t"
        )
        addSelectionItem.keyEquivalentModifierMask = [.option]
        menu.addItem(addSelectionItem)
        menu.addItem(NSMenuItem(title: "Show Shelf", action: #selector(showShelf), keyEquivalent: ""))
        menu.addItem(.separator())

        let copyItem = NSMenuItem(title: "Copy Items To...", action: #selector(copyItems), keyEquivalent: "")
        let moveItem = NSMenuItem(title: "Move Items To...", action: #selector(moveItems), keyEquivalent: "")
        let zipItem = NSMenuItem(title: "Create ZIP...", action: #selector(createZip), keyEquivalent: "")
        copyMenuItem = copyItem
        moveMenuItem = moveItem
        zipMenuItem = zipItem
        menu.addItem(copyItem)
        menu.addItem(moveItem)
        menu.addItem(zipItem)

        menu.addItem(.separator())

        let shakeItem = NSMenuItem(title: "Shake Detection", action: #selector(toggleShakeDetection), keyEquivalent: "")
        shakeMenuItem = shakeItem
        menu.addItem(shakeItem)

        let clearItem = NSMenuItem(title: "Clear Shelf", action: #selector(clearShelf), keyEquivalent: "")
        clearMenuItem = clearItem
        menu.addItem(clearItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Download Latest Version...", action: #selector(downloadLatestVersion), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Open Release Page", action: #selector(openReleasePage), keyEquivalent: ""))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit ShelfDrop", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items where item.action != nil {
            item.target = self
        }

        item.menu = menu
        statusItem = item
    }

    @objc private func showShelf() {
        shelfWindowController.showShelf()
    }

    @objc private func frontmostApplicationDidChange(_ notification: Notification) {
        let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
            as? NSRunningApplication
        updateFinderSelectionHotKey(frontmostBundleIdentifier: application?.bundleIdentifier)
    }

    private func updateFinderSelectionHotKey(frontmostBundleIdentifier: String?) {
        let shouldEnable = FinderShortcutAvailability.isEnabled(
            frontmostBundleIdentifier: frontmostBundleIdentifier
        )

        if shouldEnable, addFinderSelectionHotKey == nil {
            addFinderSelectionHotKey = GlobalHotKey { [weak self] in
                self?.addFinderSelection()
            }
            if addFinderSelectionHotKey == nil {
                finderImportLogger.error("Could not register the Option-Tab shortcut")
            } else {
                finderImportLogger.info("Option-Tab enabled for Finder")
            }
        } else if !shouldEnable, addFinderSelectionHotKey != nil {
            addFinderSelectionHotKey = nil
            finderImportLogger.info("Option-Tab disabled outside Finder")
        }
    }

    @objc private func addFinderSelection() {
        let frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        guard frontmostBundleIdentifier == FinderSelectionReader.finderBundleIdentifier else {
            finderImportLogger.info(
                "Ignored shortcut for frontmost app: \(frontmostBundleIdentifier ?? "unknown", privacy: .public)"
            )
            return
        }

        do {
            let urls = try finderSelectionReader.selectedFileURLs()
            guard !urls.isEmpty else {
                finderImportLogger.info("Finder selection was empty")
                return
            }
            store.addFileURLs(urls)
            finderImportLogger.info("Added \(urls.count) Finder selection item(s)")
            shelfWindowController.showShelf()
        } catch {
            finderImportLogger.error("Finder selection failed: \(error.localizedDescription, privacy: .public)")
            let alert = NSAlert(error: error)
            alert.messageText = "Could Not Read Finder Selection"
            alert.runModal()
        }
    }

    @objc private func copyItems() {
        store.copyItemsToChosenFolder()
    }

    @objc private func moveItems() {
        store.moveItemsToChosenFolder()
    }

    @objc private func createZip() {
        store.createZipArchive()
    }

    @objc private func clearShelf() {
        store.clear()
    }

    @objc private func toggleShakeDetection() {
        let defaults = UserDefaults.standard
        defaults.set(!defaults.bool(forKey: "shakeDetectionEnabled"), forKey: "shakeDetectionEnabled")
    }

    @objc private func downloadLatestVersion() {
        NSWorkspace.shared.open(Self.latestDownloadURL)
    }

    @objc private func openReleasePage() {
        NSWorkspace.shared.open(Self.releasesURL)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
