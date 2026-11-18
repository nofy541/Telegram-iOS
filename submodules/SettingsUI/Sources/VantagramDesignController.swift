import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import PresentationDataUtils
import AccountContext

private let vantagramAvatarRadiusChoices: [(Double, String)] = [
    (0.5, "Круг"),
    (0.35, "Мягкий скруглённый квадрат"),
    (0.25, "Скруглённый квадрат"),
    (0.12, "Почти квадрат"),
    (0.0, "Квадрат")
]

private let vantagramBubbleRadiusChoices: [(Double, String)] = [
    (-1.0, "Как в теме"),
    (0.0, "Острые углы"),
    (6.0, "6"),
    (10.0, "10"),
    (14.0, "14"),
    (18.0, "18"),
    (22.0, "22")
]

private let vantagramMessageFontChoices: [(String, String)] = [
    ("inherit", "Как у интерфейса"),
    ("default", "Системный"),
    ("rounded", "Скруглённый"),
    ("serif", "С засечками"),
    ("monospaced", "Моноширинный")
]

private let vantagramInterfaceFontChoices: [(String, String)] = [
    ("default", "Системный"),
    ("rounded", "Скруглённый"),
    ("serif", "С засечками"),
    ("monospaced", "Моноширинный")
]

private let vantagramListAvatarChoices: [(Double, String)] = [
    (1.0, "100%"),
    (0.85, "85%"),
    (0.7, "70%")
]

private let vantagramDoubleTapChoices: [(String, String)] = [
    ("reaction", "Реакция (как в Telegram)"),
    ("reply", "Ответить"),
    ("copy", "Копировать текст"),
    ("none", "Ничего")
]

private let vantagramListRowChoices: [(Double, String)] = [
    (11.0, "Свободная"),
    (8.0, "Обычная"),
    (6.0, "Плотная"),
    (4.0, "Очень плотная")
]

private func vantagramNearestTitle(_ choices: [(Double, String)], _ value: Double) -> String {
    var best = choices[0]
    for item in choices {
        if abs(item.0 - value) < abs(best.0 - value) {
            best = item
        }
    }
    return best.1
}

private func vantagramNearestId(_ choices: [(Double, String)], _ value: Double) -> String {
    var best = choices[0]
    for item in choices {
        if abs(item.0 - value) < abs(best.0 - value) {
            best = item
        }
    }
    return "\(best.0)"
}

private func vantagramStringTitle(_ choices: [(String, String)], _ id: String) -> String {
    for item in choices {
        if item.0 == id {
            return item.1
        }
    }
    return choices[0].1
}

private final class VantagramDesignArguments {
    let tap: (String) -> Void
    let toggle: (String, Bool) -> Void

    init(tap: @escaping (String) -> Void, toggle: @escaping (String, Bool) -> Void) {
        self.tap = tap
        self.toggle = toggle
    }
}

private enum VantagramDesignEntry: ItemListNodeEntry {
    case header(Int32, Int32, String)
    case link(Int32, Int32, String, String, String)
    case toggle(Int32, Int32, String, String, Bool)
    case action(Int32, Int32, String, String)
    case footer(Int32, Int32, String)

    var section: ItemListSectionId {
        switch self {
        case let .header(_, section, _):
            return section
        case let .link(_, section, _, _, _):
            return section
        case let .toggle(_, section, _, _, _):
            return section
        case let .action(_, section, _, _):
            return section
        case let .footer(_, section, _):
            return section
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(index, _, _):
            return index
        case let .link(index, _, _, _, _):
            return index
        case let .toggle(index, _, _, _, _):
            return index
        case let .action(index, _, _, _):
            return index
        case let .footer(index, _, _):
            return index
        }
    }

    static func <(lhs: VantagramDesignEntry, rhs: VantagramDesignEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! VantagramDesignArguments
        switch self {
        case let .header(_, section, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: section)
        case let .link(_, section, key, title, label):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: title, label: label, sectionId: section, style: .blocks, action: {
                arguments.tap(key)
            })
        case let .toggle(_, section, key, title, value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: title, value: value, sectionId: section, style: .blocks, updated: { value in
                arguments.toggle(key, value)
            })
        case let .action(_, section, key, title):
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: title, kind: .generic, alignment: .natural, sectionId: section, style: .blocks, action: {
                arguments.tap(key)
            })
        case let .footer(_, section, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: section)
        }
    }
}

