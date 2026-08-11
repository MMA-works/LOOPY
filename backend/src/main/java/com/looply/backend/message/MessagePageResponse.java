package com.looply.backend.message;

import java.util.List;

public record MessagePageResponse(List<MessageResponse> messages, String nextCursor) {
}
