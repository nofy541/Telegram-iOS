import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private let vantagramAnimationSpeeds: [Double] = [0.35, 0.6, 1.0, 1.6, 2.5]

private func vantagramAnimationSpeedTitle(_ factor: Double) -> String {
    if factor <= 0.4 {
        return "Очень быстро"
    } else if factor <= 0.7 {
        return "Быстро"
    } else if factor < 1.3 {
        return "Обычно"
    } else if factor < 2.0 {
        return "Медленно"
    } else {
        return "Очень медленно"
    }
}

private func vantagramNextAnimationSpeed(_ factor: Double) -> Double {
    var closestIndex = 0
    var closestDistance = Double.greatestFiniteMagnitude
    for i in 0 ..< vantagramAnimationSpeeds.count {
        let distance = abs(vantagramAnimationSpeeds[i] - factor)
        if distance < closestDistance {
            closestDistance = distance
            closestIndex = i
        }
    }
    return vantagramAnimationSpeeds[(closestIndex + 1) % vantagramAnimationSpeeds.count]
}

private final class VantagramSettingsArguments {
    let updateHideRead: (Bool) -> Void
    let updateHideTyping: (Bool) -> Void
    let updateHideOnline: (Bool) -> Void
    let updateKeepDeleted: (Bool) -> Void
    let updateHideAds: (Bool) -> Void
    let cycleAnimationSpeed: () -> Void
    let updateNotchBadge: (Bool) -> Void
    let updateHidePremium: (Bool) -> Void

    init(
        updateHideRead: @escaping (Bool) -> Void,
        updateHideTyping: @escaping (Bool) -> Void,
        updateHideOnline: @escaping (Bool) -> Void,
        updateKeepDeleted: @escaping (Bool) -> Void,
        updateHideAds: @escaping (Bool) -> Void,
        cycleAnimationSpeed: @escaping () -> Void,
        updateNotchBadge: @escaping (Bool) -> Void,
        updateHidePremium: @escaping (Bool) -> Void
    ) {
        self.updateHideRead = updateHideRead
        self.updateHideTyping = updateHideTyping
        self.updateHideOnline = updateHideOnline
        self.updateKeepDeleted = updateKeepDeleted
        self.updateHideAds = updateHideAds
        self.cycleAnimationSpeed = cycleAnimationSpeed
        self.updateNotchBadge = updateNotchBadge
        self.updateHidePremium = updateHidePremium
    }
}

private struct VantagramSettingsState: Equatable {
    var hideRead: Bool
    var hideTyping: Bool
    var hideOnline: Bool
    var keepDeleted: Bool
    var hideAds: Bool
    var animationFactor: Double
    var notchBadge: Bool
    var hidePremium: Bool

    static func load() -> VantagramSettingsState {
        return VantagramSettingsState(
            hideRead: VantagramGhost.hideRead,
            hideTyping: VantagramGhost.hideTyping,
            hideOnline: VantagramGhost.hideOnline,
            keepDeleted: VantagramGhost.keepDeleted,
            hideAds: VantagramGhost.hideAds,
            animationFactor: VantagramAnimation.factor,
            notchBadge: VantagramGhost.notchBadge,
            hidePremium: VantagramGhost.hidePremium
        )
    }
}

private enum VantagramSettingsSection: Int32 {
    case ghost
    case archive
    case interface
    case misc
}

