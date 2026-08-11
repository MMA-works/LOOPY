package com.looply.backend.message;

import java.security.Principal;
import java.util.UUID;
import org.springframework.http.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
public class ImageMessageController {
    private final ImageMessageService service;
    private final SimpMessagingTemplate messaging;

    public ImageMessageController(ImageMessageService service, SimpMessagingTemplate messaging) {
        this.service = service;
        this.messaging = messaging;
    }

    @PostMapping(path = "/api/v1/conversations/{conversationId}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    MessageResponse upload(Principal principal, @PathVariable UUID conversationId,
            @RequestParam String clientMessageId, @RequestParam MultipartFile file) {
        var persisted = service.upload(principal.getName(), conversationId, clientMessageId, file);
        persisted.recipients().forEach(username -> messaging.convertAndSendToUser(username, "/queue/messages", persisted.message()));
        return persisted.message();
    }

    @GetMapping("/api/v1/images/{attachmentId}/content")
    ResponseEntity<org.springframework.core.io.Resource> content(Principal principal, @PathVariable UUID attachmentId) {
        var stored = service.content(principal.getName(), attachmentId);
        return ResponseEntity.ok().cacheControl(CacheControl.noCache())
                .contentType(MediaType.parseMediaType(stored.contentType()))
                .contentLength(stored.size()).body(stored.resource());
    }
}
