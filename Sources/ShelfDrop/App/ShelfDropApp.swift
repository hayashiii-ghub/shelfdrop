import AppKit

@main
final class ShelfDropApplication: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let shared = ShelfDropApplication()
    private static let latestDownloadURL = URL(
        string: "https://github.com/hayashiii-ghub/shelfdrop/releases/latest/download/ShelfDrop-macos.zip"
    )!
    private static let releasesURL = URL(
        string: "https://github.com/hayashiii-ghub/shelfdrop/releases/latest"
    )!

    private let store = ShelfStore()
    private lazy var shelfWindowController = ShelfWindowController(store: store)
    private var shakeDetector: ShakeDetector?
    private var statusItem: NSStatusItem?
    private var copyMenuItem: NSMenuItem?
    private var moveMenuItem: NSMenuItem?
    private var zipMenuItem: NSMenuItem?
    private var clearMenuItem: NSMenuItem?
    private var shakeMenuItem: NSMenuItem?

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = shared
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["shakeDetectionEnabled": true])

        configureStatusItem()

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
        shakeDetector?.stop()
    }

    func menuWillOpen(_ menu: NSMenu) {
        let hasItems = !store.items.isEmpty
        copyMenuItem?.isEnabled = hasItems
        moveMenuItem?.isEnabled = hasItems
        zipMenuItem?.isEnabled = hasItems
        clearMenuItem?.isEnabled = hasItems
        shakeMenuItem?.state = UserDefaults.standard.bool(forKey: "shakeDetectionEnabled") ? .on : .off
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "ShelfDrop")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.delegate = self

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
