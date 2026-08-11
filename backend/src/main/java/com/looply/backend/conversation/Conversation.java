package com.looply.backend.conversation;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "conversations")
public class Conversation {

    @Id
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(name = "conversation_type", nullable = false, length = 20)
    private ConversationType type;

    @Column(name = "direct_key", unique = true, length = 73)
    private String directKey;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ConversationParticipant> participants = new ArrayList<>();

    protected Conversation() {
    }

    public Conversation(UUID id, String directKey, Instant now) {
        this.id = id;
        this.type = ConversationType.DIRECT;
        this.directKey = directKey;
        this.createdAt = now;
        this.updatedAt = now;
    }

    public void addParticipant(ConversationParticipant participant) {
        participants.add(participant);
    }

    public UUID getId() {
        return id;
    }

    public ConversationType getType() {
        return type;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public List<ConversationParticipant> getParticipants() {
        return List.copyOf(participants);
    }

    public void touch(Instant now) {
        this.updatedAt = now;
    }
}
