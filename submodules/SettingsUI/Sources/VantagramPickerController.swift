import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext

struct VantagramPickerOption {
    let id: String
    let title: String
    let symbol: String?
}

private final class VantagramPickerArguments {
    let select: (String) -> Void

    init(select: @escaping (String) -> Void) {
        self.select = select
    }
}

private enum VantagramPickerEntry: ItemListNodeEntry {
    case header(String)
    case option(Int32, String, String, String?, Bool)
    case footer(String)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case .header:
            return 0
        case let .option(index, _, _, _, _):
            return index + 1
        case .footer:
            return 10000
        }
    }

    static func <(lhs: VantagramPickerEntry, rhs: VantagramPickerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! VantagramPickerArguments
        switch self {
        case let .header(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .option(_, id, title, symbol, checked):
            var iconImage: UIImage?
            if let symbol = symbol {
                let configuration = UIImage.SymbolConfiguration(pointSize: 20.0, weight: .semibold)
                iconImage = UIImage(systemName: symbol, withConfiguration: configuration)?.withTintColor(presentationData.theme.list.itemPrimaryTextColor, renderingMode: .alwaysOriginal)
            }
            return ItemListCheckboxItem(presentationData: presentationData, systemStyle: .glass, icon: iconImage, iconSize: iconImage == nil ? nil : CGSize(width: 28.0, height: 28.0), title: title, style: .left, checked: checked, zeroSeparatorInsets: false, sectionId: self.section, action: {
                arguments.select(id)
            })
        case let .footer(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

func vantagramPickerController(context: AccountContext, title: String, header: String, footer: String, options: [VantagramPickerOption], selectedId: String, onSelect: @escaping (String) -> Void) -> ViewController {
    let selectedPromise = ValuePromise(selectedId, ignoreRepeated: true)

    let arguments = VantagramPickerArguments(select: { id in
        onSelect(id)
        selectedPromise.set(id)
    })

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        selectedPromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, selected -> (ItemListControllerState, (ItemListNodeState, Any)) in
        var entries: [VantagramPickerEntry] = []
        entries.append(.header(header))
        for i in 0 ..< options.count {
            let option = options[i]
            entries.append(.option(Int32(i), option.id, option.title, option.symbol, option.id == selected))
        }
        entries.append(.footer(footer))

        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
