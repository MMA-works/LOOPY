package com.looply.backend.user;

import java.util.UUID;

public record UserSummaryResponse(UUID id, String username, String name, String profilePhotoUrl) {
    public static UserSummaryResponse from(User user) {
        return new UserSummaryResponse(user.getId(), user.getUsername(), user.getName(), user.getProfilePhotoUrl());
    }
}
