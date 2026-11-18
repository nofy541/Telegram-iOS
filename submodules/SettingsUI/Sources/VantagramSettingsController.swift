import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import UserNotifications
import AlertUI
import StorageUsageScreen
import TelegramUIPreferences

private let vantagramAnimationSpeeds: [(Double, String)] = [
    (0.35, "Очень быстро"),
    (0.6, "Быстро"),
    (1.0, "Обычно"),
    (1.6, "Медленно"),
    (2.5, "Очень медленно")
]

private let vantagramDeletedIconTitles: [String: String] = [
    "trash.fill": "Корзина",
    "xmark.bin.fill": "Корзина с крестиком",
    "xmark.circle.fill": "Крестик",
    "eye.slash.fill": "Перечёркнутый глаз",
    "minus.circle.fill": "Минус",
    "exclamationmark.circle.fill": "Восклицательный знак",
    "flame.fill": "Огонь",
    "bolt.fill": "Молния"
]

private func vantagramDeletedIconTitle(_ symbol: String) -> String {
    return vantagramDeletedIconTitles[symbol] ?? symbol
}

private let vantagramFontChoices: [(String, String)] = [
    ("default", "Системный"),
    ("rounded", "Скруглённый"),
    ("serif", "С засечками"),
    ("monospaced", "Моноширинный")
]

private func vantagramFontTitle(_ id: String) -> String {
    for item in vantagramFontChoices {
        if item.0 == id {
            return item.1
        }
    }
    return "Системный"
}

private func vantagramAnimationSpeedTitle(_ factor: Double) -> String {
    var best = vantagramAnimationSpeeds[0]
    for item in vantagramAnimationSpeeds {
        if abs(item.0 - factor) < abs(best.0 - factor) {
            best = item
        }
    }
    return best.1
}

private func vantagramDeletedAlphaTitle(_ alpha: Double) -> String {
    return "\(Int((alpha * 100.0).rounded()))%"
}

