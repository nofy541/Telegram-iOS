import Foundation
import UIKit

/// Settings row icon for the Vantagram section: the "V" logo (white left half, blue right half)
/// on a dark rounded square. Drawn in code so it does not depend on bundled assets.
func vantagramSettingsIcon() -> UIImage? {
    let size = CGSize(width: 29.0, height: 29.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let cgContext = context.cgContext
        let bounds = CGRect(origin: CGPoint(), size: size)

        let background = UIBezierPath(roundedRect: bounds, cornerRadius: 7.0)
        cgContext.setFillColor(UIColor(red: 14.0 / 255.0, green: 18.0 / 255.0, blue: 26.0 / 255.0, alpha: 1.0).cgColor)
        cgContext.addPath(background.cgPath)
        cgContext.fillPath()

        // Logo geometry from the 640x640 source (bounding box x: 182...459, y: 202...459).
        let scale: CGFloat = 17.0 / 277.0
        let centerX: CGFloat = 320.5
        let centerY: CGFloat = 330.5
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            return CGPoint(x: size.width / 2.0 + (x - centerX) * scale, y: size.height / 2.0 + (y - centerY) * scale)
        }

        let leftPiece = UIBezierPath()
        leftPiece.move(to: point(182.0, 202.0))
        leftPiece.addLine(to: point(263.0, 202.0))
        leftPiece.addLine(to: point(314.0, 318.0))
        leftPiece.addLine(to: point(314.0, 459.0))
        leftPiece.close()
        cgContext.setFillColor(UIColor(red: 245.0 / 255.0, green: 248.0 / 255.0, blue: 252.0 / 255.0, alpha: 1.0).cgColor)
        cgContext.addPath(leftPiece.cgPath)
        cgContext.fillPath()

        let rightPiece = UIBezierPath()
        rightPiece.move(to: point(378.0, 202.0))
        rightPiece.addLine(to: point(459.0, 202.0))
        rightPiece.addLine(to: point(326.0, 459.0))
        rightPiece.addLine(to: point(326.0, 318.0))
        rightPiece.close()
        cgContext.setFillColor(UIColor(red: 110.0 / 255.0, green: 168.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0).cgColor)
        cgContext.addPath(rightPiece.cgPath)
        cgContext.fillPath()
    }
}
