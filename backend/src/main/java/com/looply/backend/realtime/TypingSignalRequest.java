package com.looply.backend.realtime;

import jakarta.validation.constraints.NotBlank;

public record TypingSignalRequest(
    @NotBlank String conversationId,
    boolean isTyping
) {}
