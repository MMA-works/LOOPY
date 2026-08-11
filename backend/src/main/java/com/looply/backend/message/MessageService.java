package com.looply.backend.message;

import com.looply.backend.common.ResourceNotFoundException;
import com.looply.backend.conversation.Conversation;
import com.looply.backend.conversation.ConversationParticipant;
import com.looply.backend.conversation.ConversationRepository;
import com.looply.backend.user.User;
import com.looply.backend.user.UserRepository;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final ConversationRepository conversationRepository;
    private final UserRepository userRepository;

    public MessageService(MessageRepository messageRepository, ConversationRepository conversationRepository, UserRepository userRepository) {
        this.messageRepository = messageRepository;
        this.conversationRepository = conversationRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public PersistedMessage sendText(String username, SendTextMessageRequest request) {
        User sender = requireUser(username);
        Conversation conversation = requireConversation(request.conversationId(), sender.getId());
        var existing = messageRepository.findBySenderIdAndClientMessageId(sender.getId(), request.clientMessageId());
        if (existing.isPresent()) {
            Message message = existing.get();
            if (!message.getConversation().getId().equals(conversation.getId())) {
                throw new IllegalArgumentException("Client message ID was already used in another conversation");
            }
            return persisted(message, conversation);
        }

        Instant now = Instant.now();
        Message message = new Message(
                UUID.randomUUID(), conversation, sender, request.text().trim(), request.clientMessageId(), now);
        conversation.touch(now);
        Message saved = messageRepository.save(message);
        return persisted(saved, conversation);
    }

    @Transactional(readOnly = true)
    public MessagePageResponse history(String username, UUID conversationId, String cursor, int limit) {
        User requester = requireUser(username);
        requireConversation(conversationId, requester.getId());
        Cursor decoded = decodeCursor(cursor);
        List<Message> descending = decoded == null
                ? messageRepository.findLatest(conversationId, PageRequest.of(0, limit))
                : messageRepository.findBefore(conversationId, decoded.createdAt(), decoded.id(), PageRequest.of(0, limit));
        String nextCursor = descending.size() == limit ? encodeCursor(descending.getLast()) : null;
        List<MessageResponse> chronological = new ArrayList<>(descending.stream().map(MessageResponse::from).toList());
        Collections.reverse(chronological);
        return new MessagePageResponse(chronological, nextCursor);
    }

    private PersistedMessage persisted(Message message, Conversation conversation) {
        List<String> recipients = conversation.getParticipants().stream()
                .map(ConversationParticipant::getUser)
                .map(User::getUsername)
                .toList();
        return new PersistedMessage(MessageResponse.from(message), recipients);
    }

    private User requireUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private Conversation requireConversation(UUID conversationId, UUID userId) {
        return conversationRepository.findAccessibleById(conversationId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));
    }

    private static String encodeCursor(Message message) {
        String raw = message.getCreatedAt() + "|" + message.getId();
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    private static Cursor decodeCursor(String cursor) {
        if (cursor == null || cursor.isBlank()) {
            return null;
        }
        try {
            String decoded = new String(Base64.getUrlDecoder().decode(cursor), StandardCharsets.UTF_8);
            String[] parts = decoded.split("\\|", 2);
            if (parts.length != 2) {
                throw new IllegalArgumentException("Invalid message cursor");
            }
            return new Cursor(Instant.parse(parts[0]), UUID.fromString(parts[1]));
        } catch (IllegalArgumentException | DateTimeParseException exception) {
            throw new IllegalArgumentException("Invalid message cursor");
        }
    }

    public record PersistedMessage(MessageResponse message, List<String> recipients) {
    }

    private record Cursor(Instant createdAt, UUID id) {
    }
}
