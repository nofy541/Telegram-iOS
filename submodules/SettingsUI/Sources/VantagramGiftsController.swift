import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private let vantagramStarsBonusChoices: [(Int64, String)] = [
    (0, "Нет (настоящий баланс)"),
    (100, "+100 ⭐"),
    (1000, "+1 000 ⭐"),
    (10000, "+10 000 ⭐"),
    (100000, "+100 000 ⭐"),
    (1000000, "+1 000 000 ⭐")
]

private func vantagramStarsBonusTitle(_ value: Int64) -> String {
    for item in vantagramStarsBonusChoices {
        if item.0 == value {
            return item.1
        }
    }
    return "+\(value) ⭐"
}

private final class VantagramGiftsArguments {
    let giftsContext: ProfileGiftsContext
    let openGift: (StarGift.UniqueGift) -> Void
    let loadMore: () -> Void
    let removeLocalGift: (Int) -> Void
    let addLocalGift: () -> Void
    let pickStarsBonus: () -> Void

    init(giftsContext: ProfileGiftsContext, openGift: @escaping (StarGift.UniqueGift) -> Void, loadMore: @escaping () -> Void, removeLocalGift: @escaping (Int) -> Void, addLocalGift: @escaping () -> Void, pickStarsBonus: @escaping () -> Void) {
        self.giftsContext = giftsContext
        self.openGift = openGift
        self.loadMore = loadMore
        self.removeLocalGift = removeLocalGift
        self.addLocalGift = addLocalGift
        self.pickStarsBonus = pickStarsBonus
    }
}

private enum VantagramGiftsEntry: ItemListNodeEntry {
    case header(String)
    case gift(Int32, StarGift.UniqueGift)
    case more
    case footer(String)

    case localHeader
    case localGift(Int32, Int, String, Int64)
    case localAdd
    case localFooter(String)

    case starsHeader
    case starsBonus(String)
    case starsFooter

    var section: ItemListSectionId {
        switch self {
        case .header, .gift, .more, .footer:
            return 0
        case .localHeader, .localGift, .localAdd, .localFooter:
            return 1
        case .starsHeader, .starsBonus, .starsFooter:
            return 2
        }
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .gift(index, _):
            return index + 1
        case .more:
            return 100000
        case .footer:
            return 100001
        case .localHeader:
            return 200000
        case let .localGift(index, _, _, _):
            return 200001 + index
        case .localAdd:
            return 300000
        case .localFooter:
            return 300001
        case .starsHeader:
            return 400000
        case .starsBonus:
            return 400001
        case .starsFooter:
            return 400002
        }
    }

    static func <(lhs: VantagramGiftsEntry, rhs: VantagramGiftsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! VantagramGiftsArguments
        switch self {
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .gift(_, gift):
            var modelName = ""
            var backdropName = ""
            var swatch: UIImage?
            for attribute in gift.attributes {
                switch attribute {
                case let .model(name, _, _, _):
                    modelName = name
                case let .backdrop(name, _, innerColor, outerColor, _, _, _):
                    backdropName = name
                    swatch = vantagramGiftSwatch(innerColor: innerColor, outerColor: outerColor)
                default:
                    break
                }
            }
            var details: [String] = []
            if !modelName.isEmpty {
                details.append(modelName)
            }
            if !backdropName.isEmpty {
                details.append(backdropName)
            }
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "\(gift.title) #\(gift.number)", titleIcon: swatch, label: details.joined(separator: " · "), sectionId: self.section, style: .blocks, action: {
                arguments.openGift(gift)
            })
        case .more:
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: "Загрузить ещё", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.loadMore()
            })
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case .localHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЛОКАЛЬНЫЕ ПОДАРКИ (ТОЛЬКО НА ЭТОМ УСТРОЙСТВЕ)", sectionId: self.section)
        case let .localGift(_, position, title, price):
            let configuration = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .semibold)
            let icon = UIImage(systemName: "gift.fill", withConfiguration: configuration)?.withTintColor(presentationData.theme.list.itemAccentColor, renderingMode: .alwaysOriginal)
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, titleIcon: icon, label: "\(price) ⭐", sectionId: self.section, style: .blocks, action: {
                arguments.removeLocalGift(position)
            })
        case .localAdd:
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: "Подарить себе любой подарок", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.addLocalGift()
            })
        case let .localFooter(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case .starsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЗВЁЗДЫ", sectionId: self.section)
        case let .starsBonus(label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Добавить звёзды к балансу", label: label, sectionId: self.section, style: .blocks, action: {
                arguments.pickStarsBonus()
            })
        case .starsFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Это только отображение на твоём устройстве. Настоящий баланс, покупки и подарки на сервере не меняются, а другие люди этого не видят. Баланс обновится после перезапуска приложения."), sectionId: self.section)
        }
    }
}

/// Rounded swatch painted with the colors of the gift backdrop.
private func vantagramGiftSwatch(innerColor: Int32, outerColor: Int32) -> UIImage? {
    let size = CGSize(width: 28.0, height: 28.0)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let rect = CGRect(origin: CGPoint(), size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: 8.0).addClip()
        let colors = [UIColor(rgb: UInt32(bitPattern: innerColor)).cgColor, UIColor(rgb: UInt32(bitPattern: outerColor)).cgColor]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            context.cgContext.drawRadialGradient(gradient, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: 20.0, options: [.drawsAfterEndLocation])
        }
    }
}

