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
}
