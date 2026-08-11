package com.looply.backend.auth;

import java.time.Instant;

public record AuthResponse(String accessToken, String tokenType, Instant expiresAt, UserResponse user) {
}
