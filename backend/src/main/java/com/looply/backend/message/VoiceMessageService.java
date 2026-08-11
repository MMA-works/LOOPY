package com.looply.backend.message;

import com.looply.backend.common.ResourceNotFoundException;
import com.looply.backend.conversation.Conversation;
import com.looply.backend.conversation.ConversationParticipant;
import com.looply.backend.conversation.ConversationRepository;
import com.looply.backend.user.User;
import com.looply.backend.user.UserRepository;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class VoiceMessageService {
    private static final long MAX_BYTES = 10 * 1024 * 1024;
    private static final int MAX_DURATION_MS = 5 * 60 * 1000;
    private static final Map<String, String> EXTENSIONS = Map.of(
            "audio/webm", ".webm", "audio/ogg", ".ogg", "audio/mp4", ".m4a",
            "audio/mpeg", ".mp3", "audio/wav", ".wav", "audio/x-m4a", ".m4a");

    private final UserRepository users;
    private final ConversationRepository conversations;
    private final MessageRepository messages;
    private final VoiceAttachmentRepository attachments;
    private final VoiceStorageService storage;

    public VoiceMessageService(UserRepository users, ConversationRepository conversations,
            MessageRepository messages, VoiceAttachmentRepository attachments, VoiceStorageService storage) {
        this.users = users;
        this.conversations = conversations;
        this.messages = messages;
        this.attachments = attachments;
        this.storage = storage;
    }

    @Transactional
    public MessageService.PersistedMessage upload(String username, UUID conversationId,
            String clientMessageId, int durationMs, MultipartFile file) {
        User sender = requireUser(username);
        Conversation conversation = conversations.findAccessibleById(conversationId, sender.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));
        Message existing = messages.findBySenderIdAndClientMessageId(sender.getId(), clientMessageId).orElse(null);
        if (existing != null) {
            if (existing.getType() != MessageType.VOICE || !existing.getConversation().getId().equals(conversationId)) {
                throw new IllegalArgumentException("Client message ID was already used");
            }
            return persisted(existing, conversation);
        }
        String type = file.getContentType() == null ? "" : file.getContentType().toLowerCase(Locale.ROOT);
        if (file.isEmpty() || file.getSize() > MAX_BYTES) throw new IllegalArgumentException("Voice file must be between 1 byte and 10 MB");
        if (!EXTENSIONS.containsKey(type)) throw new IllegalArgumentException("Unsupported voice file type");
        if (durationMs < 1 || durationMs > MAX_DURATION_MS) throw new IllegalArgumentException("Voice duration must be between 1 ms and 5 minutes");

        Instant now = Instant.now();
        Message message = messages.save(Message.voice(UUID.randomUUID(), conversation, sender, clientMessageId, now));
        UUID attachmentId = UUID.randomUUID();
        String key;
        try {
            key = storage.store(attachmentId, EXTENSIONS.get(type), file.getInputStream());
        } catch (IOException exception) {
            throw new IllegalStateException("Could not read voice upload", exception);
        }
        try {
            VoiceAttachment attachment = attachments.save(new VoiceAttachment(attachmentId, message, key, file.getOriginalFilename(),
                    type, file.getSize(), durationMs, now));
            message.attachVoice(attachment);
            conversation.touch(now);
            messages.flush();
            return persisted(message, conversation);
        } catch (RuntimeException exception) {
            storage.deleteQuietly(key);
            throw exception;
        }
    }

    @Transactional(readOnly = true)
    public StoredVoice content(String username, UUID attachmentId) {
        User user = requireUser(username);
        VoiceAttachment attachment = attachments.findAccessible(attachmentId, user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Voice message not found"));
        return new StoredVoice(storage.load(attachment.getStorageKey()), attachment.getContentType(), attachment.getFileSize());
    }

    private User requireUser(String username) {
        return users.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private MessageService.PersistedMessage persisted(Message message, Conversation conversation) {
        List<String> recipients = conversation.getParticipants().stream().map(ConversationParticipant::getUser)
                .map(User::getUsername).toList();
        return new MessageService.PersistedMessage(MessageResponse.from(message), recipients);
    }

    public record StoredVoice(Resource resource, String contentType, long size) {}
}
