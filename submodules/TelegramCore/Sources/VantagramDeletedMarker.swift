import Foundation
import Postbox

/// Keeps the messages but marks them with `VantagramDeletedMessageAttribute`, so the chat UI can
/// show a trash icon next to the time and fade the message.
func vantagramMarkMessagesAsDeleted(transaction: Transaction, ids: [MessageId]) {
    let now = Int32(clamping: Int(Date().timeIntervalSince1970))
    for id in ids {
        transaction.updateMessage(id, update: { currentMessage -> PostboxUpdateMessage in
            if currentMessage.isVantagramDeleted {
                return .skip
            }
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }
            var updatedAttributes = currentMessage.attributes
            updatedAttributes.append(VantagramDeletedMessageAttribute(date: now))
            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: currentMessage.text, attributes: updatedAttributes, media: currentMessage.media))
        })
    }
}
