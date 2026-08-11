package com.looply.backend.message;

import com.looply.backend.conversation.Conversation;
import com.looply.backend.user.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "messages")
public class Message {

    @Id
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "conversation_id")
    private Conversation conversation;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id")
    private User sender;

    @Enumerated(EnumType.STRING)
    @Column(name = "message_type", nullable = false, length = 20)
    private MessageType type;

    @Column(name = "text_content")
    private String textContent;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MessageStatus status;

    @Column(name = "client_message_id", length = 100)
    private String clientMessageId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "read_at")
    private Instant readAt;

    @OneToOne(mappedBy = "message", fetch = FetchType.LAZY)
    private VoiceAttachment voiceAttachment;

    @OneToOne(mappedBy = "message", fetch = FetchType.LAZY)
    private ImageAttachment imageAttachment;

    protected Message() {
    }

    public Message(UUID id, Conversation conversation, User sender, String textContent, String clientMessageId, Instant createdAt) {
        this.id = id;
        this.conversation = conversation;
        this.sender = sender;
        this.type = MessageType.TEXT;
        this.textContent = textContent;
        this.status = MessageStatus.SENT;
        this.clientMessageId = clientMessageId;
        this.createdAt = createdAt;
    }

    public static Message voice(UUID id, Conversation conversation, User sender, String clientMessageId, Instant createdAt) {
        Message message = new Message();
        message.id = id;
        message.conversation = conversation;
        message.sender = sender;
        message.type = MessageType.VOICE;
        message.status = MessageStatus.SENT;
        message.clientMessageId = clientMessageId;
        message.createdAt = createdAt;
        return message;
    }

    public static Message image(UUID id, Conversation conversation, User sender, String clientMessageId, Instant createdAt) {
        Message message = new Message();
        message.id = id;
        message.conversation = conversation;
        message.sender = sender;
        message.type = MessageType.IMAGE;
        message.status = MessageStatus.SENT;
        message.clientMessageId = clientMessageId;
        message.createdAt = createdAt;
        return message;
    }

    public UUID getId() { return id; }
    public Conversation getConversation() { return conversation; }
    public User getSender() { return sender; }
    public MessageType getType() { return type; }
    public String getTextContent() { return textContent; }
    public MessageStatus getStatus() { return status; }
    public String getClientMessageId() { return clientMessageId; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getReadAt() { return readAt; }
    public VoiceAttachment getVoiceAttachment() { return voiceAttachment; }
    void attachVoice(VoiceAttachment attachment) { this.voiceAttachment = attachment; }
    public ImageAttachment getImageAttachment() { return imageAttachment; }
    void attachImage(ImageAttachment attachment) { this.imageAttachment = attachment; }

    public boolean markDelivered() {
        if (status != MessageStatus.SENT) return false;
        status = MessageStatus.DELIVERED;
        return true;
    }

    public boolean markRead(Instant now) {
        if (status == MessageStatus.READ) return false;
        status = MessageStatus.READ;
        readAt = now;
        return true;
    }
}