/// Quits the app so that the glass setting is applied everywhere. iOS does not allow an app to relaunch itself,
/// so a local notification is scheduled that opens the app again with one tap.
private func vantagramRestartApp() {
    let content = UNMutableNotificationContent()
    content.title = "Vantagram"
    content.body = "Нажми, чтобы открыть приложение с новым оформлением"
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
    let request = UNNotificationRequest(identifier: "vantagram.restart", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}

private final class VantagramSettingsArguments {
    let updateAppSwitcherBlur: (Bool) -> Void
    let openStorage: () -> Void
    let exportBackup: () -> Void
    let importBackup: () -> Void
    let openDesignTheme: () -> Void
    let openDesignTextSize: () -> Void
    let openDesignBubbles: () -> Void
    let updateHideRead: (Bool) -> Void
    let updateHideTyping: (Bool) -> Void
    let updateHideOnline: (Bool) -> Void
    let updateKeepDeleted: (Bool) -> Void
    let openDeletedIcon: () -> Void
    let openDeletedAlpha: () -> Void
    let updateHideAds: (Bool) -> Void
    let openAnimationSpeed: () -> Void
    let openFontDesign: () -> Void
    let updateNotchBadge: (Bool) -> Void
    let updateHidePremium: (Bool) -> Void
    let updateGlassEnabled: (Bool) -> Void
    let updateShowSeconds: (Bool) -> Void
    let updateAllowCopy: (Bool) -> Void
    let updateAllowSensitive: (Bool) -> Void
    let updateHideStories: (Bool) -> Void
    let updateDisableSwipeReply: (Bool) -> Void
    let updateHidePhone: (Bool) -> Void
    let updateOpenLinksExternally: (Bool) -> Void

    init(
        updateAppSwitcherBlur: @escaping (Bool) -> Void,
        openStorage: @escaping () -> Void,
        exportBackup: @escaping () -> Void,
        importBackup: @escaping () -> Void,
        openDesignTheme: @escaping () -> Void,
        openDesignTextSize: @escaping () -> Void,
        openDesignBubbles: @escaping () -> Void,
        updateHideRead: @escaping (Bool) -> Void,
        updateHideTyping: @escaping (Bool) -> Void,
        updateHideOnline: @escaping (Bool) -> Void,
        updateKeepDeleted: @escaping (Bool) -> Void,
        openDeletedIcon: @escaping () -> Void,
        openDeletedAlpha: @escaping () -> Void,
        updateHideAds: @escaping (Bool) -> Void,
        openAnimationSpeed: @escaping () -> Void,
        openFontDesign: @escaping () -> Void,
        updateNotchBadge: @escaping (Bool) -> Void,
        updateHidePremium: @escaping (Bool) -> Void,
        updateGlassEnabled: @escaping (Bool) -> Void,
        updateShowSeconds: @escaping (Bool) -> Void,
        updateAllowCopy: @escaping (Bool) -> Void,
        updateAllowSensitive: @escaping (Bool) -> Void,
        updateHideStories: @escaping (Bool) -> Void,
        updateDisableSwipeReply: @escaping (Bool) -> Void,
        updateHidePhone: @escaping (Bool) -> Void,
        updateOpenLinksExternally: @escaping (Bool) -> Void
    ) {
        self.updateAppSwitcherBlur = updateAppSwitcherBlur
        self.openStorage = openStorage
        self.exportBackup = exportBackup
        self.importBackup = importBackup
        self.openDesignTheme = openDesignTheme
        self.openDesignTextSize = openDesignTextSize
        self.openDesignBubbles = openDesignBubbles
        self.updateHideRead = updateHideRead
        self.updateHideTyping = updateHideTyping
        self.updateHideOnline = updateHideOnline
        self.updateKeepDeleted = updateKeepDeleted
        self.openDeletedIcon = openDeletedIcon
        self.openDeletedAlpha = openDeletedAlpha
        self.updateHideAds = updateHideAds
        self.openAnimationSpeed = openAnimationSpeed
        self.openFontDesign = openFontDesign
        self.updateNotchBadge = updateNotchBadge
        self.updateHidePremium = updateHidePremium
        self.updateGlassEnabled = updateGlassEnabled
        self.updateShowSeconds = updateShowSeconds
        self.updateAllowCopy = updateAllowCopy
        self.updateAllowSensitive = updateAllowSensitive
        self.updateHideStories = updateHideStories
        self.updateDisableSwipeReply = updateDisableSwipeReply
        self.updateHidePhone = updateHidePhone
        self.updateOpenLinksExternally = updateOpenLinksExternally
    }
}

private struct VantagramSettingsState: Equatable {
    var hideRead: Bool
    var hideTyping: Bool
    var hideOnline: Bool
    var keepDeleted: Bool
    var deletedIcon: String
    var deletedAlpha: Double
    var hideAds: Bool
    var animationFactor: Double
    var fontDesign: String
    var appSwitcherBlur: Bool
    var notchBadge: Bool
    var hidePremium: Bool
    var glassEnabled: Bool
    var showSeconds: Bool
    var allowCopy: Bool
    var allowSensitive: Bool
    var hideStories: Bool
    var disableSwipeReply: Bool
    var hidePhone: Bool
    var openLinksExternally: Bool

    static func load() -> VantagramSettingsState {
        return VantagramSettingsState(
            hideRead: VantagramGhost.hideRead,
            hideTyping: VantagramGhost.hideTyping,
            hideOnline: VantagramGhost.hideOnline,
            keepDeleted: VantagramGhost.keepDeleted,
            deletedIcon: VantagramGhost.deletedIcon,
            deletedAlpha: VantagramGhost.deletedAlpha,
            hideAds: VantagramGhost.hideAds,
            animationFactor: VantagramAnimation.factor,
            fontDesign: VantagramUI.storedFontDesign,
            appSwitcherBlur: VantagramUI.appSwitcherBlur,
            notchBadge: VantagramGhost.notchBadge,
            hidePremium: VantagramGhost.hidePremium,
            glassEnabled: VantagramUI.glassEnabled,
            showSeconds: VantagramGhost.showSeconds,
            allowCopy: VantagramGhost.allowCopy,
            allowSensitive: VantagramGhost.allowSensitive,
            hideStories: VantagramGhost.hideStories,
            disableSwipeReply: VantagramGhost.disableSwipeReply,
            hidePhone: VantagramGhost.hidePhone,
            openLinksExternally: VantagramGhost.openLinksExternally
        )
    }
}

private enum VantagramSettingsSection: Int32 {
    case tools
    case design
    case ghost
    case archive
    case interface
    case access
    case misc
    case chats
}

private enum VantagramSettingsEntry: ItemListNodeEntry {
    case toolsHeader
    case appSwitcherBlur(Bool)
    case openStorage
    case backupExport
    case backupImport
    case toolsFooter

    case designHeader
    case designTheme
    case designTextSize
    case designBubbles
    case designFooter

    case ghostHeader
    case hideRead(Bool)
    case hideTyping(Bool)
    case hideOnline(Bool)
    case ghostFooter

    case archiveHeader
    case keepDeleted(Bool)
    case deletedIcon(String)
    case deletedAlpha(Double)
    case archiveFooter

    case interfaceHeader
    case animationSpeed(Double)
    case fontDesign(String)
    case notchBadge(Bool)
    case glass(Bool)
    case showSeconds(Bool)
    case interfaceFooter

    case accessHeader
    case allowCopy(Bool)
    case allowSensitive(Bool)
    case accessFooter

    case miscHeader
    case hideAds(Bool)
    case hidePremium(Bool)

    case chatsHeader
    case hideStories(Bool)
    case disableSwipeReply(Bool)
    case hidePhone(Bool)
    case openLinksExternally(Bool)
    case chatsFooter

    var section: ItemListSectionId {
        switch self {
        case .toolsHeader, .appSwitcherBlur, .openStorage, .backupExport, .backupImport, .toolsFooter:
            return VantagramSettingsSection.tools.rawValue
        case .designHeader, .designTheme, .designTextSize, .designBubbles, .designFooter:
            return VantagramSettingsSection.design.rawValue
        case .ghostHeader, .hideRead, .hideTyping, .hideOnline, .ghostFooter:
            return VantagramSettingsSection.ghost.rawValue
        case .archiveHeader, .keepDeleted, .deletedIcon, .deletedAlpha, .archiveFooter:
            return VantagramSettingsSection.archive.rawValue
        case .interfaceHeader, .animationSpeed, .fontDesign, .notchBadge, .glass, .showSeconds, .interfaceFooter:
            return VantagramSettingsSection.interface.rawValue
        case .accessHeader, .allowCopy, .allowSensitive, .accessFooter:
            return VantagramSettingsSection.access.rawValue
        case .miscHeader, .hideAds, .hidePremium:
            return VantagramSettingsSection.misc.rawValue
        case .chatsHeader, .hideStories, .disableSwipeReply, .hidePhone, .openLinksExternally, .chatsFooter:
            return VantagramSettingsSection.chats.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .toolsHeader:
            return 30
        case .appSwitcherBlur:
            return 31
        case .openStorage:
            return 32
        case .backupExport:
            return 33
        case .backupImport:
            return 34
        case .toolsFooter:
            return 35
        case .designHeader:
            return -5
        case .designTheme:
            return -4
        case .designTextSize:
            return -3
        case .designBubbles:
            return -2
        case .designFooter:
            return -1
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
        case .deletedIcon:
            return 7
        case .deletedAlpha:
            return 8
        case .archiveFooter:
            return 9
        case .interfaceHeader:
            return 10
        case .animationSpeed:
            return 11
        case .notchBadge:
            return 12
        case .glass:
            return 13
        case .showSeconds:
            return 14
        case .fontDesign:
            return 15
        case .interfaceFooter:
            return 16
        case .accessHeader:
            return 17
        case .allowCopy:
            return 18
        case .allowSensitive:
            return 19
        case .accessFooter:
            return 20
        case .miscHeader:
            return 21
        case .hideAds:
            return 22
        case .hidePremium:
            return 23
        case .chatsHeader:
            return 24
        case .hideStories:
            return 25
        case .disableSwipeReply:
            return 26
        case .hidePhone:
            return 27
        case .openLinksExternally:
            return 28
        case .chatsFooter:
            return 29
        }
    }

    static func <(lhs: VantagramSettingsEntry, rhs: VantagramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! VantagramSettingsArguments
        switch self {
        case .toolsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ПРИВАТНОСТЬ И ДАННЫЕ", sectionId: self.section)
        case let .appSwitcherBlur(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Размывать экран в переключателе", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateAppSwitcherBlur(value)
            })
        case .openStorage:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Хранилище и чистка кэша", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openStorage()
            })
        case .backupExport:
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: "Экспорт настроек Vantagram", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.exportBackup()
            })
        case .backupImport:
            return ItemListActionItem(presentationData: presentationData, systemStyle: .glass, title: "Импорт настроек из буфера обмена", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                arguments.importBackup()
            })
        case .toolsFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Размытие скрывает содержимое в списке недавних приложений. Экспорт отдаёт все настройки Vantagram текстом (JSON): сохрани его в заметки или отправь себе. Чтобы восстановить, скопируй этот текст и нажми «Импорт». После импорта перезапусти приложение."), sectionId: self.section)
        case .designHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ДИЗАЙН", sectionId: self.section)
        case .designTheme:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Оформление и темы", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openDesignTheme()
            })
        case .designTextSize:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Размер текста", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openDesignTextSize()
            })
        case .designBubbles:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Форма пузырей", label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openDesignBubbles()
            })
        case .designFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Эти экраны показывают пример чата: двигаешь ползунок, и результат виден сразу."), sectionId: self.section)
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
        case let .deletedIcon(icon):
            let configuration = UIImage.SymbolConfiguration(pointSize: 17.0, weight: .semibold)
            let iconImage = UIImage(systemName: icon, withConfiguration: configuration)?.withTintColor(presentationData.theme.list.itemAccentColor, renderingMode: .alwaysOriginal)
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Значок удалённых", titleIcon: iconImage, label: vantagramDeletedIconTitle(icon), sectionId: self.section, style: .blocks, action: {
                arguments.openDeletedIcon()
            })
        case let .deletedAlpha(alpha):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Прозрачность удалённых", label: vantagramDeletedAlphaTitle(alpha), sectionId: self.section, style: .blocks, action: {
                arguments.openDeletedAlpha()
            })
        case .archiveFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Если собеседник удалит сообщение, оно останется в чате: рядом со временем появится выбранный значок, а само сообщение станет прозрачным. Работает для удалений, пришедших, пока приложение запущено."), sectionId: self.section)
        case .interfaceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ИНТЕРФЕЙС", sectionId: self.section)
        case let .animationSpeed(factor):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Скорость анимаций", label: vantagramAnimationSpeedTitle(factor), sectionId: self.section, style: .blocks, action: {
                arguments.openAnimationSpeed()
            })
        case let .fontDesign(design):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: "Шрифт интерфейса", label: vantagramFontTitle(design), sectionId: self.section, style: .blocks, action: {
                arguments.openFontDesign()
            })
        case let .notchBadge(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Логотип под вырезом", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateNotchBadge(value)
            })
        case let .glass(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Liquid Glass (стекло)", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGlassEnabled(value)
            })
        case let .showSeconds(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Секунды во времени сообщений", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateShowSeconds(value)
            })
        case .interfaceFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Шрифт меняется после перезапуска: приложение закроется, нажми на уведомление, чтобы открыть его снова. Логотип под вырезом обычно не виден, но попадает на скриншоты и запись экрана. Если выключить «Liquid Glass», панели и кнопки станут обычными, как до iOS 26. При переключении приложение закроется, а через секунду придёт уведомление: нажми на него, чтобы открыть Vantagram с новым видом (iOS не даёт приложению перезапуститься самому)."), sectionId: self.section)
        case .accessHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ДОСТУП К КОНТЕНТУ", sectionId: self.section)
        case let .allowCopy(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Обход запрета копирования", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateAllowCopy(value)
            })
        case let .allowSensitive(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Не скрывать контент 18+", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateAllowSensitive(value)
            })
        case .accessFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Позволяет копировать, пересылать и сохранять сообщения из чатов с запретом сохранения, а также показывает чувствительный контент без размытия. Откройте чат заново, чтобы изменения применились."), sectionId: self.section)
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
        case .chatsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ЧАТЫ И СПИСКИ", sectionId: self.section)
        case let .hideStories(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрыть истории над чатами", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHideStories(value)
            })
        case let .disableSwipeReply(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Отключить свайп для ответа", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateDisableSwipeReply(value)
            })
        case let .hidePhone(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Скрыть мой номер телефона", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateHidePhone(value)
            })
        case let .openLinksExternally(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Ссылки во внешнем браузере", value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateOpenLinksExternally(value)
            })
        case .chatsFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Истории и свайп применяются после повторного открытия экрана. Номер скрывается только на твоём экране настроек, другим людям он виден по-прежнему."), sectionId: self.section)
        }
    }
}

