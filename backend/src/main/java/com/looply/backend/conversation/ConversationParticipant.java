package com.looply.backend.conversation;

import com.looply.backend.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "conversation_participants")
public class ConversationParticipant {

    @EmbeddedId
    private ConversationParticipantId id;

    @MapsId("conversationId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id")
    private Conversation conversation;

    @MapsId("userId")
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "joined_at", nullable = false)
    private Instant joinedAt;

    @Column(name = "last_read_message_id")
    private UUID lastReadMessageId;

    @Column(name = "last_read_at")
    private Instant lastReadAt;

    protected ConversationParticipant() {
    }

    public ConversationParticipant(Conversation conversation, User user, Instant joinedAt) {
        this.id = new ConversationParticipantId(conversation.getId(), user.getId());
        this.conversation = conversation;
        this.user = user;
        this.joinedAt = joinedAt;
    }

    public User getUser() {
        return user;
    }

    public Instant getJoinedAt() {
        return joinedAt;
    }

    public void markRead(UUID messageId, Instant now) {
        lastReadMessageId = messageId;
        lastReadAt = now;
    }
}
