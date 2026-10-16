//
//  AnimalIcon.swift
//  DayByDay
//

import SwiftUI

/// An animal's SF Symbol, or a drawn silhouette for animals SF Symbols lacks.
/// Both take the current foreground style. Size symbols with `.font` and
/// drawings with `.frame`.
struct AnimalIcon: View {
    let animal: LearnAnimal

    var body: some View {
        if let symbol = animal.symbol {
            Image(systemName: symbol)
                .symbolRenderingMode(.monochrome)
        } else {
            Canvas { context, size in
                // 88% so drawings sit at the same visual weight as the symbols.
                let scale = min(size.width, size.height) / 100 * 0.88
                context.translateBy(x: (size.width - 100 * scale) / 2, y: (size.height - 100 * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                AnimalDrawing.draw(animal, in: &context)
            }
            .accessibilityHidden(true)
        }
    }
}

/// Silhouettes in a 100×100 space. `fill` adds shape, `cut` removes it, so
/// details show whatever is behind the icon.
private enum AnimalDrawing {
    static func draw(_ animal: LearnAnimal, in context: inout GraphicsContext) {
        switch animal {
        case .pig:   pig(&context)
        case .cow:   cow(&context)
        case .sheep: sheep(&context)
        case .duck:  duck(&context)
        default:     break
        }
    }

    private static func fill(_ context: inout GraphicsContext, _ path: Path) {
        context.blendMode = .normal
        context.fill(path, with: .foreground)
    }

    private static func cut(_ context: inout GraphicsContext, _ path: Path) {
        context.blendMode = .destinationOut
        context.fill(path, with: .color(.black))
    }

    private static func ellipse(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> Path {
        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
    }

    private static func circle(_ cx: Double, _ cy: Double, _ r: Double) -> Path {
        ellipse(cx - r, cy - r, 2 * r, 2 * r)
    }

    private static func polygon(_ points: [(Double, Double)]) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        path.closeSubpath()
        return path
    }

    /// Front face: floppy ears folded forward, round head, big snout with nostrils.
    private static func pig(_ c: inout GraphicsContext) {
        fill(&c, ellipse(10, 18, 80, 70))
        cut(&c, polygon([(12, 20), (46, 16), (26, 50)]))
        fill(&c, polygon([(16, 23), (42, 20), (26, 45)]))
        cut(&c, polygon([(88, 20), (54, 16), (74, 50)]))
        fill(&c, polygon([(84, 23), (58, 20), (74, 45)]))
        cut(&c, circle(40, 50, 5))
        cut(&c, circle(60, 50, 5))
        cut(&c, ellipse(27, 55, 46, 31))
        fill(&c, ellipse(31, 59, 38, 23))
        cut(&c, ellipse(39, 64, 8, 13))
        cut(&c, ellipse(53, 64, 8, 13))
    }

    /// Front face: horns, side ears, a spot, and a wide muzzle with nostrils.
    private static func cow(_ c: inout GraphicsContext) {
        fill(&c, polygon([(30, 22), (20, 2), (40, 16)]))
        fill(&c, polygon([(70, 22), (80, 2), (60, 16)]))
        fill(&c, ellipse(1, 27, 30, 14))
        fill(&c, ellipse(69, 27, 30, 14))
        fill(&c, Path(roundedRect: CGRect(x: 23, y: 12, width: 54, height: 62), cornerRadius: 22))
        cut(&c, ellipse(30, 18, 16, 13))
        cut(&c, circle(39, 40, 5))
        cut(&c, circle(61, 40, 5))
        cut(&c, ellipse(15, 56, 70, 42))
        fill(&c, ellipse(19, 60, 62, 34))
        cut(&c, ellipse(33, 70, 9, 11))
        cut(&c, ellipse(58, 70, 9, 11))
    }

    /// Side view facing right: woolly cloud body, four legs, head and ear.
    private static func sheep(_ c: inout GraphicsContext) {
        for x in [24.0, 36, 56, 68] {
            fill(&c, Path(roundedRect: CGRect(x: x, y: 64, width: 8, height: 28), cornerRadius: 4))
        }
        fill(&c, ellipse(16, 36, 62, 32))
        for (x, y) in [(22.0, 50.0), (30, 38), (44, 33), (58, 34), (70, 42), (68, 58), (54, 63), (38, 63), (24, 60)] {
            fill(&c, circle(x, y, 12))
        }
        cut(&c, ellipse(66, 20, 32, 40))
        fill(&c, ellipse(70, 24, 24, 32))
        fill(&c, ellipse(62, 28, 16, 8))
        cut(&c, circle(84, 36, 3.5))
    }

    /// Side view facing right: body with raised tail, round head, bill, wing.
    private static func duck(_ c: inout GraphicsContext) {
        fill(&c, polygon([(18, 64), (4, 40), (32, 56)]))
        fill(&c, ellipse(10, 48, 74, 38))
        fill(&c, ellipse(58, 30, 28, 32))
        fill(&c, circle(70, 32, 16))
        fill(&c, Path(roundedRect: CGRect(x: 80, y: 30, width: 19, height: 11), cornerRadius: 5))
        cut(&c, circle(74, 27, 3.5))
        cut(&c, ellipse(30, 56, 40, 18))
        fill(&c, ellipse(30, 60, 40, 18))
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach([LearnAnimal.cow, .pig, .sheep, .duck, .cat]) { animal in
            AnimalIcon(animal: animal)
                .font(.system(size: 64))
                .frame(width: 80, height: 80)
                .foregroundStyle(.white)
                .padding()
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.brown))
        }
    }
    .padding()
}