private func vantagramSettingsEntries(state: VantagramSettingsState) -> [VantagramSettingsEntry] {
    var entries: [VantagramSettingsEntry] = []
    entries.append(.designHeader)
    entries.append(.designTheme)
    entries.append(.designTextSize)
    entries.append(.designBubbles)
    entries.append(.designFooter)
    entries.append(.ghostHeader)
    entries.append(.hideRead(state.hideRead))
    entries.append(.hideTyping(state.hideTyping))
    entries.append(.hideOnline(state.hideOnline))
    entries.append(.ghostFooter)
    entries.append(.archiveHeader)
    entries.append(.keepDeleted(state.keepDeleted))
    entries.append(.deletedIcon(state.deletedIcon))
    entries.append(.deletedAlpha(state.deletedAlpha))
    entries.append(.archiveFooter)
    entries.append(.interfaceHeader)
    entries.append(.animationSpeed(state.animationFactor))
    entries.append(.fontDesign(state.fontDesign))
    entries.append(.notchBadge(state.notchBadge))
    entries.append(.glass(state.glassEnabled))
    entries.append(.showSeconds(state.showSeconds))
    entries.append(.interfaceFooter)
    entries.append(.accessHeader)
    entries.append(.allowCopy(state.allowCopy))
    entries.append(.allowSensitive(state.allowSensitive))
    entries.append(.accessFooter)
    entries.append(.miscHeader)
    entries.append(.hideAds(state.hideAds))
    entries.append(.hidePremium(state.hidePremium))
    entries.append(.chatsHeader)
    entries.append(.hideStories(state.hideStories))
    entries.append(.disableSwipeReply(state.disableSwipeReply))
    entries.append(.hidePhone(state.hidePhone))
    entries.append(.openLinksExternally(state.openLinksExternally))
    entries.append(.chatsFooter)
    entries.append(.toolsHeader)
    entries.append(.appSwitcherBlur(state.appSwitcherBlur))
    entries.append(.openStorage)
    entries.append(.backupExport)
    entries.append(.backupImport)
    entries.append(.toolsFooter)
    return entries
}

