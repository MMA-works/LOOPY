package com.looply.backend.conversation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.looply.backend.user.UserRepository;
import com.looply.backend.message.MessageRepository;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class ConversationIntegrationTest {

    private static final Pattern ACCESS_TOKEN = Pattern.compile("\\\"accessToken\\\":\\\"([^\\\"]+)\\\"");
    private static final Pattern USER_ID = Pattern.compile("\\\"user\\\":\\\"?\\{?[^}]*\\\"id\\\":\\\"([^\\\"]+)\\\"");
    private static final Pattern FIRST_ID = Pattern.compile("\\\"id\\\":\\\"([^\\\"]+)\\\"");

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ConversationRepository conversationRepository;

    @Autowired
    UserRepository userRepository;

    @Autowired
    MessageRepository messageRepository;

    @Autowired
    JdbcTemplate jdbcTemplate;

    @BeforeEach
    void cleanDatabase() {
        messageRepository.deleteAll();
        conversationRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void listsOtherUsersAndCreatesIdempotentDirectConversation() throws Exception {
        RegisteredUser ayan = register("ayan", "Ayan Malik");
        RegisteredUser sara = register("sara", "Sara Khan");
        register("hamza", "Hamza Ali");

        mockMvc.perform(get("/api/v1/users").header("Authorization", bearer(ayan.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].name").value("Hamza Ali"))
                .andExpect(jsonPath("$[1].name").value("Sara Khan"));

        String firstBody = openDirect(ayan.token(), sara.id());
        String secondBody = openDirect(ayan.token(), sara.id());
        UUID firstConversationId = firstId(firstBody);
        UUID secondConversationId = firstId(secondBody);

        assertThat(secondConversationId).isEqualTo(firstConversationId);
        assertThat(conversationRepository.count()).isEqualTo(1);
        Integer participantCount = jdbcTemplate.queryForObject(
                "select count(*) from conversation_participants where conversation_id = ?",
                Integer.class,
                firstConversationId);
        assertThat(participantCount).isEqualTo(2);

        mockMvc.perform(get("/api/v1/conversations").header("Authorization", bearer(sara.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(firstConversationId.toString()))
                .andExpect(jsonPath("$[0].participants.length()").value(2));

        mockMvc.perform(get("/api/v1/conversations/{id}", firstConversationId)
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("DIRECT"));
    }

    @Test
    void rejectsNonParticipantSelfConversationAndUnknownUser() throws Exception {
        RegisteredUser ayan = register("ayan", "Ayan Malik");
        RegisteredUser sara = register("sara", "Sara Khan");
        RegisteredUser outsider = register("noor", "Noor Fatima");
        UUID conversationId = firstId(openDirect(ayan.token(), sara.id()));

        mockMvc.perform(get("/api/v1/conversations/{id}", conversationId)
                        .header("Authorization", bearer(outsider.token())))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.title").value("Resource not found"));

        mockMvc.perform(post("/api/v1/conversations/direct")
                        .header("Authorization", bearer(ayan.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"%s\"}".formatted(ayan.id())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid conversation"));

        mockMvc.perform(post("/api/v1/conversations/direct")
                        .header("Authorization", bearer(ayan.token()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"%s\"}".formatted(UUID.randomUUID())))
                .andExpect(status().isNotFound());
    }

    @Test
    void requiresAuthenticationForDirectoryAndConversations() throws Exception {
        mockMvc.perform(get("/api/v1/users")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/conversations")).andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/v1/conversations/direct")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"%s\"}".formatted(UUID.randomUUID())))
                .andExpect(status().isUnauthorized());
    }

    private RegisteredUser register(String username, String name) throws Exception {
        String body = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"username":"%s","password":"valid-password-21","name":"%s"}
                                """.formatted(username, name)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return new RegisteredUser(extract(ACCESS_TOKEN, body), UUID.fromString(extract(USER_ID, body)));
    }

    private String openDirect(String token, UUID targetUserId) throws Exception {
        return mockMvc.perform(post("/api/v1/conversations/direct")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"%s\"}".formatted(targetUserId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("DIRECT"))
                .andReturn().getResponse().getContentAsString();
    }

    private static UUID firstId(String body) {
        return UUID.fromString(extract(FIRST_ID, body));
    }

    private static String extract(Pattern pattern, String body) {
        Matcher matcher = pattern.matcher(body);
        assertThat(matcher.find()).as("Expected pattern in response: %s", body).isTrue();
        return matcher.group(1);
    }

    private static String bearer(String token) {
        return "Bearer " + token;
    }

    private record RegisteredUser(String token, UUID id) {
    }
}
