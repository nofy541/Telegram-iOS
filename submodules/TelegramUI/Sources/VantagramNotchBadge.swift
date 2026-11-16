import Foundation
import UIKit
import TelegramCore

/// Vantagram easter egg: a small "V" logo placed exactly under the Dynamic Island / notch.
/// It is normally hidden by the cutout, but shows up in screenshots, screen recordings
/// and during the app minimize animation.
private final class VantagramNotchWindow: UIWindow {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}

private func vantagramNotchLogo() -> UIImage {
    let size = CGSize(width: 24.0, height: 22.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let cgContext = context.cgContext
        let scale: CGFloat = 22.0 / 257.0
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

enum VantagramNotchBadge {
    private static var window: UIWindow?
    private static var isInstalled = false

    /// Starts listening for app activation and for the settings switch.
    static func install() {
        if isInstalled {
            return
        }
        isInstalled = true
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: { _ in
            refresh()
        })
        NotificationCenter.default.addObserver(forName: Notification.Name("vantagram.notchBadge.changed"), object: nil, queue: .main, using: { _ in
            refresh()
        })
    }

    private static func refresh() {
        if VantagramGhost.notchBadge {
            show()
        } else {
            window?.isHidden = true
            window = nil
        }
    }

    private static func show() {
        if window != nil {
            return
        }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return
        }
        let overlay = VantagramNotchWindow(windowScene: scene)
        overlay.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1000.0)
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false

        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        overlay.rootViewController = controller

        let imageView = UIImageView(image: vantagramNotchLogo())
        imageView.isUserInteractionEnabled = false
        let imageSize = CGSize(width: 24.0, height: 22.0)
        // The Dynamic Island pill is about 37pt tall and starts around 11pt from the top edge.
        imageView.frame = CGRect(x: floor((overlay.bounds.width - imageSize.width) / 2.0), y: 29.5 - imageSize.height / 2.0, width: imageSize.width, height: imageSize.height)
        imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        controller.view.addSubview(imageView)

        overlay.isHidden = false
        window = overlay
    }
}
