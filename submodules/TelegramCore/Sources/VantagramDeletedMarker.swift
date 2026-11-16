import Foundation
import Postbox

/// Text appended to messages that were deleted on the server but are kept locally.
let vantagramDeletedMarker = "🗑 удалено"

/// Keeps the messages but visibly marks them as deleted by the other side.
func vantagramMarkMessagesAsDeleted(transaction: Transaction, ids: [MessageId]) {
    for id in ids {
        transaction.updateMessage(id, update: { currentMessage -> PostboxUpdateMessage in
            if currentMessage.text.hasSuffix(vantagramDeletedMarker) {
                return .skip
            }
            var storeForwardInfo: StoreMessageForwardInfo?
            if let forwardInfo = currentMessage.forwardInfo {
                storeForwardInfo = StoreMessageForwardInfo(authorId: forwardInfo.author?.id, sourceId: forwardInfo.source?.id, sourceMessageId: forwardInfo.sourceMessageId, date: forwardInfo.date, authorSignature: forwardInfo.authorSignature, psaType: forwardInfo.psaType, flags: forwardInfo.flags)
            }
            let updatedText: String
            if currentMessage.text.isEmpty {
                updatedText = vantagramDeletedMarker
            } else {
                updatedText = currentMessage.text + "\n" + vantagramDeletedMarker
            }
            return .update(StoreMessage(id: currentMessage.id, customStableId: nil, globallyUniqueId: currentMessage.globallyUniqueId, groupingKey: currentMessage.groupingKey, threadId: currentMessage.threadId, timestamp: currentMessage.timestamp, flags: StoreMessageFlags(currentMessage.flags), tags: currentMessage.tags, globalTags: currentMessage.globalTags, localTags: currentMessage.localTags, forwardInfo: storeForwardInfo, authorId: currentMessage.author?.id, text: updatedText, attributes: currentMessage.attributes, media: currentMessage.media))
        })
    }
}
