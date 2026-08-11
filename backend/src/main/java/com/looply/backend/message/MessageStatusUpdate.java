package com.looply.backend.message;

import java.time.Instant;
import java.util.UUID;

public record MessageStatusUpdate(UUID messageId, UUID conversationId,
        MessageStatus status, Instant readAt) {
    static MessageStatusUpdate from(Message message) {
        return new MessageStatusUpdate(message.getId(), message.getConversation().getId(),
                message.getStatus(), message.getReadAt());
    }
}
