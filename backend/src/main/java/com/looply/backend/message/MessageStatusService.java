package com.looply.backend.message;

import com.looply.backend.common.ResourceNotFoundException;
import com.looply.backend.conversation.Conversation;
import com.looply.backend.conversation.ConversationParticipant;
import com.looply.backend.conversation.ConversationRepository;
import com.looply.backend.user.User;
import com.looply.backend.user.UserRepository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MessageStatusService {
    private final MessageRepository messages;
    private final ConversationRepository conversations;
    private final UserRepository users;

    public MessageStatusService(MessageRepository messages, ConversationRepository conversations,
            UserRepository users) {
        this.messages = messages;
        this.conversations = conversations;
        this.users = users;
    }

    @Transactional
    public StatusChanges delivered(String username, UUID messageId) {
        User receiver = requireUser(username);
        Message message = messages.findLockedById(messageId)
                .orElseThrow(() -> new ResourceNotFoundException("Message not found"));
        Conversation conversation = conversations.findAccessibleById(
                message.getConversation().getId(), receiver.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Message not found"));
        if (message.getSender().getId().equals(receiver.getId())) {
            throw new IllegalArgumentException("Sender cannot acknowledge their own message");
        }
        return new StatusChanges(message.markDelivered() ? List.of(MessageStatusUpdate.from(message)) : List.of(),
                recipients(conversation));
    }

    @Transactional
    public StatusChanges read(String username, UUID conversationId) {
        User reader = requireUser(username);
        Conversation conversation = conversations.findAccessibleById(conversationId, reader.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));
        List<Message> unread = messages.findUnreadIncoming(conversationId, reader.getId());
        if (unread.isEmpty()) return new StatusChanges(List.of(), recipients(conversation));
        Instant now = Instant.now();
        unread.forEach(message -> message.markRead(now));
        UUID lastMessageId = unread.getLast().getId();
        conversation.getParticipants().stream()
                .filter(participant -> participant.getUser().getId().equals(reader.getId()))
                .findFirst().ifPresent(participant -> participant.markRead(lastMessageId, now));
        return new StatusChanges(unread.stream().map(MessageStatusUpdate::from).toList(), recipients(conversation));
    }

    private User requireUser(String username) {
        return users.findByUsername(username).orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private List<String> recipients(Conversation conversation) {
        return conversation.getParticipants().stream().map(ConversationParticipant::getUser)
                .map(User::getUsername).toList();
    }

    public record StatusChanges(List<MessageStatusUpdate> updates, List<String> recipients) {}
}