private func vantagramDesignEntries() -> [VantagramDesignEntry] {
    var entries: [VantagramDesignEntry] = []
    var index: Int32 = 0
    func next() -> Int32 {
        index += 1
        return index
    }

    entries.append(.header(next(), 0, "АВАТАРКИ"))
    entries.append(.link(next(), 0, "avatarRadius", "Закругление аватарок", vantagramNearestTitle(vantagramAvatarRadiusChoices, VantagramUI.storedAvatarRadius)))
    entries.append(.footer(next(), 0, "Форма аватарок в списке чатов, в чатах и в профилях."))

    entries.append(.header(next(), 1, "ПУЗЫРИ СООБЩЕНИЙ"))
    entries.append(.link(next(), 1, "bubbleRadius", "Радиус углов пузырей", vantagramNearestTitle(vantagramBubbleRadiusChoices, VantagramUI.storedBubbleRadius)))
    entries.append(.toggle(next(), 1, "bubbleTails", "Хвостики у пузырей", !VantagramUI.storedBubbleNoTails))
    entries.append(.footer(next(), 1, "Это ваши настройки Vantagram: они перекрывают значения темы."))

    entries.append(.header(next(), 2, "ШРИФТЫ И РАЗМЕРЫ"))
    entries.append(.link(next(), 2, "interfaceFont", "Шрифт интерфейса", vantagramStringTitle(vantagramInterfaceFontChoices, VantagramUI.storedFontDesign)))
    entries.append(.link(next(), 2, "messageFont", "Шрифт сообщений", vantagramStringTitle(vantagramMessageFontChoices, VantagramUI.storedMessageFont)))
    entries.append(.link(next(), 2, "textSize", "Размер текста", ""))
    entries.append(.footer(next(), 2, "Размер текста открывает стандартный экран с ползунком и живым примером чата."))

    entries.append(.header(next(), 3, "СПИСОК ЧАТОВ"))
    entries.append(.link(next(), 3, "listAvatar", "Размер аватарок", vantagramNearestTitle(vantagramListAvatarChoices, VantagramUI.storedListAvatarScale)))
    entries.append(.link(next(), 3, "listRow", "Плотность строк", vantagramNearestTitle(vantagramListRowChoices, VantagramUI.storedListRowPadding)))
    entries.append(.footer(next(), 3, "Плотнее строки, больше чатов на экране."))

    entries.append(.header(next(), 6, "ЖЕСТЫ"))
    entries.append(.link(next(), 6, "doubleTap", "Двойной тап по сообщению", vantagramStringTitle(vantagramDoubleTapChoices, VantagramUI.doubleTapAction)))
    entries.append(.footer(next(), 6, "Применяется сразу. Для ответа и копирования реакция по двойному тапу отключается."))

    entries.append(.header(next(), 7, "СВАЙП ПО ЧАТУ В СПИСКЕ"))
    entries.append(.toggle(next(), 7, "gesture.hideMute", "Скрыть действие «Звук»", VantagramUI.gestureFlag("hideMute")))
    entries.append(.toggle(next(), 7, "gesture.hidePin", "Скрыть действие «Закрепить»", VantagramUI.gestureFlag("hidePin")))
    entries.append(.toggle(next(), 7, "gesture.hideArchive", "Скрыть действие «Архив»", VantagramUI.gestureFlag("hideArchive")))
    entries.append(.toggle(next(), 7, "gesture.hideDelete", "Скрыть действие «Удалить»", VantagramUI.gestureFlag("hideDelete")))
    entries.append(.footer(next(), 7, "Убирает выбранные кнопки при свайпе влево по чату. Применяется после перезапуска."))

    entries.append(.header(next(), 8, "МЕДИА В ЧАТАХ"))
    entries.append(.toggle(next(), 8, "mediaMonths", "Подписи месяцев в медиа", VantagramUI.mediaMonthLabels))
    entries.append(.footer(next(), 8, "В общих медиа чата на первом фото каждого месяца появляется подпись с названием месяца. Применяется при следующем открытии медиа."))

    entries.append(.header(next(), 4, "ПРИМЕНЕНИЕ"))
    entries.append(.action(next(), 4, "restart", "Перезапустить и применить"))
    entries.append(.footer(next(), 4, "Изменения вступают в силу после перезапуска. Приложение закроется, а через секунду придёт уведомление: нажми на него, чтобы открыть Vantagram."))

    entries.append(.header(next(), 5, "СТАНДАРТНЫЕ ЭКРАНЫ TELEGRAM"))
    entries.append(.link(next(), 5, "themes", "Оформление и темы", ""))
    entries.append(.link(next(), 5, "telegramBubbles", "Форма пузырей Telegram", ""))
    return entries
}

