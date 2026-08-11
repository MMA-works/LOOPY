package com.looply.backend.auth;

import com.looply.backend.common.UsernameAlreadyExistsException;
import com.looply.backend.security.TokenService;
import com.looply.backend.security.TokenService.IssuedToken;
import com.looply.backend.user.User;
import com.looply.backend.user.UserRepository;
import java.time.Instant;
import java.util.Locale;
import java.util.UUID;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TokenService tokenService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, TokenService tokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String username = normalize(request.username());
        if (userRepository.existsByUsername(username)) {
            throw new UsernameAlreadyExistsException();
        }
        Instant now = Instant.now();
        User user = new User(UUID.randomUUID(), username, passwordEncoder.encode(request.password()), request.name().trim(), now);
        return response(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(normalize(request.username()))
                .orElseThrow(() -> new BadCredentialsException("Invalid username or password"));
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid username or password");
        }
        return response(user);
    }

    @Transactional(readOnly = true)
    public UserResponse currentUser(String username) {
        return userRepository.findByUsername(normalize(username))
                .map(UserResponse::from)
                .orElseThrow(() -> new BadCredentialsException("Authenticated user no longer exists"));
    }

    private AuthResponse response(User user) {
        IssuedToken token = tokenService.issue(user);
        return new AuthResponse(token.value(), "Bearer", token.expiresAt(), UserResponse.from(user));
    }

    private static String normalize(String username) {
        return username.trim().toLowerCase(Locale.ROOT);
    }
}
