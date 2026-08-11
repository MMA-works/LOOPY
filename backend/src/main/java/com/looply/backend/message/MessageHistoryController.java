package com.looply.backend.message;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/conversations/{conversationId}/messages")
public class MessageHistoryController {

    private final MessageService messageService;

    public MessageHistoryController(MessageService messageService) {
        this.messageService = messageService;
    }

    @GetMapping
    MessagePageResponse history(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable UUID conversationId,
            @RequestParam(required = false) String before,
            @RequestParam(defaultValue = "50") @Min(1) @Max(100) int limit) {
        return messageService.history(jwt.getSubject(), conversationId, before, limit);
    }
}