func vantagramDesignController(context: AccountContext) -> ViewController {
    let refresh = ValuePromise<Int>(0, ignoreRepeated: false)
    var counter = 0
    var pushControllerImpl: ((ViewController) -> Void)?

    func changed() {
        counter += 1
        refresh.set(counter)
    }

    func pushDoublePicker(title: String, header: String, footer: String, choices: [(Double, String)], current: Double, onSelect: @escaping (Double) -> Void) {
        var options: [VantagramPickerOption] = []
        for item in choices {
            options.append(VantagramPickerOption(id: "\(item.0)", title: item.1, symbol: nil))
        }
        pushControllerImpl?(vantagramPickerController(
            context: context,
            title: title,
            header: header,
            footer: footer,
            options: options,
            selectedId: vantagramNearestId(choices, current),
            onSelect: { id in
                if let value = Double(id) {
                    onSelect(value)
                }
                changed()
            }
        ))
    }

    func pushStringPicker(title: String, header: String, footer: String, choices: [(String, String)], current: String, onSelect: @escaping (String) -> Void) {
        var options: [VantagramPickerOption] = []
        for item in choices {
            options.append(VantagramPickerOption(id: item.0, title: item.1, symbol: nil))
        }
        pushControllerImpl?(vantagramPickerController(
            context: context,
            title: title,
            header: header,
            footer: footer,
            options: options,
            selectedId: current,
            onSelect: { id in
                onSelect(id)
                changed()
            }
        ))
    }

    let arguments = VantagramDesignArguments(
        tap: { key in
            switch key {
            case "avatarRadius":
                pushControllerImpl?(VantagramAvatarPreviewController(context: context))
            case "bubbleRadius":
                pushDoublePicker(title: "Радиус пузырей", header: "РАДИУС УГЛОВ", footer: "«Как в теме» оставляет значение из стандартных настроек. Применяется после перезапуска.", choices: vantagramBubbleRadiusChoices, current: VantagramUI.storedBubbleRadius, onSelect: { value in
                    VantagramUI.setDesignDouble("bubbleRadius", value)
                })
            case "interfaceFont":
                pushStringPicker(title: "Шрифт интерфейса", header: "ШРИФТ", footer: "Применяется ко всему тексту после перезапуска.", choices: vantagramInterfaceFontChoices, current: VantagramUI.storedFontDesign, onSelect: { id in
                    VantagramUI.setFontDesign(id)
                })
            case "messageFont":
                pushStringPicker(title: "Шрифт сообщений", header: "ШРИФТ СООБЩЕНИЙ", footer: "Отдельный шрифт для текста сообщений. Применяется после перезапуска.", choices: vantagramMessageFontChoices, current: VantagramUI.storedMessageFont, onSelect: { id in
                    VantagramUI.setMessageFont(id)
                })
            case "listAvatar":
                pushDoublePicker(title: "Аватарки в списке", header: "РАЗМЕР АВАТАРОК", footer: "Применяется после перезапуска.", choices: vantagramListAvatarChoices, current: VantagramUI.storedListAvatarScale, onSelect: { value in
                    VantagramUI.setDesignDouble("listAvatarScale", value)
                })
            case "doubleTap":
                pushStringPicker(title: "Двойной тап", header: "ДЕЙСТВИЕ ПО ДВОЙНОМУ ТАПУ", footer: "Что делает двойной тап по сообщению в чате. Применяется сразу.", choices: vantagramDoubleTapChoices, current: VantagramUI.doubleTapAction, onSelect: { id in
                    VantagramUI.setDoubleTapAction(id)
                })
            case "listRow":
                pushDoublePicker(title: "Плотность строк", header: "ВЫСОТА СТРОК СПИСКА", footer: "Применяется после перезапуска.", choices: vantagramListRowChoices, current: VantagramUI.storedListRowPadding, onSelect: { value in
                    VantagramUI.setDesignDouble("listRowPadding", value)
                })
            case "textSize":
                let _ = (context.sharedContext.accountManager.sharedData(keys: Set([ApplicationSpecificSharedDataKeys.presentationThemeSettings]))
                |> take(1)
                |> deliverOnMainQueue).start(next: { view in
                    let settings = view.entries[ApplicationSpecificSharedDataKeys.presentationThemeSettings]?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
                    pushControllerImpl?(TextSizeSelectionController(context: context, presentationThemeSettings: settings))
                })
            case "telegramBubbles":
                let _ = (context.sharedContext.accountManager.sharedData(keys: Set([ApplicationSpecificSharedDataKeys.presentationThemeSettings]))
                |> take(1)
                |> deliverOnMainQueue).start(next: { view in
                    let settings = view.entries[ApplicationSpecificSharedDataKeys.presentationThemeSettings]?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
                    pushControllerImpl?(BubbleSettingsController(context: context, presentationThemeSettings: settings))
                })
            case "themes":
                pushControllerImpl?(themeSettingsController(context: context))
            case "restart":
                vantagramRestartApp()
            default:
                break
            }
        },
        toggle: { key, value in
            if key == "mediaMonths" {
                VantagramUI.setMediaMonthLabels(value)
                changed()
            } else if key == "bubbleTails" {
                VantagramUI.setDesignBool("bubbleNoTails", !value)
                changed()
            } else if key.hasPrefix("gesture.") {
                VantagramUI.setGestureFlag(String(key.dropFirst("gesture.".count)), value)
                changed()
            }
        }
    )

    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        refresh.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text("Дизайн Vantagram"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: vantagramDesignEntries(), style: .blocks, animateChanges: true)
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    controller.didAppear = { _ in
        changed()
    }
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}
