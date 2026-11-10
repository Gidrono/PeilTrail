import AppKit

private struct GridPoint: Hashable {
    let x: Int
    let y: Int
}

@MainActor
final class TrailController {
    var isEnabled = true {
        didSet { if !isEnabled { lastPoint = nil } }
    }

    private let overlays: OverlayManager
    private var monitors: [Any] = []
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

    init(overlays: OverlayManager) {
        self.overlays = overlays
    }

    func start() {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .flagsChanged,
        ]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
        }) {
            monitors.append(global)
        } else {
            NSLog("PaleTrail: could not install global event monitor. Check System Settings > Privacy & Security > Accessibility / Input Monitoring.")
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            self?.handle(event)
            return event
        }) {
            monitors.append(local)
        }
    }

    func stop() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

    private func handle(_ event: NSEvent) {
        // NSEvent.modifierFlags reflects the live hardware state, which is more
        // reliable than the flags attached to globally observed mouse events.
        guard isEnabled, NSEvent.modifierFlags.contains(.command) else {
            lastPoint = nil
            return
        }
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
