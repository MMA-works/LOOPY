package com.looply.backend.conversation;

import com.looply.backend.common.ResourceNotFoundException;
import com.looply.backend.common.SelfConversationException;
import com.looply.backend.user.User;
import com.looply.backend.user.UserRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ConversationService {

    private final ConversationRepository conversationRepository;
    private final UserRepository userRepository;

    public ConversationService(ConversationRepository conversationRepository, UserRepository userRepository) {
        this.conversationRepository = conversationRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ConversationResponse openDirect(String username, UUID targetUserId) {
        User requester = requireUser(username);
        if (requester.getId().equals(targetUserId)) {
            throw new SelfConversationException();
        }

        List<UUID> ids = new ArrayList<>(List.of(requester.getId(), targetUserId));
        ids.sort(Comparator.naturalOrder());
        List<User> lockedUsers = userRepository.lockAllByIds(ids);
        if (lockedUsers.size() != 2) {
            throw new ResourceNotFoundException("User not found");
        }

        String directKey = ids.get(0) + ":" + ids.get(1);
        return conversationRepository.findByDirectKey(directKey)
                .map(ConversationResponse::from)
                .orElseGet(() -> createDirect(directKey, lockedUsers));
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> list(String username) {
        User requester = requireUser(username);
        return conversationRepository.findAllForUser(requester.getId()).stream()
                .map(ConversationResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public ConversationResponse get(String username, UUID conversationId) {
        User requester = requireUser(username);
        return conversationRepository.findAccessibleById(conversationId, requester.getId())
                .map(ConversationResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException("Conversation not found"));
    }

    private ConversationResponse createDirect(String directKey, List<User> users) {
        Instant now = Instant.now();
        Conversation conversation = new Conversation(UUID.randomUUID(), directKey, now);
        users.forEach(user -> conversation.addParticipant(new ConversationParticipant(conversation, user, now)));
        return ConversationResponse.from(conversationRepository.save(conversation));
    }

    private User requireUser(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}
