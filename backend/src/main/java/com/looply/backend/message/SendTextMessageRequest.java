package com.looply.backend.message;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record SendTextMessageRequest(
        @NotNull UUID conversationId,
        @NotBlank @Size(max = 4000) String text,
        @NotBlank @Size(max = 100) String clientMessageId) {
}
