import Cocoa
import CoreGraphics

func generateAppIcon() {
    let size: CGFloat = 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create CGContext")
        return
    }
    
    // Draw macOS Squircle rounded rect
    let iconRect = CGRect(x: 64, y: 64, width: size - 128, height: size - 128)
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: 196, cornerHeight: 196, transform: nil)
    
    context.saveGState()
    context.addPath(squirclePath)
    context.clip()
    
    // Base dark gradient
    let bgColors = [
        NSColor(red: 0.08, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    context.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 960), end: CGPoint(x: 512, y: 64), options: [])
    
    // Subtle outer border highlight
    context.restoreGState()
    context.saveGState()
    context.addPath(squirclePath)
    context.setStrokeColor(NSColor(red: 0.25, green: 0.35, blue: 0.55, alpha: 0.6).cgColor)
    context.setLineWidth(10)
    context.strokePath()
    context.restoreGState()
    
    // Draw 2x2 Grid inside
    let gridBounds = iconRect.insetBy(dx: 100, dy: 100)
    let gap: CGFloat = 24
    let cellW = (gridBounds.width - gap) / 2
    let cellH = (gridBounds.height - gap) / 2
    
    // 4 Cells
    let cellRects = [
        CGRect(x: gridBounds.minX, y: gridBounds.minY + cellH + gap, width: cellW, height: cellH), // Top-Left
        CGRect(x: gridBounds.minX + cellW + gap, y: gridBounds.minY + cellH + gap, width: cellW, height: cellH), // Top-Right
        CGRect(x: gridBounds.minX, y: gridBounds.minY, width: cellW, height: cellH), // Bottom-Left
        CGRect(x: gridBounds.minX + cellW + gap, y: gridBounds.minY, width: cellW, height: cellH)  // Bottom-Right
    ]
    
    // Draw Top-Left Cell: Glowing Active Cell
    let activeCell = cellRects[0]
    let activePath = CGPath(roundedRect: activeCell, cornerWidth: 28, cornerHeight: 28, transform: nil)
    context.saveGState()
    context.addPath(activePath)
    context.setFillColor(NSColor(red: 0.10, green: 0.16, blue: 0.28, alpha: 1.0).cgColor)
    context.fillPath()
    context.addPath(activePath)
    context.setStrokeColor(NSColor(red: 0.15, green: 0.65, blue: 1.0, alpha: 0.9).cgColor)
    context.setLineWidth(8)
    context.strokePath()
    
    // Draw prompt `> _` in Top-Left
    let promptFont = NSFont.monospacedSystemFont(ofSize: 110, weight: .bold)
    let promptAttrs: [NSAttributedString.Key: Any] = [
        .font: promptFont,
        .foregroundColor: NSColor(red: 0.20, green: 0.85, blue: 1.0, alpha: 1.0)
    ]
    let promptStr = NSAttributedString(string: ">_", attributes: promptAttrs)
    let promptLine = CTLineCreateWithAttributedString(promptStr)
    context.textPosition = CGPoint(x: activeCell.minX + 40, y: activeCell.minY + 95)
    CTLineDraw(promptLine, context)
    context.restoreGState()
    
    // Draw other 3 cells with subtle code lines
    for i in 1..<4 {
        let cell = cellRects[i]
        let cellPath = CGPath(roundedRect: cell, cornerWidth: 28, cornerHeight: 28, transform: nil)
        context.saveGState()
        context.addPath(cellPath)
        context.setFillColor(NSColor(red: 0.08, green: 0.09, blue: 0.13, alpha: 0.9).cgColor)
        context.fillPath()
        context.addPath(cellPath)
        context.setStrokeColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
        context.setLineWidth(4)
        context.strokePath()
        
        // Draw simulated code lines
        let lineColors = [
            NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.5),
            NSColor(white: 0.6, alpha: 0.4),
            NSColor(white: 0.4, alpha: 0.3)
        ]
        let widths: [CGFloat] = [cellW * 0.65, cellW * 0.45, cellW * 0.55]
        for l in 0..<3 {
            let lineY = cell.maxY - 70 - CGFloat(l * 40)
            let lineRect = CGRect(x: cell.minX + 35, y: lineY, width: widths[l], height: 12)
            let linePath = CGPath(roundedRect: lineRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
            context.addPath(linePath)
            context.setFillColor(lineColors[l].cgColor)
            context.fillPath()
        }
        context.restoreGState()
    }
    
    guard let cgImage = context.makeImage() else {
        print("Failed to make CGImage")
        return
    }
    
    // Create AppIcon.iconset folder
    let fm = FileManager.default
    let iconsetDir = "AppIcon.iconset"
    try? fm.removeItem(atPath: iconsetDir)
    try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
    
    let sizes: [(Int, Int, String)] = [
        (16, 1, "icon_16x16.png"),
        (16, 2, "icon_16x16@2x.png"),
        (32, 1, "icon_32x32.png"),
        (32, 2, "icon_32x32@2x.png"),
        (128, 1, "icon_128x128.png"),
        (128, 2, "icon_128x128@2x.png"),
        (256, 1, "icon_256x256.png"),
        (256, 2, "icon_256x256@2x.png"),
        (512, 1, "icon_512x512.png"),
        (512, 2, "icon_512x512@2x.png")
    ]
    
    for (ptSize, scale, filename) in sizes {
        let pixelSize = ptSize * scale
        guard let resizedContext = CGContext(
            data: nil,
            width: pixelSize,
            height: pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { continue }
        
        resizedContext.interpolationQuality = .high
        resizedContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        if let resizedImage = resizedContext.makeImage() {
            let rep = NSBitmapImageRep(cgImage: resizedImage)
            if let pngData = rep.representation(using: .png, properties: [:]) {
                let outURL = URL(fileURLWithPath: "\(iconsetDir)/\(filename)")
                try? pngData.write(to: outURL)
            }
        }
    }
    
    print("Iconset generated successfully!")
}

generateAppIcon()
