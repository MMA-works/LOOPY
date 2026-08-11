package com.looply.backend.conversation;

import com.looply.backend.user.UserSummaryResponse;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record ConversationResponse(
        UUID id,
        ConversationType type,
        List<UserSummaryResponse> participants,
        Instant createdAt,
        Instant updatedAt) {

    static ConversationResponse from(Conversation conversation) {
        return new ConversationResponse(
                conversation.getId(),
                conversation.getType(),
                conversation.getParticipants().stream()
                        .map(ConversationParticipant::getUser)
                        .map(UserSummaryResponse::from)
                        .toList(),
                conversation.getCreatedAt(),
                conversation.getUpdatedAt());
    }
}
