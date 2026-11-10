import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let enabledKey = "PaleTrailEnabled"

    private var statusItem: NSStatusItem!
    private var overlays: OverlayManager!
    private var controller: TrailController!

    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [Self.enabledKey: true])

        overlays = OverlayManager()
        controller = TrailController(overlays: overlays)
        controller.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        controller.start()

        setUpStatusItem()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "PaleTrail")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()
        let hint = NSMenuItem(title: "Hold \u{2318} and move the mouse", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(.separator())

        enabledItem.target = self
        menu.addItem(enabledItem)
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())

        let about = NSMenuItem(title: "About PaleTrail", action: #selector(openRepo), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit PaleTrail", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        refreshMenuState()
    }

    private func refreshMenuState() {
        enabledItem.state = controller.isEnabled ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleEnabled() {
        controller.isEnabled.toggle()
        UserDefaults.standard.set(controller.isEnabled, forKey: Self.enabledKey)
        refreshMenuState()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nLaunch at Login only works when PaleTrail runs from an app bundle, ideally in /Applications."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        refreshMenuState()
    }

    @objc private func openRepo() {
        if let url = URL(string: "https://github.com/Gidrono/paletrail") {
            NSWorkspace.shared.open(url)
        }
    }
}
