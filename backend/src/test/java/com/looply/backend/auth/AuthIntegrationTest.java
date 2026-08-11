package com.looply.backend.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.looply.backend.user.UserRepository;
import com.looply.backend.conversation.ConversationRepository;
import com.looply.backend.message.MessageRepository;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class AuthIntegrationTest {

    private static final Pattern ACCESS_TOKEN = Pattern.compile("\\\"accessToken\\\":\\\"([^\\\"]+)\\\"");

    @Autowired
    MockMvc mockMvc;

    @Autowired
    UserRepository userRepository;

    @Autowired
    ConversationRepository conversationRepository;

    @Autowired
    MessageRepository messageRepository;

    @Autowired
    PasswordEncoder passwordEncoder;

    @BeforeEach
    void cleanUsers() {
        messageRepository.deleteAll();
        conversationRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void registersUserHashesPasswordAndReturnsToken() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"Ayan_01","password":"very-secret-password","name":"Ayan Malik"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.username").value("ayan_01"))
                .andExpect(jsonPath("$.user.name").value("Ayan Malik"));

        var saved = userRepository.findByUsername("ayan_01").orElseThrow();
        assertThat(saved.getPasswordHash()).doesNotContain("very-secret-password");
        assertThat(passwordEncoder.matches("very-secret-password", saved.getPasswordHash())).isTrue();
    }

    @Test
    void loginTokenCanAccessProtectedCurrentUserEndpoint() throws Exception {
        register("sara", "correct-password", "Sara Khan");

        String body = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"SARA","password":"correct-password"}
                                """))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        Matcher matcher = ACCESS_TOKEN.matcher(body);
        assertThat(matcher.find()).isTrue();
        String token = matcher.group(1);

        mockMvc.perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("sara"))
                .andExpect(jsonPath("$.name").value("Sara Khan"));
    }

    @Test
    void rejectsDuplicateUsernameInvalidLoginAndAnonymousProtectedAccess() throws Exception {
        register("hamza", "correct-password", "Hamza Ali");

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"HAMZA","password":"another-password","name":"Other Hamza"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.title").value("Username unavailable"));

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"hamza","password":"wrong-password"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.title").value("Authentication failed"));

        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void returnsUsefulValidationErrors() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"a!","password":"short","name":""}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Validation failed"))
                .andExpect(jsonPath("$.errors.username").exists())
                .andExpect(jsonPath("$.errors.password").exists())
                .andExpect(jsonPath("$.errors.name").exists());
    }

    private void register(String username, String password, String name) throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"%s","password":"%s","name":"%s"}
                                """.formatted(username, password, name)))
                .andExpect(status().isCreated());
    }
}
