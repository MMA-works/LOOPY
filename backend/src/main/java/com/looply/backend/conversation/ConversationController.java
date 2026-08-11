package com.looply.backend.conversation;

import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/conversations")
public class ConversationController {

    private final ConversationService conversationService;

    public ConversationController(ConversationService conversationService) {
        this.conversationService = conversationService;
    }

    @PostMapping("/direct")
    ConversationResponse openDirect(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody DirectConversationRequest request) {
        return conversationService.openDirect(jwt.getSubject(), request.userId());
    }

    @GetMapping
    List<ConversationResponse> list(@AuthenticationPrincipal Jwt jwt) {
        return conversationService.list(jwt.getSubject());
    }

    @GetMapping("/{conversationId}")
    ConversationResponse get(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID conversationId) {
        return conversationService.get(jwt.getSubject(), conversationId);
    }
}
