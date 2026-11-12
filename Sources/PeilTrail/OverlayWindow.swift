import AppKit

@MainActor
final class OverlayWindow: NSWindow {
    let trailView: TrailView

    init(screen: NSScreen) {
        trailView = TrailView(frame: NSRect(origin: .zero, size: screen.frame.size))
        super.init(
            contentRect: NSRect(origin: .zero, size: screen.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        contentView = trailView
        setFrame(screen.frame, display: false)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Owns one overlay window per display and routes cells (in global screen
/// coordinates) to the window that contains them.
@MainActor
final class OverlayManager {
    private var windows: [OverlayWindow] = []
    private var screenObserver: NSObjectProtocol?

    init() {
        rebuild()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuild() }
        }
    }

    func rebuild() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows = NSScreen.screens.map { OverlayWindow(screen: $0) }
        for window in windows {
            window.orderFrontRegardless()
        }
    }

    func spawn(rect: CGRect, color: NSColor, lifetime: CFTimeInterval, endScale: CGFloat) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        guard let window = windows.first(where: { $0.frame.contains(center) }) else { return }
        let local = rect.offsetBy(dx: -window.frame.minX, dy: -window.frame.minY)
        window.trailView.spawn(rect: local, color: color, lifetime: lifetime, endScale: endScale)
    }
}
