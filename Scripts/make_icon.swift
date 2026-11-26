// Uygulama ikonunu çizer: swiftc Scripts/make_icon.swift -o build/make_icon && build/make_icon out.png
import AppKit

let S: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor { CGColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: a) }
func rr(_ r: CGRect, _ rad: CGFloat) -> CGPath { CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil) }
let all: CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsAfterEndLocation]

// gövde
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: c(0, 0, 0, 0.35))
ctx.addPath(rr(body, 185)); ctx.setFillColor(c(30, 90, 200)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState(); ctx.addPath(rr(body, 185)); ctx.clip()
let g = CGGradient(colorsSpace: cs, colors: [c(90, 170, 255), c(40, 110, 230), c(28, 70, 180)] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(g, start: CGPoint(x: 300, y: 924), end: CGPoint(x: 724, y: 100), options: all)
let gloss = CGGradient(colorsSpace: cs, colors: [c(255, 255, 255, 0.18), c(255, 255, 255, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gloss, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 560), options: [])
ctx.restoreGState()

// belge (kıvrık köşeli)
let dw: CGFloat = 420, dh: CGFloat = 540, fold: CGFloat = 120
let dx = (S - dw) / 2 - 30, dy: CGFloat = 220
let doc = CGMutablePath()
doc.move(to: CGPoint(x: dx + 40, y: dy))
doc.addLine(to: CGPoint(x: dx + dw - 40, y: dy))
doc.addQuadCurve(to: CGPoint(x: dx + dw, y: dy + 40), control: CGPoint(x: dx + dw, y: dy))
doc.addLine(to: CGPoint(x: dx + dw, y: dy + dh - fold))
doc.addLine(to: CGPoint(x: dx + dw - fold, y: dy + dh))
doc.addLine(to: CGPoint(x: dx + 40, y: dy + dh))
doc.addQuadCurve(to: CGPoint(x: dx, y: dy + dh - 40), control: CGPoint(x: dx, y: dy + dh))
doc.addLine(to: CGPoint(x: dx, y: dy + 40))
doc.addQuadCurve(to: CGPoint(x: dx + 40, y: dy), control: CGPoint(x: dx, y: dy))
doc.closeSubpath()
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: c(0, 20, 80, 0.4))
ctx.addPath(doc); ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()
ctx.restoreGState()
// kıvrık köşe
let f = CGMutablePath()
f.move(to: CGPoint(x: dx + dw, y: dy + dh - fold))
f.addLine(to: CGPoint(x: dx + dw - fold + 22, y: dy + dh - fold))
f.addQuadCurve(to: CGPoint(x: dx + dw - fold, y: dy + dh - fold + 22), control: CGPoint(x: dx + dw - fold, y: dy + dh - fold))
f.addLine(to: CGPoint(x: dx + dw - fold, y: dy + dh))
f.closeSubpath()
ctx.addPath(f); ctx.setFillColor(c(200, 215, 240)); ctx.fillPath()
// satırlar
for (i, w) in [CGFloat(280), 300, 240, 290, 180].enumerated() {
    let y = dy + dh - 190 - CGFloat(i) * 62
    ctx.addPath(rr(CGRect(x: dx + 60, y: y, width: w, height: 26), 13))
    ctx.setFillColor(c(190, 205, 230)); ctx.fillPath()
}

// + rozeti
let r: CGFloat = 150, bc = CGPoint(x: dx + dw + 10, y: dy + 70)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: c(0, 0, 0, 0.3))
ctx.addEllipse(in: CGRect(x: bc.x - r, y: bc.y - r, width: 2 * r, height: 2 * r))
ctx.setFillColor(c(255, 255, 255)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: bc.x - r + 18, y: bc.y - r + 18, width: 2 * r - 36, height: 2 * r - 36)); ctx.clip()
let gg = CGGradient(colorsSpace: cs, colors: [c(70, 215, 120), c(20, 160, 90)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gg, start: CGPoint(x: bc.x, y: bc.y + r), end: CGPoint(x: bc.x, y: bc.y - r), options: all)
ctx.restoreGState()
let pw: CGFloat = 36, pl: CGFloat = 150
ctx.setFillColor(c(255, 255, 255))
ctx.addPath(rr(CGRect(x: bc.x - pl/2, y: bc.y - pw/2, width: pl, height: pw), pw/2)); ctx.fillPath()
ctx.addPath(rr(CGRect(x: bc.x - pw/2, y: bc.y - pl/2, width: pw, height: pl), pw/2)); ctx.fillPath()

let img = ctx.makeImage()!
try! NSBitmapImageRep(cgImage: img).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("yazıldı: \(out)")