func vantagramGiftsController(context: AccountContext) -> ViewController {
    let giftsContext = ProfileGiftsContext(account: context.account, peerId: context.account.peerId)
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0
    var pushControllerImpl: ((ViewController) -> Void)?

    func changed() {
        counter += 1
        refresh.set(counter)
    }

    let catalogPromise = Promise<[StarGift]?>(nil)
    catalogPromise.set(context.engine.payments.cachedStarGifts())

    let arguments = VantagramGiftsArguments(
        giftsContext: giftsContext,
        openGift: { gift in
            let controller = context.sharedContext.makeGiftViewScreen(context: context, gift: gift, shareStory: nil, openChatTheme: nil, dismissed: nil)
            pushControllerImpl?(controller)
        },
        loadMore: {
            giftsContext.loadMore()
        },
        removeLocalGift: { position in
            var ids = VantagramGhost.localGiftIds
            if position >= 0 && position < ids.count {
                ids.remove(at: position)
                VantagramGhost.setLocalGiftIds(ids)
                changed()
            }
        },
        addLocalGift: {
            let _ = (context.engine.payments.cachedStarGifts()
            |> take(1)
            |> deliverOnMainQueue).start(next: { catalog in
                var options: [VantagramPickerOption] = []
                for item in catalog ?? [] {
                    if case let .generic(gift) = item {
                        options.append(VantagramPickerOption(id: "\(gift.id)", title: "\(gift.title ?? "Подарок") · \(gift.price) ⭐", symbol: "gift.fill"))
                    }
                }
                if options.isEmpty {
                    return
                }
                pushControllerImpl?(vantagramPickerController(
                    context: context,
                    title: "Выбери подарок",
                    header: "КАТАЛОГ ПОДАРКОВ",
                    footer: "Выбранный подарок появится в списке локальных подарков. Нажми на подарок в списке, чтобы убрать его.",
                    options: options,
                    selectedId: "",
                    onSelect: { id in
                        if let value = Int64(id) {
                            var ids = VantagramGhost.localGiftIds
                            ids.append(value)
                            VantagramGhost.setLocalGiftIds(ids)
                            changed()
                        }
                    }
                ))
            })
        },
        pickStarsBonus: {
            var options: [VantagramPickerOption] = []
            for item in vantagramStarsBonusChoices {
                options.append(VantagramPickerOption(id: "\(item.0)", title: item.1, symbol: nil))
            }
            pushControllerImpl?(vantagramPickerController(
                context: context,
                title: "Звёзды",
                header: "ДОБАВИТЬ К БАЛАНСУ",
                footer: "Только отображение на этом устройстве. Применяется после перезапуска приложения.",
                options: options,
                selectedId: "\(VantagramGhost.localStarsBonus)",
                onSelect: { id in
                    if let value = Int64(id) {
                        VantagramGhost.setLocalStarsBonus(value)
                        changed()
                    }
                }
            ))
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        giftsContext.state,
        catalogPromise.get(),
        refresh.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state, catalog, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [VantagramGiftsEntry] = []
        entries.append(.header("МОИ КОЛЛЕКЦИОННЫЕ ПОДАРКИ"))
        var index: Int32 = 0
        for item in state.gifts {
            if case let .unique(gift) = item.gift {
                entries.append(.gift(index, gift))
                index += 1
            }
        }
        var canLoadMore = false
        var isLoading = false
        switch state.dataState {
        case .loading:
            isLoading = true
        case let .ready(more, _):
            canLoadMore = more
        }
        if canLoadMore {
            entries.append(.more)
        }
        let footer: String
        if isLoading && index == 0 {
            footer = "Загружаю подарки…"
        } else if index == 0 {
            footer = "Коллекционных подарков пока нет."
        } else {
            footer = "Цвет значка повторяет фон подарка. Нажми на подарок, чтобы открыть его полностью: модель, узор и фон."
        }
        entries.append(.footer(footer))

        entries.append(.localHeader)
        var catalogById: [Int64: (String, Int64)] = [:]
        for item in catalog ?? [] {
            if case let .generic(gift) = item {
                catalogById[gift.id] = (gift.title ?? "Подарок", gift.price)
            }
        }
        let localIds = VantagramGhost.localGiftIds
        for i in 0 ..< localIds.count {
            let known = catalogById[localIds[i]]
            entries.append(.localGift(Int32(i), i, known?.0 ?? "Подарок #\(localIds[i])", known?.1 ?? 0))
        }
        entries.append(.localAdd)
        entries.append(.localFooter(localIds.isEmpty ? "Ты можешь подарить себе любой подарок из каталога: он появится здесь, но существует только на этом устройстве." : "Эти подарки видны только тебе на этом устройстве. Нажми на подарок, чтобы убрать его."))

        entries.append(.starsHeader)
        entries.append(.starsBonus(vantagramStarsBonusTitle(VantagramGhost.localStarsBonus)))
        entries.append(.starsFooter)

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Витрина подарков"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}
