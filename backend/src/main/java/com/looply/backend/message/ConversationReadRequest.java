package com.looply.backend.message;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ConversationReadRequest(@NotNull UUID conversationId) {}
