import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let enabledKey = "PeilTrailEnabled"
    private static let paletteKey = "PeilTrailPalette"

    private var statusItem: NSStatusItem!
    private var overlays: OverlayManager!
    private var controller: TrailController!

    private let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var paletteItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        migrateLegacyDefaults()
        UserDefaults.standard.register(defaults: [
            Self.enabledKey: true,
            Self.paletteKey: Palette.github.id,
        ])
        let savedPalette = UserDefaults.standard.string(forKey: Self.paletteKey) ?? ""
        Palette.current = Palette.named(savedPalette) ?? .github

        overlays = OverlayManager()
        controller = TrailController(overlays: overlays)
        controller.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        controller.start()

        setUpStatusItem()
    }

    /// Copies settings saved by PaleTrail (the app's previous name and bundle ID).
    private func migrateLegacyDefaults() {
        let defaults = UserDefaults.standard
        guard let legacy = UserDefaults(suiteName: "com.gidrono.paletrail") else { return }
        if defaults.object(forKey: Self.enabledKey) == nil,
           let enabled = legacy.object(forKey: "PaleTrailEnabled") as? Bool {
            defaults.set(enabled, forKey: Self.enabledKey)
        }
        if defaults.object(forKey: Self.paletteKey) == nil,
           let palette = legacy.string(forKey: "PaleTrailPalette") {
            defaults.set(palette, forKey: Self.paletteKey)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "PeilTrail")
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

        let paletteMenu = NSMenu()
        for palette in Palette.all {
            let item = NSMenuItem(title: palette.name, action: #selector(selectPalette(_:)), keyEquivalent: "")
            item.target = self
            item.image = swatchImage(for: palette)
            item.representedObject = palette.id
            paletteMenu.addItem(item)
            paletteItems.append(item)
        }
        let paletteItem = NSMenuItem(title: "Palette", action: nil, keyEquivalent: "")
        paletteItem.submenu = paletteMenu
        menu.addItem(paletteItem)
        menu.addItem(.separator())

        let about = NSMenuItem(title: "About PeilTrail", action: #selector(openRepo), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        menu.addItem(NSMenuItem(title: "Quit PeilTrail", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
        refreshMenuState()
    }

    private func refreshMenuState() {
        enabledItem.state = controller.isEnabled ? .on : .off
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        for item in paletteItems {
            item.state = item.representedObject as? String == Palette.current.id ? .on : .off
        }
    }

    private func swatchImage(for palette: Palette) -> NSImage {
        let square: CGFloat = 12
        let gap: CGFloat = 2
        let count = CGFloat(palette.colors.count)
        let size = NSSize(width: count * square + (count - 1) * gap, height: square)
        let image = NSImage(size: size, flipped: false) { _ in
            for (index, color) in palette.colors.enumerated() {
                let rect = NSRect(x: CGFloat(index) * (square + gap), y: 0, width: square, height: square)
                let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 2, yRadius: 2)
                color.setFill()
                path.fill()
                // Keeps very light colours (e.g. oatmeal) visible on a light menu.
                NSColor.black.withAlphaComponent(0.15).setStroke()
                path.lineWidth = 1
                path.stroke()
            }
            return true
        }
        image.isTemplate = false
        return image
    }

    @objc private func selectPalette(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, let palette = Palette.named(id) else { return }
        Palette.current = palette
        UserDefaults.standard.set(palette.id, forKey: Self.paletteKey)
        refreshMenuState()
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
            alert.informativeText = "\(error.localizedDescription)\n\nLaunch at Login only works when PeilTrail runs from an app bundle, ideally in /Applications."
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        refreshMenuState()
    }

    @objc private func openRepo() {
        if let url = URL(string: "https://github.com/Gidrono/PeilTrail") {
            NSWorkspace.shared.open(url)
        }
    }
}
