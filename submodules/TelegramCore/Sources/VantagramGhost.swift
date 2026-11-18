import Foundation

/// Vantagram "ghost mode" switches. Stored in UserDefaults so that low-level network code
/// (read receipts, typing, online presence) can check them without any plumbing.
public enum VantagramGhost {
    private static let hideReadKey = "vantagram.ghost.hideRead"
    private static let hideTypingKey = "vantagram.ghost.hideTyping"
    private static let hideOnlineKey = "vantagram.ghost.hideOnline"

    /// Do not tell the server that incoming messages were read (no "read" checkmarks for the sender).
    public static var hideRead: Bool {
        return UserDefaults.standard.bool(forKey: hideReadKey)
    }

    /// Do not send "typing..." / "recording voice message..." activity.
    public static var hideTyping: Bool {
        return UserDefaults.standard.bool(forKey: hideTypingKey)
    }

    /// Never report online presence.
    public static var hideOnline: Bool {
        return UserDefaults.standard.bool(forKey: hideOnlineKey)
    }

    private static let keepDeletedKey = "vantagram.archive.keepDeleted"

    /// Keep messages locally when the sender (or the other side) deletes them on the server.
    public static var keepDeleted: Bool {
        return UserDefaults.standard.bool(forKey: keepDeletedKey)
    }

    private static let hideAdsKey = "vantagram.misc.hideAds"

    /// Never load sponsored messages in channels.
    public static var hideAds: Bool {
        return UserDefaults.standard.bool(forKey: hideAdsKey)
    }

    public static func setHideAds(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hideAdsKey)
    }

    private static let deletedIconKey = "vantagram.archive.deletedIcon"
    private static let deletedAlphaKey = "vantagram.archive.deletedAlpha"

    /// Icons the user can pick for messages that were deleted remotely (shown next to the message time).
    public static let deletedIconChoices: [String] = ["trash.fill", "xmark.bin.fill", "xmark.circle.fill", "eye.slash.fill", "minus.circle.fill", "exclamationmark.circle.fill", "flame.fill", "bolt.fill"]

    /// Opacity choices for messages that were deleted remotely.
    public static let deletedAlphaChoices: [Double] = [1.0, 0.8, 0.6, 0.4, 0.25]

    /// Icon shown next to the time of a message that was deleted remotely.
    public static var deletedIcon: String {
        if let value = UserDefaults.standard.string(forKey: deletedIconKey), deletedIconChoices.contains(value) {
            return value
        }
        return "trash.fill"
    }

    public static func setDeletedIcon(_ value: String) {
        UserDefaults.standard.set(value, forKey: deletedIconKey)
    }

    /// Opacity of a message that was deleted remotely (1.0 = fully opaque).
    public static var deletedAlpha: Double {
        if let value = UserDefaults.standard.object(forKey: deletedAlphaKey) as? Double, value >= 0.05, value <= 1.0 {
            return value
        }
        return 0.6
    }

    public static func setDeletedAlpha(_ value: Double) {
        UserDefaults.standard.set(value, forKey: deletedAlphaKey)
    }

    private static let showSecondsKey = "vantagram.time.showSeconds"

    /// Show seconds in the time of messages in chat bubbles.
    public static var showSeconds: Bool {
        return UserDefaults.standard.bool(forKey: showSecondsKey)
    }

    public static func setShowSeconds(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: showSecondsKey)
    }

    private static let allowCopyKey = "vantagram.misc.allowCopy"
    private static let allowSensitiveKey = "vantagram.misc.allowSensitive"

    /// Allow copying, saving and forwarding from chats with "restrict saving content".
    public static var allowCopy: Bool {
        return UserDefaults.standard.bool(forKey: allowCopyKey)
    }

    public static func setAllowCopy(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: allowCopyKey)
    }

    /// Do not hide sensitive (18+) content behind a blur.
    public static var allowSensitive: Bool {
        return UserDefaults.standard.bool(forKey: allowSensitiveKey)
    }

    public static func setAllowSensitive(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: allowSensitiveKey)
    }

    private static let hideStoriesKey = "vantagram.ui.hideStories"
    private static let disableSwipeReplyKey = "vantagram.ui.disableSwipeReply"
    private static let hidePhoneKey = "vantagram.ui.hidePhone"

    /// Hide the stories row above the chat list.
    public static var hideStories: Bool {
        return UserDefaults.standard.bool(forKey: hideStoriesKey)
    }

    public static func setHideStories(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hideStoriesKey)
    }

    /// Disable the swipe-to-reply gesture on messages.
    public static var disableSwipeReply: Bool {
        return UserDefaults.standard.bool(forKey: disableSwipeReplyKey)
    }

    public static func setDisableSwipeReply(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: disableSwipeReplyKey)
    }

    /// Mask my own phone number on the settings screen.
    public static var hidePhone: Bool {
        return UserDefaults.standard.bool(forKey: hidePhoneKey)
    }

    public static func setHidePhone(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hidePhoneKey)
    }

    private static let openLinksExternallyKey = "vantagram.ui.openLinksExternally"

    /// Open web links in the system browser instead of the in-app browser.
    public static var openLinksExternally: Bool {
        return UserDefaults.standard.bool(forKey: openLinksExternallyKey)
    }

    public static func setOpenLinksExternally(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: openLinksExternallyKey)
    }

    private static let hidePremiumKey = "vantagram.misc.hidePremium"

    /// Hide Telegram Premium purchase promotions across the app.
    public static var hidePremium: Bool {
        return UserDefaults.standard.bool(forKey: hidePremiumKey)
    }

    public static func setHidePremium(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hidePremiumKey)
    }

    private static let notchBadgeKey = "vantagram.misc.notchBadge"

    /// Show the Vantagram "V" logo under the Dynamic Island (visible in screenshots/recordings).
    public static var notchBadge: Bool {
        return UserDefaults.standard.bool(forKey: notchBadgeKey)
    }

    public static func setNotchBadge(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: notchBadgeKey)
        NotificationCenter.default.post(name: Notification.Name("vantagram.notchBadge.changed"), object: nil)
    }

    public static func setKeepDeleted(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: keepDeletedKey)
    }

    public static func setHideRead(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hideReadKey)
    }

    public static func setHideTyping(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hideTypingKey)
    }

    public static func setHideOnline(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: hideOnlineKey)
    }

    // MARK: Local visuals. These values only change what is shown on this device.

    private static let localStarsBonusKey = "vantagram.local.starsBonus"
    private static let localGiftIdsKey = "vantagram.local.giftIds"

    /// Stars added on top of the real balance in the interface. The real balance is not touched.
    public static var localStarsBonus: Int64 {
        if let value = UserDefaults.standard.object(forKey: localStarsBonusKey) as? Int64, value > 0 {
            return value
        }
        return 0
    }

    public static func setLocalStarsBonus(_ value: Int64) {
        UserDefaults.standard.set(max(0, value), forKey: localStarsBonusKey)
    }

    /// Ids of catalog gifts that the user gave to themselves locally.
    public static var localGiftIds: [Int64] {
        guard let text = UserDefaults.standard.string(forKey: localGiftIdsKey), !text.isEmpty else {
            return []
        }
        var result: [Int64] = []
        for part in text.split(separator: ",") {
            if let value = Int64(part) {
                result.append(value)
            }
        }
        return result
    }

    public static func setLocalGiftIds(_ value: [Int64]) {
        UserDefaults.standard.set(value.map { String($0) }.joined(separator: ","), forKey: localGiftIdsKey)
    }
}