public func vantagramSettingsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(VantagramSettingsState.load(), ignoreRepeated: true)

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?

    let arguments = VantagramSettingsArguments(
        updateAppSwitcherBlur: { value in
            VantagramUI.setAppSwitcherBlur(value)
            statePromise.set(VantagramSettingsState.load())
        },
        openStorage: {
            pushControllerImpl?(StorageUsageScreen(context: context, makeStorageUsageExceptionsScreen: { category in
                return storageUsageExceptionsScreen(context: context, category: category)
            }))
        },
        exportBackup: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            if let text = VantagramBackup.exportJSON() {
                context.sharedContext.mainWindow?.presentNative(UIActivityViewController(activityItems: [text], applicationActivities: nil))
            } else {
                presentControllerImpl?(textAlertController(context: context, title: nil, text: "Не удалось собрать настройки.", actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]))
            }
        },
        importBackup: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let count = VantagramBackup.importJSON(UIPasteboard.general.string ?? "")
            let message: String
            if count > 0 {
                message = "Импортировано настроек: \(count). Перезапусти приложение, чтобы они применились."
            } else {
                message = "В буфере обмена нет настроек Vantagram. Скопируй текст экспорта и попробуй снова."
            }
            statePromise.set(VantagramSettingsState.load())
            presentControllerImpl?(textAlertController(context: context, title: nil, text: message, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]))
        },
        openDesignTheme: {
            pushControllerImpl?(themeSettingsController(context: context))
        },
        openDesignTextSize: {
            let _ = (context.sharedContext.accountManager.sharedData(keys: Set([ApplicationSpecificSharedDataKeys.presentationThemeSettings]))
            |> take(1)
            |> deliverOnMainQueue).start(next: { view in
                let settings = view.entries[ApplicationSpecificSharedDataKeys.presentationThemeSettings]?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
                pushControllerImpl?(TextSizeSelectionController(context: context, presentationThemeSettings: settings))
            })
        },
        openDesignBubbles: {
            let _ = (context.sharedContext.accountManager.sharedData(keys: Set([ApplicationSpecificSharedDataKeys.presentationThemeSettings]))
            |> take(1)
            |> deliverOnMainQueue).start(next: { view in
                let settings = view.entries[ApplicationSpecificSharedDataKeys.presentationThemeSettings]?.get(PresentationThemeSettings.self) ?? PresentationThemeSettings.defaultSettings
                pushControllerImpl?(BubbleSettingsController(context: context, presentationThemeSettings: settings))
            })
        },
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
        openDeletedIcon: {
            var options: [VantagramPickerOption] = []
            for symbol in VantagramGhost.deletedIconChoices {
                options.append(VantagramPickerOption(id: symbol, title: vantagramDeletedIconTitle(symbol), symbol: symbol))
            }
            pushControllerImpl?(vantagramPickerController(
                context: context,
                title: "Значок удалённых",
                header: "ЗНАЧОК У ВРЕМЕНИ СООБЩЕНИЯ",
                footer: "Этот значок появляется рядом со временем сообщения, которое удалил собеседник.",
                options: options,
                selectedId: VantagramGhost.deletedIcon,
                onSelect: { id in
                    VantagramGhost.setDeletedIcon(id)
                    statePromise.set(VantagramSettingsState.load())
                }
            ))
        },
        openDeletedAlpha: {
            var options: [VantagramPickerOption] = []
            for alpha in VantagramGhost.deletedAlphaChoices {
                options.append(VantagramPickerOption(id: "\(alpha)", title: vantagramDeletedAlphaTitle(alpha), symbol: nil))
            }
            let current = VantagramGhost.deletedAlpha
            var selected = options.first?.id ?? "1.0"
            for alpha in VantagramGhost.deletedAlphaChoices {
                if abs(alpha - current) < 0.001 {
                    selected = "\(alpha)"
                }
            }
            pushControllerImpl?(vantagramPickerController(
                context: context,
                title: "Прозрачность удалённых",
                header: "ПРОЗРАЧНОСТЬ СООБЩЕНИЯ",
                footer: "Насколько заметным остаётся сообщение после удаления. 100% — как обычное.",
                options: options,
                selectedId: selected,
                onSelect: { id in
                    if let value = Double(id) {
                        VantagramGhost.setDeletedAlpha(value)
                    }
                    statePromise.set(VantagramSettingsState.load())
                }
            ))
        },
        updateHideAds: { value in
            VantagramGhost.setHideAds(value)
            statePromise.set(VantagramSettingsState.load())
        },
        openAnimationSpeed: {
            var options: [VantagramPickerOption] = []
            for item in vantagramAnimationSpeeds {
                options.append(VantagramPickerOption(id: "\(item.0)", title: item.1, symbol: nil))
            }
            let current = VantagramAnimation.factor
            var selected = "1.0"
            var bestDistance = Double.greatestFiniteMagnitude
            for item in vantagramAnimationSpeeds {
                let distance = abs(item.0 - current)
                if distance < bestDistance {
                    bestDistance = distance
                    selected = "\(item.0)"
                }
            }
            pushControllerImpl?(vantagramPickerController(
                context: context,
                title: "Скорость анимаций",
                header: "СКОРОСТЬ АНИМАЦИЙ ИНТЕРФЕЙСА",
                footer: "Влияет на переходы, открытие экранов и пролистывание. Применяется сразу.",
                options: options,
                selectedId: selected,
                onSelect: { id in
                    if let value = Double(id) {
                        VantagramAnimation.setFactor(value)
                    }
                    statePromise.set(VantagramSettingsState.load())
                }
            ))
        },
        openFontDesign: {
            var options: [VantagramPickerOption] = []
            for item in vantagramFontChoices {
                options.append(VantagramPickerOption(id: item.0, title: item.1, symbol: nil))
            }
            pushControllerImpl?(vantagramPickerController(
                context: context,
                title: "Шрифт интерфейса",
                header: "ШРИФТ",
                footer: "Применяется ко всему тексту приложения. После выбора приложение закроется, а через секунду придёт уведомление: нажми на него, чтобы открыть Vantagram с новым шрифтом.",
                options: options,
                selectedId: VantagramUI.storedFontDesign,
                onSelect: { id in
                    if id == VantagramUI.storedFontDesign {
                        return
                    }
                    VantagramUI.setFontDesign(id)
                    statePromise.set(VantagramSettingsState.load())
                    vantagramRestartApp()
                }
            ))
        },
        updateNotchBadge: { value in
            VantagramGhost.setNotchBadge(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHidePremium: { value in
            VantagramGhost.setHidePremium(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateGlassEnabled: { value in
            VantagramUI.setGlassEnabled(value)
            statePromise.set(VantagramSettingsState.load())
            vantagramRestartApp()
        },
        updateShowSeconds: { value in
            VantagramGhost.setShowSeconds(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateAllowCopy: { value in
            VantagramGhost.setAllowCopy(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateAllowSensitive: { value in
            VantagramGhost.setAllowSensitive(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHideStories: { value in
            VantagramGhost.setHideStories(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateDisableSwipeReply: { value in
            VantagramGhost.setDisableSwipeReply(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateHidePhone: { value in
            VantagramGhost.setHidePhone(value)
            statePromise.set(VantagramSettingsState.load())
        },
        updateOpenLinksExternally: { value in
            VantagramGhost.setOpenLinksExternally(value)
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
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root))
    }
    return controller
}
