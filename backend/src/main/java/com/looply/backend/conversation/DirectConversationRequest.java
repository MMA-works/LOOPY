package com.looply.backend.conversation;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record DirectConversationRequest(@NotNull UUID userId) {
}
