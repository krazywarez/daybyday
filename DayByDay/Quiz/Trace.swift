//
//  Trace.swift
//  DayByDay
//

import CoreGraphics
import CoreText
import UIKit

/// The area a child traces over, in a `size`×`size` canvas: a letter's filled
/// shape, or a shape's thick outline.
nonisolated enum TraceGuide {
    static func region(for item: QuizItem, size: CGFloat) -> CGPath {
        if let letter = item.value(LearnLetter.self) {
            return fitted(glyph(letter.character), size: size)
        }
        let outline = fitted(shapeOutline(item.value(LearnShape.self)!), size: size)
        // normalized() removes the stroke's self-overlaps at corners.
        return outline.copy(strokingWithWidth: size * 0.12, lineCap: .round, lineJoin: .round, miterLimit: 10)
            .normalized()
    }

    /// Scales and centers `path` into the middle 80% of the canvas.
    private static func fitted(_ path: CGPath, size: CGFloat) -> CGPath {
        let box = path.boundingBoxOfPath
        let scale = size * 0.8 / max(box.width, box.height)
        var t = CGAffineTransform(translationX: size / 2, y: size / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -box.midX, y: -box.midY)
        return path.copy(using: &t) ?? path
    }

    /// The uppercase letter in the system rounded heavy font, y pointing down.
    private static func glyph(_ character: String) -> CGPath {
        let base = UIFont.systemFont(ofSize: 200, weight: .heavy)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let font = CTFontCreateWithFontDescriptor(descriptor as CTFontDescriptor, 200, nil)
        var chars = Array(character.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: chars.count)
        CTFontGetGlyphsForCharacters(font, &chars, &glyphs, chars.count)
        var flip = CGAffineTransform(scaleX: 1, y: -1)
        return CTFontCreatePathForGlyph(font, glyphs[0], &flip) ?? CGPath(rect: .zero, transform: nil)
    }

    /// Outlines in a unit square, y pointing down.
    private static func shapeOutline(_ shape: LearnShape) -> CGPath {
        let p = CGMutablePath()
        switch shape {
        case .circle:
            p.addEllipse(in: CGRect(x: 0, y: 0, width: 1, height: 1))
        case .square:
            p.addRect(CGRect(x: 0, y: 0, width: 1, height: 1))
        case .triangle:
            p.addLines(between: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.9), CGPoint(x: 0, y: 0.9)])
            p.closeSubpath()
        case .star:
            let points = (0..<10).map { i -> CGPoint in
                let r = i.isMultiple(of: 2) ? 0.5 : 0.22
                let a = -Double.pi / 2 + Double(i) * .pi / 5
                return CGPoint(x: 0.5 + r * cos(a), y: 0.5 + r * sin(a))
            }
            p.addLines(between: points)
            p.closeSubpath()
        case .heart:
            p.move(to: CGPoint(x: 0.5, y: 0.95))
            p.addCurve(to: CGPoint(x: 0, y: 0.3), control1: CGPoint(x: 0.2, y: 0.75), control2: CGPoint(x: 0, y: 0.55))
            p.addCurve(to: CGPoint(x: 0.5, y: 0.2), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: 0.4, y: -0.05))
            p.addCurve(to: CGPoint(x: 1, y: 0.3), control1: CGPoint(x: 0.6, y: -0.05), control2: CGPoint(x: 1, y: 0))
            p.addCurve(to: CGPoint(x: 0.5, y: 0.95), control1: CGPoint(x: 1, y: 0.55), control2: CGPoint(x: 0.8, y: 0.75))
            p.closeSubpath()
        case .oval:
            p.addEllipse(in: CGRect(x: 0, y: 0, width: 1, height: 0.65))
        case .diamond:
            p.addLines(between: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
            p.closeSubpath()
        case .rectangle:
            p.addRect(CGRect(x: 0, y: 0, width: 1, height: 0.6))
        }
        return p
    }
}

/// Scores a finger trace against a guide region.
nonisolated struct TraceChecker {
    /// Points inside the region, on a grid.
    let samples: [CGPoint]
    private let region: CGPath
    private let tolerance: CGFloat

    init(region: CGPath, size: CGFloat) {
        self.region = region
        tolerance = size * 0.07
        let step = size / 30
        var samples: [CGPoint] = []
        for row in 0...30 {
            for col in 0...30 {
                let point = CGPoint(x: CGFloat(col) * step, y: CGFloat(row) * step)
                if region.contains(point) { samples.append(point) }
            }
        }
        self.samples = samples
    }

    /// Coverage: share of the region the finger passed near. Accuracy: share
    /// of the finger's points on or near the region.
    func score(_ drawn: [CGPoint]) -> (coverage: Double, accuracy: Double) {
        guard !drawn.isEmpty, !samples.isEmpty else { return (0, 0) }
        let t2 = tolerance * tolerance
        func near(_ a: CGPoint, _ b: CGPoint) -> Bool {
            let dx = a.x - b.x, dy = a.y - b.y
            return dx * dx + dy * dy <= t2
        }
        let covered = samples.filter { s in drawn.contains { near($0, s) } }.count
        let onTarget = drawn.filter { d in region.contains(d) || samples.contains { near($0, d) } }.count
        return (Double(covered) / Double(samples.count), Double(onTarget) / Double(drawn.count))
    }

    func passes(_ drawn: [CGPoint]) -> Bool {
        let s = score(drawn)
        return s.coverage >= 0.75 && s.accuracy >= 0.75
    }
}
