package com.looply.backend.realtime;

import jakarta.validation.constraints.NotBlank;

public record CallSignalRequest(
    @NotBlank String conversationId,
    @NotBlank String type,
    String data,
    String callerId,
    String callerName
) {}
