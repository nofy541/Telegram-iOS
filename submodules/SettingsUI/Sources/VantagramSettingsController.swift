import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

private final class VantagramSettingsArguments {
    let updateHideRead: (Bool) -> Void
    let updateHideTyping: (Bool) -> Void
    let updateHideOnline: (Bool) -> Void

    init(
        updateHideRead: @escaping (Bool) -> Void,
        updateHideTyping: @escaping (Bool) -> Void,
        updateHideOnline: @escaping (Bool) -> Void
    ) {
        self.updateHideRead = updateHideRead
        self.updateHideTyping = updateHideTyping
        self.updateHideOnline = updateHideOnline
    }
}

private struct VantagramSettingsState: Equatable {
    var hideRead: Bool
    var hideTyping: Bool
    var hideOnline: Bool

    static func load() -> VantagramSettingsState {
        return VantagramSettingsState(
            hideRead: VantagramGhost.hideRead,
            hideTyping: VantagramGhost.hideTyping,
            hideOnline: VantagramGhost.hideOnline
        )
    }
}

private enum VantagramSettingsSection: Int32 {
    case ghost
}

private enum VantagramSettingsEntry: ItemListNodeEntry {
    case ghostHeader
    case hideRead(Bool)
    case hideTyping(Bool)
    case hideOnline(Bool)
    case ghostFooter

    var section: ItemListSectionId {
        return VantagramSettingsSection.ghost.rawValue
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
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ты читаешь сообщения, но собеседник не видит галочки прочтения, набор текста и твой онлайн."), sectionId: self.section)
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
