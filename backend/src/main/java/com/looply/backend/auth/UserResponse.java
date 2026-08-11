package com.looply.backend.auth;

import com.looply.backend.user.User;
import java.time.Instant;
import java.util.UUID;

public record UserResponse(UUID id, String username, String name, String profilePhotoUrl, Instant createdAt) {
    static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getUsername(), user.getName(), user.getProfilePhotoUrl(), user.getCreatedAt());
    }
}
