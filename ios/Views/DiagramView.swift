import SwiftUI

struct DiagramView: View {
    let scenario: Scenario
    let bush: Double
    let cutter: Double
    let offset: Double?

    private let boardW: CGFloat = 460
    private let boardH: CGFloat = 300

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / boardW, y: size.height / boardH)
            draw(into: &ctx)
        }
        .aspectRatio(boardW / boardH, contentMode: .fit)
        .accessibilityLabel("Cross-section diagram")
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(CGRect(x: x, y: y, width: w, height: h))
    }

    private func label(_ ctx: inout GraphicsContext, _ text: String, _ x: CGFloat, _ y: CGFloat,
                       size: CGFloat, color: Color, anchor: UnitPoint = .leading, bold: Bool = false) {
        var t = Text(text).font(.system(size: size, weight: bold ? .bold : .regular))
        t = t.foregroundColor(color)
        ctx.draw(t, at: CGPoint(x: x, y: y), anchor: anchor)
    }

    private func draw(into ctx: inout GraphicsContext) {
        let scale: CGFloat = 3.2
        let B = CGFloat(bush), C = CGFloat(cutter)
        let bw = min(B, 34) * scale
        let cw = min(C, 30) * scale
        let female = (scenario == .femHole || scenario == .femPlug)
        let ex: CGFloat = 230 - 70            // template edge x
        let bushCX = female ? ex + bw / 2 : ex - bw / 2
        let cutCX = bushCX
        let cutL = cutCX - cw / 2
        let cutR = cutCX + cw / 2

        // workpiece
        ctx.fill(rect(20, 205, 420, 55), with: .color(Color(hex: "e7cf9f")))
        ctx.stroke(rect(20, 205, 420, 55), with: .color(Color(hex: "a98d55")))
        label(&ctx, "Workpiece", 30, 238, size: 13, color: Color(hex: "7a5c1e"))

        // template layer
        if female {
            ctx.fill(rect(20, 165, ex - 20, 40), with: .color(Color(hex: "9fd8e8")))
            ctx.stroke(rect(20, 165, ex - 20, 40), with: .color(Color(hex: "4a93a8")))
            label(&ctx, "Template", 30, 190, size: 13, color: Color(hex: "245e6e"))
        } else {
            ctx.fill(rect(ex, 165, 440 - ex, 40), with: .color(Color(hex: "9fd8e8")))
            ctx.stroke(rect(ex, 165, 440 - ex, 40), with: .color(Color(hex: "4a93a8")))
            label(&ctx, "Template", ex + 12, 190, size: 13, color: Color(hex: "245e6e"))
        }

        // router base
        let base = Path(roundedRect: CGRect(x: bushCX - 90, y: 40, width: 180, height: 30), cornerRadius: 6)
        ctx.fill(base, with: .color(Color(hex: "2f8f7a")))
        ctx.stroke(base, with: .color(Color(hex: "1e6b5a")))
        label(&ctx, "ROUTER", bushCX, 60, size: 14, color: .white, anchor: .center, bold: true)

        // bush (outer + lighter bore)
        ctx.fill(rect(bushCX - bw / 2, 70, bw, 100), with: .color(Color(hex: "8d8d8d")))
        ctx.stroke(rect(bushCX - bw / 2, 70, bw, 100), with: .color(Color(hex: "5a5a5a")))
        ctx.fill(rect(bushCX - bw / 2 + 6, 70, max(bw - 12, 2), 100), with: .color(Color(hex: "bdbdbd")))

        // cutter
        ctx.fill(rect(cutL, 70, cw, 190), with: .color(Color(hex: "8c4bbf")))
        ctx.stroke(rect(cutL, 70, cw, 190), with: .color(Color(hex: "5d2f85")))

        // cut slot in workpiece (dashed)
        let slot = rect(cutL, 205, cw, 55)
        ctx.fill(slot, with: .color(.white))
        ctx.stroke(slot, with: .color(Color(hex: "8c4bbf")), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

        // template edge marker (dashed vertical)
        var edge = Path(); edge.move(to: CGPoint(x: ex, y: 160)); edge.addLine(to: CGPoint(x: ex, y: 270))
        ctx.stroke(edge, with: .color(Color(hex: "4a93a8")), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

        // offset dimension
        if let o = offset, o >= 0 {
            let keptX: CGFloat = scenario.isDiff ? (female ? cutL : cutR) : (female ? cutR : cutL)
            let red = Color(hex: "c0392b")
            for x in [keptX, ex] {
                var tick = Path(); tick.move(to: CGPoint(x: x, y: 260)); tick.addLine(to: CGPoint(x: x, y: 285))
                ctx.stroke(tick, with: .color(red))
            }
            var dim = Path()
            dim.move(to: CGPoint(x: min(ex, keptX), y: 280))
            dim.addLine(to: CGPoint(x: max(ex, keptX), y: 280))
            ctx.stroke(dim, with: .color(red))
            label(&ctx, "offset \(Offsets.fmt(o)) mm", (ex + keptX) / 2, 296, size: 13, color: red, anchor: .center)
        }
    }
}
