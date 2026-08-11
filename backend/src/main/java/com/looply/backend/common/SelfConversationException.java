package com.looply.backend.common;

public class SelfConversationException extends RuntimeException {
    public SelfConversationException() {
        super("A direct conversation requires another user");
    }
}
