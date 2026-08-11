package com.looply.backend.message;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.looply.backend.conversation.ConversationRepository;
import com.looply.backend.user.UserRepository;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class MessageIntegrationTest {

    private static final Pattern TOKEN = Pattern.compile("\\\"accessToken\\\":\\\"([^\\\"]+)\\\"");
    private static final Pattern USER_ID = Pattern.compile("\\\"user\\\":\\\"?\\{?[^}]*\\\"id\\\":\\\"([^\\\"]+)\\\"");
    private static final Pattern FIRST_ID = Pattern.compile("\\\"id\\\":\\\"([^\\\"]+)\\\"");

    @Autowired MockMvc mockMvc;
    @Autowired MessageService messageService;
    @Autowired MessageStatusService messageStatusService;
    @Autowired MessageRepository messageRepository;
    @Autowired VoiceAttachmentRepository voiceAttachmentRepository;
    @Autowired ImageAttachmentRepository imageAttachmentRepository;
    @Autowired ConversationRepository conversationRepository;
    @Autowired UserRepository userRepository;

    @BeforeEach
    void cleanDatabase() {
        imageAttachmentRepository.deleteAll();
        voiceAttachmentRepository.deleteAll();
        messageRepository.deleteAll();
        conversationRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void uploadsAuthorizedImageAndReturnsItInHistory() throws Exception {
        RegisteredUser ayan = register("imageayan", "Image Ayan");
        RegisteredUser sara = register("imagesara", "Image Sara");
        UUID conversationId = openDirect(ayan.token(), sara.id());
        MockMultipartFile file = new MockMultipartFile("file", "photo.jpg", "image/jpeg",
                new byte[] {(byte) 0xff, (byte) 0xd8, 1, 2, 3});

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart(
                        "/api/v1/conversations/{id}/images", conversationId)
                        .file(file).param("clientMessageId", "image-client-1")
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageType").value("IMAGE"))
                .andExpect(jsonPath("$.imageFileUrl").isNotEmpty())
                .andExpect(jsonPath("$.imageContentType").value("image/jpeg"));

        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .header("Authorization", bearer(sara.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messages[0].messageType").value("IMAGE"))
                .andExpect(jsonPath("$.messages[0].imageFileUrl").isNotEmpty());
    }

    @Test
    void uploadsAuthorizedVoiceAndReturnsItInHistory() throws Exception {
        RegisteredUser ayan = register("voiceayan", "Voice Ayan");
        RegisteredUser sara = register("voicesara", "Voice Sara");
        UUID conversationId = openDirect(ayan.token(), sara.id());
        MockMultipartFile file = new MockMultipartFile("file", "note.webm", "audio/webm", new byte[] {1, 2, 3, 4});

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart(
                        "/api/v1/conversations/{id}/voice", conversationId)
                        .file(file).param("clientMessageId", "voice-client-1").param("durationMs", "1400")
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageType").value("VOICE"))
                .andExpect(jsonPath("$.voiceDuration").value(1400))
                .andExpect(jsonPath("$.voiceFileUrl").isNotEmpty());

        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .header("Authorization", bearer(sara.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messages[0].messageType").value("VOICE"))
                .andExpect(jsonPath("$.messages[0].voiceDuration").value(1400));
    }

    @Test
    void rejectsUnsupportedVoiceType() throws Exception {
        RegisteredUser ayan = register("badvoiceayan", "Bad Voice Ayan");
        RegisteredUser sara = register("badvoicesara", "Bad Voice Sara");
        UUID conversationId = openDirect(ayan.token(), sara.id());
        MockMultipartFile file = new MockMultipartFile("file", "note.txt", "text/plain", new byte[] {1});

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart(
                        "/api/v1/conversations/{id}/voice", conversationId)
                        .file(file).param("clientMessageId", "bad-voice-1").param("durationMs", "500")
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isBadRequest());
    }

    @Test
    void persistsIdempotentTextAndReturnsPaginatedHistory() throws Exception {
        RegisteredUser ayan = register("messageayan", "Message Ayan");
        RegisteredUser sara = register("messagesara", "Message Sara");
        UUID conversationId = openDirect(ayan.token(), sara.id());

        var first = messageService.sendText("messageayan", new SendTextMessageRequest(conversationId, "First", "client-1"));
        messageService.sendText("messagesara", new SendTextMessageRequest(conversationId, "Second", "client-2"));
        messageService.sendText("messageayan", new SendTextMessageRequest(conversationId, "Third", "client-3"));
        var duplicate = messageService.sendText("messageayan", new SendTextMessageRequest(conversationId, "First", "client-1"));

        assertThat(duplicate.message().id()).isEqualTo(first.message().id());
        assertThat(messageRepository.count()).isEqualTo(3);
        assertThat(first.recipients()).containsExactlyInAnyOrder("messageayan", "messagesara");

        String firstPage = mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .param("limit", "2")
                        .header("Authorization", bearer(sara.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messages.length()").value(2))
                .andExpect(jsonPath("$.messages[0].textContent").value("Second"))
                .andExpect(jsonPath("$.messages[1].textContent").value("Third"))
                .andExpect(jsonPath("$.nextCursor").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        String cursor = extract(Pattern.compile("\\\"nextCursor\\\":\\\"([^\\\"]+)\\\""), firstPage);
        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .param("limit", "2")
                        .param("before", cursor)
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messages.length()").value(1))
                .andExpect(jsonPath("$.messages[0].textContent").value("First"))
                .andExpect(jsonPath("$.nextCursor").doesNotExist());
    }

    @Test
    void blocksOutsiderHistoryAndInvalidCursor() throws Exception {
        RegisteredUser ayan = register("secureayan", "Secure Ayan");
        RegisteredUser sara = register("securesara", "Secure Sara");
        RegisteredUser outsider = register("outsider", "Outside User");
        UUID conversationId = openDirect(ayan.token(), sara.id());

        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .header("Authorization", bearer(outsider.token())))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/v1/conversations/{id}/messages", conversationId)
                        .param("before", "not-a-cursor")
                        .header("Authorization", bearer(ayan.token())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid request"));
    }

    @Test
    void transitionsIncomingMessageFromSentToDeliveredToReadAndPersistsTimestamp() throws Exception {
        RegisteredUser ayan = register("statusayan", "Status Ayan");
        RegisteredUser sara = register("statussara", "Status Sara");
        UUID conversationId = openDirect(ayan.token(), sara.id());
        var sent = messageService.sendText("statusayan",
                new SendTextMessageRequest(conversationId, "Track me", "status-client-1"));

        var delivered = messageStatusService.delivered("statussara", sent.message().id());
        assertThat(delivered.updates()).singleElement()
                .extracting(MessageStatusUpdate::status).isEqualTo(MessageStatus.DELIVERED);

        var read = messageStatusService.read("statussara", conversationId);
        assertThat(read.updates()).singleElement()
                .satisfies(update -> {
                    assertThat(update.status()).isEqualTo(MessageStatus.READ);
                    assertThat(update.readAt()).isNotNull();
                });
        Message persisted = messageRepository.findById(sent.message().id()).orElseThrow();
        assertThat(persisted.getStatus()).isEqualTo(MessageStatus.READ);
        assertThat(persisted.getReadAt()).isNotNull();
        assertThat(messageStatusService.read("statussara", conversationId).updates()).isEmpty();
    }

    @Test
    void rejectsSenderAndOutsiderAcknowledgements() throws Exception {
        RegisteredUser ayan = register("ackayan", "Ack Ayan");
        RegisteredUser sara = register("acksara", "Ack Sara");
        register("ackoutsider", "Ack Outsider");
        UUID conversationId = openDirect(ayan.token(), sara.id());
        var sent = messageService.sendText("ackayan",
                new SendTextMessageRequest(conversationId, "Secure ack", "ack-client-1"));

        assertThatThrownBy(() -> messageStatusService.delivered("ackayan", sent.message().id()))
                .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> messageStatusService.delivered("ackoutsider", sent.message().id()))
                .isInstanceOf(com.looply.backend.common.ResourceNotFoundException.class);
    }

    private RegisteredUser register(String username, String name) throws Exception {
        String body = mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"%s\",\"password\":\"valid-password-41\",\"name\":\"%s\"}".formatted(username, name)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return new RegisteredUser(extract(TOKEN, body), UUID.fromString(extract(USER_ID, body)));
    }

    private UUID openDirect(String token, UUID userId) throws Exception {
        String body = mockMvc.perform(post("/api/v1/conversations/direct")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"%s\"}".formatted(userId)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return UUID.fromString(extract(FIRST_ID, body));
    }

    private static String extract(Pattern pattern, String body) {
        Matcher matcher = pattern.matcher(body);
        assertThat(matcher.find()).as("Expected value in %s", body).isTrue();
        return matcher.group(1);
    }

    private static String bearer(String token) { return "Bearer " + token; }
    private record RegisteredUser(String token, UUID id) {}
}
