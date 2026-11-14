import AppKit

private struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

@MainActor
final class TrailController {
    var isEnabled = true {
        didSet {
            if !isEnabled {
                lastPoint = nil
                stopMousePolling()
            }
        }
    }

    private let overlays: OverlayManager
    private var localMonitor: Any?
    private var flagsTimer: Timer?
    private var mouseTimer: Timer?
    private var lastPoint: NSPoint?
    private var lastSpawn: [GridPoint: CFTimeInterval] = [:]

    private let gridSize: CGFloat = 12
    private let cellInset: CGFloat = 1.5
    private let lifetime: CFTimeInterval = 0.6
    private let revisitInterval: CFTimeInterval = 0.12
    private let sparkleChance = 0.35
    private let sparkleSpread = 3
    /// Jumps longer than this (e.g. warping across displays) aren't interpolated.
    private let maxInterpolatedDistance: CGFloat = 1500

    /// Low-rate poll for ⌘ while idle. Avoids Accessibility / global monitors
    /// (incompatible with App Sandbox) and keeps CPU near zero when not drawing.
    private let flagsPollInterval: TimeInterval = 0.1
    /// Display-rate poll for mouse location while ⌘ is held.
    private let mousePollInterval: TimeInterval = 1.0 / 60.0

    init(overlays: OverlayManager) {
        self.overlays = overlays
    }

    func start() {
        // Local monitor still covers events delivered to this process (e.g. while
        // a menu is open). Global monitors need Accessibility and are unavailable
        // in the App Sandbox, so background drawing uses polling instead.
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .flagsChanged,
        ]
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }

        let flags = Timer(timeInterval: flagsPollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollCommandKey() }
        }
        flags.tolerance = flagsPollInterval * 0.25
        RunLoop.main.add(flags, forMode: .common)
        flagsTimer = flags
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        flagsTimer?.invalidate()
        flagsTimer = nil
        stopMousePolling()
    }

    /// While ⌘ is down, raise the poll rate to track the cursor; otherwise stay
    /// on the cheap flags-only timer. Trade-off vs a global monitor: at most
    /// ~100 ms latency to notice ⌘, and ~60 Hz sampling (not every OS mouse event)
    /// while drawing — fine for a 12 px grid trail.
    private func pollCommandKey() {
        guard isEnabled, NSEvent.modifierFlags.contains(.command) else {
            lastPoint = nil
            stopMousePolling()
            return
        }
        if mouseTimer == nil {
            startMousePollingIfNeeded()
            pollMouse()
        }
    }

    private func startMousePollingIfNeeded() {
        guard mouseTimer == nil else { return }
        let mouse = Timer(timeInterval: mousePollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.pollMouse() }
        }
        mouse.tolerance = mousePollInterval * 0.2
        RunLoop.main.add(mouse, forMode: .common)
        mouseTimer = mouse
    }

    private func stopMousePolling() {
        mouseTimer?.invalidate()
        mouseTimer = nil
    }

    private func pollMouse() {
        guard isEnabled, NSEvent.modifierFlags.contains(.command) else {
            lastPoint = nil
            stopMousePolling()
            return
        }
        let point = NSEvent.mouseLocation
        if let lastPoint, lastPoint.x == point.x, lastPoint.y == point.y {
            return
        }
        trace(from: lastPoint ?? point, to: point)
        lastPoint = point
    }

    private func handle(_ event: NSEvent) {
        // NSEvent.modifierFlags reflects the live hardware state, which is more
        // reliable than the flags attached to locally observed mouse events.
        guard isEnabled, NSEvent.modifierFlags.contains(.command) else {
            lastPoint = nil
            stopMousePolling()
            return
        }
        startMousePollingIfNeeded()
        guard event.type != .flagsChanged else { return }

        let point = NSEvent.mouseLocation
        trace(from: lastPoint ?? point, to: point)
        lastPoint = point
    }

    private func trace(from start: NSPoint, to end: NSPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = hypot(dx, dy)
        let now = CACurrentMediaTime()

        guard distance <= maxInterpolatedDistance else {
            emit(cell(at: end), now: now)
            return
        }

        let steps = max(1, Int((distance / (gridSize * 0.5)).rounded(.up)))
        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            emit(cell(at: NSPoint(x: start.x + dx * t, y: start.y + dy * t)), now: now)
        }

        if lastSpawn.count > 2000 {
            lastSpawn = lastSpawn.filter { now - $0.value < revisitInterval }
        }
    }

    private func cell(at point: NSPoint) -> GridPoint {
        GridPoint(x: Int((point.x / gridSize).rounded(.down)), y: Int((point.y / gridSize).rounded(.down)))
    }

    private func emit(_ cell: GridPoint, now: CFTimeInterval) {
        if let last = lastSpawn[cell], now - last < revisitInterval { return }
        lastSpawn[cell] = now

        spawn(cell, size: gridSize - cellInset * 2, lifetime: lifetime, endScale: 0.3)

        if Double.random(in: 0..<1) < sparkleChance {
            let offset = GridPoint(
                x: cell.x + Int.random(in: -sparkleSpread...sparkleSpread),
                y: cell.y + Int.random(in: -sparkleSpread...sparkleSpread)
            )
            if offset != cell {
                spawn(offset, size: gridSize * 0.5, lifetime: lifetime * 0.7, endScale: 0.1)
            }
        }
    }

    private func spawn(_ cell: GridPoint, size: CGFloat, lifetime: CFTimeInterval, endScale: CGFloat) {
        let centerX = (CGFloat(cell.x) + 0.5) * gridSize
        let centerY = (CGFloat(cell.y) + 0.5) * gridSize
        let rect = CGRect(x: centerX - size / 2, y: centerY - size / 2, width: size, height: size)
        overlays.spawn(rect: rect, color: Palette.random(), lifetime: lifetime, endScale: endScale)
    }
}
