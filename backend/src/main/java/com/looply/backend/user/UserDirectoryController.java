package com.looply.backend.user;

import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserDirectoryController {

    private final UserRepository userRepository;

    public UserDirectoryController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    List<UserSummaryResponse> availableUsers(@AuthenticationPrincipal Jwt jwt) {
        User currentUser = userRepository.findByUsername(jwt.getSubject())
                .orElseThrow(() -> new IllegalStateException("Authenticated user no longer exists"));
        return userRepository.findAllByIdNotOrderByNameAsc(currentUser.getId()).stream()
                .map(UserSummaryResponse::from)
                .toList();
    }
}
