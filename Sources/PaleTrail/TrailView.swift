import AppKit
import QuartzCore

enum Palette {
    static let colors: [NSColor] = [
        NSColor(hex: 0x39D353),
        NSColor(hex: 0x2F81F7),
        NSColor(hex: 0xA371F7),
        NSColor(hex: 0xDB61A2),
        NSColor(hex: 0x26A641),
    ]

    static func random() -> NSColor {
        colors.randomElement() ?? .systemGreen
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
