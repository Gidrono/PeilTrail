// Replays a JSON script of mouse moves and ⌘ presses as real system events,
// so PeilTrail draws its trail while the screen is being recorded.
//
// Steps (screen points, top-left origin):
//   {"move": [x, y]}                          jump the cursor
//   {"glide": [[x, y], ...], "ms": 1200}      smooth Catmull-Rom path through the points
//                                             (add "ease": false for constant speed)
//   {"cmd": true} / {"cmd": false}            press / release ⌘
//   {"wait": 500}                             pause
//   {"scroll": 300}                           scroll content down by 300 pixels
//   {"key": 27}                               press ⌘ + virtual key code (27 is "-")
//
// Usage: swiftc -O driver.swift -o driver && ./driver steps.json

import CoreGraphics
import Foundation

guard CommandLine.arguments.count == 2,
      let data = FileManager.default.contents(atPath: CommandLine.arguments[1]),
      let steps = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
else {
    FileHandle.standardError.write("usage: driver steps.json\n".data(using: .utf8)!)
    exit(2)
}

let source = CGEventSource(stateID: .hidSystemState)
var commandDown = false
var cursor = CGEvent(source: nil)?.location ?? .zero

func setCommand(_ down: Bool) {
    let event = CGEvent(keyboardEventSource: source, virtualKey: 55, keyDown: down)
    event?.type = .flagsChanged
    event?.flags = down ? .maskCommand : []
    event?.post(tap: .cghidEventTap)
    commandDown = down
}

func moveCursor(to point: CGPoint) {
    let event = CGEvent(mouseEventSource: source, mouseType: .mouseMoved,
                        mouseCursorPosition: point, mouseButton: .left)
    event?.flags = commandDown ? .maskCommand : []
    event?.post(tap: .cghidEventTap)
    cursor = point
}

func catmullRom(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ t: CGFloat) -> CGPoint {
    let t2 = t * t, t3 = t2 * t
    func axis(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
        0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
    }
    return CGPoint(x: axis(p0.x, p1.x, p2.x, p3.x), y: axis(p0.y, p1.y, p2.y, p3.y))
}

func glide(through targets: [CGPoint], milliseconds: Double, ease: Bool) {
    let points = [cursor] + targets
    let hz = 120.0
    let frames = max(1, Int(milliseconds / 1000 * hz))
    let segments = points.count - 1
    let start = Date()
    for frame in 1...frames {
        let progress = CGFloat(frame) / CGFloat(frames)
        let eased = !ease ? progress
            : progress < 0.5 ? 2 * progress * progress : 1 - pow(-2 * progress + 2, 2) / 2
        let position = eased * CGFloat(segments)
        let index = min(Int(position), segments - 1)
        let t = position - CGFloat(index)
        let p0 = points[max(index - 1, 0)]
        let p1 = points[index]
        let p2 = points[index + 1]
        let p3 = points[min(index + 2, points.count - 1)]
        moveCursor(to: catmullRom(p0, p1, p2, p3, t))
        let due = start.addingTimeInterval(Double(frame) / hz)
        let delay = due.timeIntervalSinceNow
        if delay > 0 { usleep(useconds_t(delay * 1_000_000)) }
    }
}

func point(_ value: Any?) -> CGPoint? {
    guard let pair = value as? [Double], pair.count == 2 else { return nil }
    return CGPoint(x: pair[0], y: pair[1])
}

signal(SIGINT) { _ in
    let event = CGEvent(keyboardEventSource: nil, virtualKey: 55, keyDown: false)
    event?.type = .flagsChanged
    event?.flags = []
    event?.post(tap: .cghidEventTap)
    exit(130)
}

for step in steps {
    if let target = point(step["move"]) {
        moveCursor(to: target)
    } else if let path = step["glide"] as? [Any] {
        glide(through: path.compactMap(point), milliseconds: step["ms"] as? Double ?? 1000,
              ease: step["ease"] as? Bool ?? true)
    } else if let down = step["cmd"] as? Bool {
        setCommand(down)
    } else if let ms = step["wait"] as? Double {
        usleep(useconds_t(ms * 1000))
    } else if let code = step["key"] as? Int {
        setCommand(true)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(code), keyDown: down)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
            usleep(30_000)
        }
        setCommand(false)
    } else if let pixels = step["scroll"] as? Int {
        var remaining = pixels
        while remaining != 0 {
            let chunk = remaining > 0 ? min(remaining, 40) : max(remaining, -40)
            CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 1,
                    wheel1: Int32(-chunk), wheel2: 0, wheel3: 0)?.post(tap: .cghidEventTap)
            remaining -= chunk
            usleep(16_000)
        }
    }
}

if commandDown { setCommand(false) }
