package com.looply.backend.message;

import java.time.Instant;
import java.util.UUID;

public record MessageResponse(
        UUID id,
        UUID conversationId,
        UUID senderId,
        MessageType messageType,
        String textContent,
        MessageStatus status,
        String clientMessageId,
        String voiceFileUrl,
        Integer voiceDuration,
        String voiceContentType,
        String imageFileUrl,
        String imageContentType,
        Instant createdAt,
        Instant readAt) {

    static MessageResponse from(Message message) {
        VoiceAttachment voice = message.getType() == MessageType.VOICE ? message.getVoiceAttachment() : null;
        ImageAttachment image = message.getType() == MessageType.IMAGE ? message.getImageAttachment() : null;
        return new MessageResponse(
                message.getId(), message.getConversation().getId(), message.getSender().getId(),
                message.getType(), message.getTextContent(), message.getStatus(),
                message.getClientMessageId(),
                voice == null ? null : "/api/v1/voice/" + voice.getId() + "/content",
                voice == null ? null : voice.getDurationMs(),
                voice == null ? null : voice.getContentType(),
                image == null ? null : "/api/v1/images/" + image.getId() + "/content",
                image == null ? null : image.getContentType(),
                message.getCreatedAt(), message.getReadAt());
    }
}
