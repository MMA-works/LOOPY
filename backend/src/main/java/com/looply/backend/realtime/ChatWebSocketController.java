package com.looply.backend.realtime;

import com.looply.backend.message.MessageResponse;
import com.looply.backend.message.MessageService;
import com.looply.backend.message.MessageService.PersistedMessage;
import com.looply.backend.message.SendTextMessageRequest;
import com.looply.backend.message.ConversationReadRequest;
import com.looply.backend.message.MessageAcknowledgementRequest;
import com.looply.backend.message.MessageStatusService;
import jakarta.validation.Valid;
import java.security.Principal;
import org.springframework.messaging.handler.annotation.MessageExceptionHandler;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;

@Controller
public class ChatWebSocketController {

    private final MessageService messageService;
    private final SimpMessagingTemplate messagingTemplate;
    private final MessageStatusService statusService;

    public ChatWebSocketController(MessageService messageService, SimpMessagingTemplate messagingTemplate,
            MessageStatusService statusService) {
        this.messageService = messageService;
        this.messagingTemplate = messagingTemplate;
        this.statusService = statusService;
    }

    @MessageMapping("/chat.delivered")
    public void delivered(Principal principal, @Valid MessageAcknowledgementRequest request) {
        broadcast(statusService.delivered(principal.getName(), request.messageId()));
    }

    @MessageMapping("/chat.read")
    public void read(Principal principal, @Valid ConversationReadRequest request) {
        broadcast(statusService.read(principal.getName(), request.conversationId()));
    }

    private void broadcast(MessageStatusService.StatusChanges changes) {
        changes.updates().forEach(update -> changes.recipients().forEach(username ->
                messagingTemplate.convertAndSendToUser(username, "/queue/message-status", update)));
    }

    @MessageMapping("/chat.send")
    public void send(Principal principal, @Valid SendTextMessageRequest request) {
        PersistedMessage persisted = messageService.sendText(principal.getName(), request);
        MessageResponse response = persisted.message();
        persisted.recipients().forEach(username ->
                messagingTemplate.convertAndSendToUser(username, "/queue/messages", response));
    }

    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public RealtimeError error(Exception exception) {
        return new RealtimeError("MESSAGE_REJECTED", exception.getMessage());
    }

    public record RealtimeError(String code, String message) {
    }
}