private enum VantagramSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case hideRead(Bool)
    case hideTyping(Bool)
    case hideOnline(Bool)
    case ghostFooter

    case archiveHeader
    case keepDeleted(Bool)
    case archiveFooter

    case interfaceHeader
    case animationSpeed(Double)
    case notchBadge(Bool)
    case interfaceFooter

    case miscHeader
    case hideAds(Bool)
    case hidePremium(Bool)

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .hideRead, .hideTyping, .hideOnline, .ghostFooter:
            return VantagramSettingsSection.ghost.rawValue
        case .archiveHeader, .keepDeleted, .archiveFooter:
            return VantagramSettingsSection.archive.rawValue
        case .interfaceHeader, .animationSpeed, .notchBadge, .interfaceFooter:
            return VantagramSettingsSection.interface.rawValue
        case .miscHeader, .hideAds, .hidePremium:
            return VantagramSettingsSection.misc.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader:
            return 0
        case .hideRead:
            return 1
        case .hideTyping:
            return 2
        case .hideOnline:
            return 3
        case .ghostFooter:
            return 4
        case .archiveHeader:
            return 5
        case .keepDeleted:
            return 6
        case .archiveFooter:
            return 7
        case .interfaceHeader:
            return 8
        case .animationSpeed:
            return 9
        case .notchBadge:
            return 10
        case .interfaceFooter:
            return 11
        case .miscHeader:
            return 12
        case .hideAds:
            return 13
        case .hidePremium:
            return 14
        }
    }

    static func <(lhs: VantagramSettingsEntry, rhs: VantagramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! VantagramSettingsArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST MODE", sectionId: self.section)
        case let .hideRead(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Не отмечать прочитанным", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideRead(value)
            })
        case let .hideTyping(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрывать «печатает…»", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideTyping(value)
            })
        case let .hideOnline(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрывать онлайн", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideOnline(value)
            })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ты читаешь сообщения, слушаешь голосовые и смотришь истории, а собеседник не видит галочки прочтения, набор текста и твой онлайн."), sectionId: self.section)
        case .archiveHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "АРХИВ", sectionId: self.section)
        case let .keepDeleted(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Сохранять удалённые сообщения", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateKeepDeleted(value)
            })
        case .archiveFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Если собеседник удалит сообщение, оно останется у тебя в чате с пометкой «удалено». Работает для удалений, пришедших, пока приложение запущено."), sectionId: self.section)
        case .interfaceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ИНТЕРФЕЙС", sectionId: self.section)
        case let .animationSpeed(factor):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Скорость анимаций", label: vantagramAnimationSpeedTitle(factor), sectionId: self.section, style: .blocks, action: {
                arguments.cycleAnimationSpeed()
            })
        case let .notchBadge(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Логотип под вырезом", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateNotchBadge(value)
            })
        case .interfaceFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Нажми на «Скорость анимаций», чтобы переключить. Логотип под вырезом обычно не виден, но попадает на скриншоты и запись экрана."), sectionId: self.section)
        case .miscHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ПРОЧЕЕ", sectionId: self.section)
        case let .hideAds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрывать рекламу в каналах", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideAds(value)
            })
        case let .hidePremium(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрывать предложения Premium", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHidePremium(value)
            })
        }
    }
}

private func vantagramSettingsEntries(state: VantagramSettingsState) -> [VantagramSettingsEntry] {
    var entries: [VantagramSettingsEntry] = []
    entries.append(.ghostHeader)
    entries.append(.hideRead(state.hideRead))
    entries.append(.hideTyping(state.hideTyping))
    entries.append(.hideOnline(state.hideOnline))
    entries.append(.ghostFooter)
    entries.append(.archiveHeader)
    entries.append(.keepDeleted(state.keepDeleted))
    entries.append(.archiveFooter)
    entries.append(.interfaceHeader)
    entries.append(.animationSpeed(state.animationFactor))
    entries.append(.notchBadge(state.notchBadge))
    entries.append(.interfaceFooter)
    entries.append(.miscHeader)
    entries.append(.hideAds(state.hideAds))
    entries.append(.hidePremium(state.hidePremium))
    return entries
}

public func vantagramSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(VantagramSettingsState.load(), ignoreRepeated: true)

    let arguments = VantagramSettingsArguments(
        updateHideRead: { value in
            VantagramGhost.setHideRead(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHideTyping: { value in
            VantagramGhost.setHideTyping(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHideOnline: { value in
            VantagramGhost.setHideOnline(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateKeepDeleted: { value in
            VantagramGhost.setKeepDeleted(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHideAds: { value in
            VantagramGhost.setHideAds(value)
            statePromise.set(VantagramSettingsState.load())
        },
        cycleAnimationSpeed: {
            VantagramAnimation.setFactor(vantagramNextAnimationSpeed(VantagramAnimation.factor))
            statePromise.set(VantagramSettingsState.load())
        },
        updateNotchBadge: { value in
            VantagramGhost.setNotchBadge(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHidePremium: { value in
            VantagramGhost.setHidePremium(value)
            statePromise.set(VantagramSettingsState.load())
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Vantagram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: vantagramSettingsEntries(state: state), style: .blocks, animateChanges: true)

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
