import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext

/// Avatar sample that is painted with a gradient and shows initials.
private final class VantagramSampleAvatarView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    private let label = UILabel()

    init(letters: String, top: UIColor, bottom: UIColor) {
        super.init(frame: CGRect())
        if let gradient = self.layer as? CAGradientLayer {
            gradient.colors = [top.cgColor, bottom.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        }
        self.clipsToBounds = true
        self.label.text = letters
        self.label.textColor = UIColor.white
        self.label.textAlignment = .center
        self.addSubview(self.label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(size: CGFloat, radiusFactor: CGFloat) {
        self.label.font = UIFont.systemFont(ofSize: floor(size * 0.4), weight: .medium)
        self.label.frame = CGRect(origin: CGPoint(), size: CGSize(width: size, height: size))
        self.layer.cornerRadius = size * radiusFactor
    }
}

private final class VantagramAvatarPreviewView: UIView {
    private static let presets: [CGFloat] = [0.5, 0.3, 0.0]
    private static let palette: [(UIColor, UIColor)] = [
        (UIColor(rgb: 0xFF885E), UIColor(rgb: 0xFF516A)),
        (UIColor(rgb: 0x72D5FD), UIColor(rgb: 0x2A9EF1)),
        (UIColor(rgb: 0xA0DE7E), UIColor(rgb: 0x54CB68)),
        (UIColor(rgb: 0xE0A2F3), UIColor(rgb: 0xD669ED))
    ]

    private let theme: PresentationTheme
    private let scrollView = UIScrollView()
    private let bigAvatars: [VantagramSampleAvatarView]
    private let listCard = UIView()
    private let rowAvatars: [VantagramSampleAvatarView]
    private let rowTitles: [UILabel]
    private let rowSubtitles: [UILabel]
    private let presetControl = UISegmentedControl(items: ["Круг", "Мягкий", "Квадрат"])
    private let valueLabel = UILabel()
    private let slider = UISlider()
    private let hintLabel = UILabel()
    private let restartButton = UIButton(type: .system)

    private var radiusFactor: CGFloat

    init(theme: PresentationTheme) {
        self.theme = theme
        self.radiusFactor = CGFloat(min(0.5, max(0.0, VantagramUI.storedAvatarRadius)))

        let letters = ["АН", "ВК", "ДМ", "ЕЛ"]
        var bigAvatars: [VantagramSampleAvatarView] = []
        for i in 0 ..< 4 {
            bigAvatars.append(VantagramSampleAvatarView(letters: letters[i], top: VantagramAvatarPreviewView.palette[i].0, bottom: VantagramAvatarPreviewView.palette[i].1))
        }
        self.bigAvatars = bigAvatars

        let names = ["Анна", "Команда", "Дмитрий"]
        let texts = ["Привет! Как дела?", "Встреча в 19:00", "Фото отправлено"]
        var rowAvatars: [VantagramSampleAvatarView] = []
        var rowTitles: [UILabel] = []
        var rowSubtitles: [UILabel] = []
        for i in 0 ..< 3 {
            rowAvatars.append(VantagramSampleAvatarView(letters: String(names[i].prefix(1)), top: VantagramAvatarPreviewView.palette[(i + 1) % 4].0, bottom: VantagramAvatarPreviewView.palette[(i + 1) % 4].1))
            let title = UILabel()
            title.text = names[i]
            title.textColor = theme.list.itemPrimaryTextColor
            title.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
            rowTitles.append(title)
            let subtitle = UILabel()
            subtitle.text = texts[i]
            subtitle.textColor = theme.list.itemSecondaryTextColor
            subtitle.font = UIFont.systemFont(ofSize: 15.0)
            rowSubtitles.append(subtitle)
        }
        self.rowAvatars = rowAvatars
        self.rowTitles = rowTitles
        self.rowSubtitles = rowSubtitles

        super.init(frame: CGRect())

        self.addSubview(self.scrollView)
        for avatar in self.bigAvatars {
            self.scrollView.addSubview(avatar)
        }
        self.listCard.backgroundColor = theme.list.itemBlocksBackgroundColor
        self.listCard.layer.cornerRadius = 12.0
        self.scrollView.addSubview(self.listCard)
        for i in 0 ..< 3 {
            self.listCard.addSubview(self.rowAvatars[i])
            self.listCard.addSubview(self.rowTitles[i])
            self.listCard.addSubview(self.rowSubtitles[i])
        }

        self.presetControl.addTarget(self, action: #selector(self.presetChanged), for: .valueChanged)
        self.scrollView.addSubview(self.presetControl)

        self.valueLabel.textColor = theme.list.itemPrimaryTextColor
        self.valueLabel.font = UIFont.systemFont(ofSize: 15.0)
        self.scrollView.addSubview(self.valueLabel)

        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 0.5
        self.slider.minimumTrackTintColor = theme.list.itemAccentColor
        self.slider.addTarget(self, action: #selector(self.sliderChanged), for: .valueChanged)
        self.scrollView.addSubview(self.slider)

        self.hintLabel.numberOfLines = 0
        self.hintLabel.textColor = theme.list.freeTextColor
        self.hintLabel.font = UIFont.systemFont(ofSize: 13.0)
        self.hintLabel.text = "Сверху пример аватарок и список чатов: форма меняется сразу, пока двигаешь ползунок. В самом приложении аватарки изменятся после перезапуска."
        self.scrollView.addSubview(self.hintLabel)

        self.restartButton.setTitle("Перезапустить и применить", for: .normal)
        self.restartButton.setTitleColor(theme.list.itemAccentColor, for: .normal)
        self.restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        self.restartButton.addTarget(self, action: #selector(self.restartPressed), for: .touchUpInside)
        self.scrollView.addSubview(self.restartButton)

        self.apply(radiusFactor: self.radiusFactor, fromSlider: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func presetChanged() {
        let index = self.presetControl.selectedSegmentIndex
        if index >= 0 && index < VantagramAvatarPreviewView.presets.count {
            self.apply(radiusFactor: VantagramAvatarPreviewView.presets[index], fromSlider: false)
        }
    }

    @objc private func sliderChanged() {
        self.apply(radiusFactor: CGFloat(self.slider.value), fromSlider: true)
    }

    @objc private func restartPressed() {
        vantagramRestartApp()
    }

    private func apply(radiusFactor: CGFloat, fromSlider: Bool) {
        self.radiusFactor = radiusFactor
        VantagramUI.setDesignDouble("avatarRadius", Double(radiusFactor))

        if !fromSlider {
            self.slider.value = Float(radiusFactor)
        }
        self.valueLabel.text = "Закругление: \(Int((radiusFactor / 0.5 * 100.0).rounded()))%"

        var selected = UISegmentedControl.noSegment
        for i in 0 ..< VantagramAvatarPreviewView.presets.count {
            if abs(VantagramAvatarPreviewView.presets[i] - radiusFactor) < 0.01 {
                selected = i
            }
        }
        self.presetControl.selectedSegmentIndex = selected

        self.setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.scrollView.frame = self.bounds
        let width = self.bounds.width
        let inset: CGFloat = 16.0
        var y: CGFloat = 20.0

        let bigSize: CGFloat = 64.0
        let gap = max(8.0, (width - inset * 2.0 - bigSize * 4.0) / 3.0)
        for i in 0 ..< self.bigAvatars.count {
            let avatar = self.bigAvatars[i]
            avatar.frame = CGRect(x: inset + CGFloat(i) * (bigSize + gap), y: y, width: bigSize, height: bigSize)
            avatar.update(size: bigSize, radiusFactor: self.radiusFactor)
        }
        y += bigSize + 24.0

        let rowHeight: CGFloat = 64.0
        self.listCard.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: rowHeight * 3.0)
        let rowAvatarSize: CGFloat = 46.0
        for i in 0 ..< 3 {
            let top = CGFloat(i) * rowHeight
            self.rowAvatars[i].frame = CGRect(x: 12.0, y: top + floor((rowHeight - rowAvatarSize) / 2.0), width: rowAvatarSize, height: rowAvatarSize)
            self.rowAvatars[i].update(size: rowAvatarSize, radiusFactor: self.radiusFactor)
            let textX = 12.0 + rowAvatarSize + 12.0
            let textWidth = max(0.0, self.listCard.bounds.width - textX - 12.0)
            self.rowTitles[i].frame = CGRect(x: textX, y: top + 11.0, width: textWidth, height: 20.0)
            self.rowSubtitles[i].frame = CGRect(x: textX, y: top + 33.0, width: textWidth, height: 20.0)
        }
        y += rowHeight * 3.0 + 24.0

        self.presetControl.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: 32.0)
        y += 32.0 + 20.0

        self.valueLabel.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: 20.0)
        y += 24.0
        self.slider.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: 32.0)
        y += 32.0 + 16.0

        let hintSize = self.hintLabel.sizeThatFits(CGSize(width: width - inset * 2.0, height: CGFloat.greatestFiniteMagnitude))
        self.hintLabel.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: hintSize.height)
        y += hintSize.height + 20.0

        self.restartButton.frame = CGRect(x: inset, y: y, width: width - inset * 2.0, height: 44.0)
        y += 44.0 + 40.0

        self.scrollView.contentSize = CGSize(width: width, height: y)
    }
}

private final class VantagramAvatarPreviewNode: ASDisplayNode {
    private let presentationData: PresentationData
    private var contentView: VantagramAvatarPreviewView?

    init(presentationData: PresentationData) {
        self.presentationData = presentationData

        super.init()

        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
    }

    override func didLoad() {
        super.didLoad()

        let view = VantagramAvatarPreviewView(theme: self.presentationData.theme)
        self.view.addSubview(view)
        self.contentView = view
    }

    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat) {
        let top = navigationBarHeight
        self.contentView?.frame = CGRect(x: 0.0, y: top, width: layout.size.width, height: max(0.0, layout.size.height - top))
    }
}

final class VantagramAvatarPreviewController: ViewController {
    private let context: AccountContext
    private let presentationData: PresentationData

    private var controllerNode: VantagramAvatarPreviewNode {
        return self.displayNode as! VantagramAvatarPreviewNode
    }

    init(context: AccountContext) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }

        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings, style: .glass))
        self._hasGlassStyle = true

        self.navigationItem.title = "Аватарки"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadDisplayNode() {
        super.loadDisplayNode()

        self.displayNode = VantagramAvatarPreviewNode(presentationData: self.presentationData)
        self.displayNodeDidLoad()
    }

    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)

        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY)
    }
}
