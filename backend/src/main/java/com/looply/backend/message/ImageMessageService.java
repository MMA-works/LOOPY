package com.looply.backend.message;

import com.looply.backend.common.ResourceNotFoundException;
import com.looply.backend.conversation.*;
import com.looply.backend.user.*;
import java.io.IOException;
import java.time.Instant;
import java.util.*;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ImageMessageService {
    private static final long MAX_BYTES = 10 * 1024 * 1024;
    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", ".jpg", "image/png", ".png", "image/webp", ".webp");

    private final UserRepository users;
    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final ImageAttachmentRepository attachments;
    private final ImageStorageService storage;

    public ImageMessageService(UserRepository users, ConversationRepository conversations,
            MessageRepository messages, ImageAttachmentRepository attachments, ImageStorageService storage) {
        this.users = users;
        this.conversations = conversations;
        this.messages = messages;
        this.attachments = attachments;
        this.storage = storage;
    }

    @Transactional
    public MessageService.PersistedMessage upload(String username, UUID conversationId,
            String clientMessageId, MultipartFile file) {
        User sender = requireUser(username);
        Conversation conversation = conversations.findAccessibleById(conversationId, sender.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));
        Message existing = messages.findBySenderIdAndClientMessageId(sender.getId(), clientMessageId).orElse(null);
        if (existing != null) {
            if (existing.getType() != MessageType.IMAGE || !existing.getConversation().getId().equals(conversationId))
                throw new IllegalArgumentException("Client message ID was already used");
            return persisted(existing, conversation);
        }
        String type = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        if (file.isEmpty() || file.getSize() > MAX_BYTES)
            throw new IllegalArgumentException("Image must be between 1 byte and 10 MB");
        if (!EXTENSIONS.containsKey(type)) throw new IllegalArgumentException("Only JPEG, PNG, and WebP images are supported");

        Instant now = Instant.now();
        Message message = messages.save(Message.image(UUID.randomUUID(), conversation, sender, clientMessageId, now));
        UUID attachmentId = UUID.randomUUID();
        String key;
        try { key = storage.store(attachmentId, EXTENSIONS.get(type), file.getInputStream()); }
        catch (IOException exception) { throw new IllegalStateException("Could not read image upload", exception); }
        try {
            ImageAttachment attachment = attachments.save(new ImageAttachment(attachmentId, message, key,
                    file.getOriginalFilename(), type, file.getSize(), now));
            message.attachImage(attachment);
            conversation.touch(now);
            messages.flush();
            return persisted(message, conversation);
        } catch (RuntimeException exception) {
            storage.deleteQuietly(key);
            throw exception;
        }
    }

    @Transactional(readOnly = true)
    public StoredImage content(String username, UUID attachmentId) {
        User user = requireUser(username);
        ImageAttachment attachment = attachments.findAccessible(attachmentId, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Image message not found"));
        return new StoredImage(storage.load(attachment.getStorageKey()), attachment.getContentType(), attachment.getFileSize());
    }

    private User requireUser(String username) {
        return users.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private MessageService.PersistedMessage persisted(Message message, Conversation conversation) {
        List<String> recipients = conversation.getParticipants().stream().map(ConversationParticipant::getUser)
                .map(User::getUsername).toList();
        return new MessageService.PersistedMessage(MessageResponse.from(message), recipients);
    }

    public record StoredImage(Resource resource, String contentType, long size) {}
}
