import AppKit
import QuartzCore

struct Palette {
    /// Stable key persisted in UserDefaults; don't rename existing ids.
    let id: String
    let name: String
    let colors: [NSColor]

    init(id: String, name: String, hex: [UInt32]) {
        self.id = id
        self.name = name
        self.colors = hex.map { NSColor(hex: $0) }
    }

    static let github = Palette(id: "github", name: "GitHub", hex: [
        0x39D353, 0x2F81F7, 0xA371F7, 0xDB61A2, 0x26A641,
    ])
    static let earthy = Palette(id: "earthy", name: "Earthy", hex: [
        0xEDE6D6, 0x1F5F5B, 0x5F9EA0, 0xD4A62A, 0xC8643B, 0x3B2F2A, 0x8B7D70,
    ])
    static let sunset = Palette(id: "sunset", name: "Sunset", hex: [
        0xFF6B6B, 0xFF9F43, 0xFECA57, 0xFF6B9D, 0xC44569,
    ])
    static let fire = Palette(id: "fire", name: "Fire", hex: [
        0x9D0208, 0xD00000, 0xDC2F02, 0xE85D04, 0xF48C06, 0xFAA307, 0xFFBA08,
    ])
    static let ocean = Palette(id: "ocean", name: "Ocean", hex: [
        0x023E8A, 0x0077B6, 0x00B4D8, 0x48CAE4, 0x90E0EF,
    ])
    static let forest = Palette(id: "forest", name: "Forest", hex: [
        0x1B4332, 0x2D6A4F, 0x40916C, 0x52B788, 0x95D5B2,
    ])
    static let neon = Palette(id: "neon", name: "Neon", hex: [
        0xF72585, 0x7209B7, 0x4CC9F0, 0x00FFFF, 0xFF00FF,
    ])
    static let pastel = Palette(id: "pastel", name: "Pastel", hex: [
        0xFFADAD, 0xFFD6A5, 0xFDFFB6, 0xCAFFBF, 0x9BF6FF, 0xA0C4FF, 0xBDB2FF,
    ])

    static let all: [Palette] = [github, earthy, sunset, fire, ocean, forest, neon, pastel]
    static var current: Palette = github

    static func named(_ id: String) -> Palette? {
        all.first { $0.id == id }
    }

    static func random() -> NSColor {
        current.colors.randomElement() ?? .systemGreen
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// Renders trail cells as short-lived layers. Core Animation drives the fade,
/// so nothing runs on the CPU once all cells have expired.
@MainActor
final class TrailView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func spawn(rect: CGRect, color: NSColor, lifetime: CFTimeInterval, endScale: CGFloat) {
        guard let host = layer else { return }

        let cell = CALayer()
        cell.frame = rect
        cell.backgroundColor = color.cgColor
        cell.cornerRadius = rect.width * 0.15

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0

        let shrink = CABasicAnimation(keyPath: "transform.scale")
        shrink.fromValue = 1
        shrink.toValue = endScale

        let group = CAAnimationGroup()
        group.animations = [fade, shrink]
        group.duration = lifetime
        group.timingFunction = CAMediaTimingFunction(name: .easeIn)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock { [weak cell] in
            cell?.removeFromSuperlayer()
        }
        cell.opacity = 0
        cell.add(group, forKey: "trail")
        host.addSublayer(cell)
        CATransaction.commit()
    }
}
