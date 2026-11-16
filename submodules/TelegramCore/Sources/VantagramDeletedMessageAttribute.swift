import Foundation
import Postbox

/// Marks a message that was deleted on the server side but is kept locally (Vantagram "keep deleted").
public class VantagramDeletedMessageAttribute: MessageAttribute {
    /// When the deletion was noticed.
    public let date: Int32

    public init(date: Int32) {
        self.date = date
    }

    required public init(decoder: PostboxDecoder) {
        self.date = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.date, forKey: "d")
    }
}

public extension Message {
    /// True when the message was deleted remotely but is kept in the local history.
    var isVantagramDeleted: Bool {
        for attribute in self.attributes {
            if attribute is VantagramDeletedMessageAttribute {
                return true
            }
        }
        return false
    }
}
