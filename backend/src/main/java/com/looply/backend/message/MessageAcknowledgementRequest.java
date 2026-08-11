package com.looply.backend.message;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record MessageAcknowledgementRequest(@NotNull UUID messageId) {}
