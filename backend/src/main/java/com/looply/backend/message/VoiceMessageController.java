package com.looply.backend.message;

import java.security.Principal;
import java.util.UUID;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class VoiceMessageController {
    private final VoiceMessageService service;
    private final SimpMessagingTemplate messaging;

    public VoiceMessageController(VoiceMessageService service, SimpMessagingTemplate messaging) {
        this.service = service;
        this.messaging = messaging;
    }

    @PostMapping(path = "/api/v1/conversations/{conversationId}/voice", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    MessageResponse upload(Principal principal, @PathVariable UUID conversationId,
            @RequestParam String clientMessageId, @RequestParam int durationMs, @RequestParam MultipartFile file) {
        var persisted = service.upload(principal.getName(), conversationId, clientMessageId, durationMs, file);
        persisted.recipients().forEach(username -> messaging.convertAndSendToUser(username, "/queue/messages", persisted.message()));
        return persisted.message();
    }

    @GetMapping("/api/v1/voice/{attachmentId}/content")
    ResponseEntity<org.springframework.core.io.Resource> content(Principal principal, @PathVariable UUID attachmentId) {
        var stored = service.content(principal.getName(), attachmentId);
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noCache())
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .contentType(MediaType.parseMediaType(stored.contentType()))
                .contentLength(stored.size())
                .body(stored.resource());
    }
}
