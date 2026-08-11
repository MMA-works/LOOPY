CREATE TABLE app_users (
    id UUID PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    profile_photo_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_app_users_username UNIQUE (username),
    CONSTRAINT ck_app_users_username_normalized CHECK (username = LOWER(username))
);

CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    conversation_type VARCHAR(20) NOT NULL,
    direct_key VARCHAR(73),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT ck_conversations_type CHECK (conversation_type IN ('DIRECT')),
    CONSTRAINT ck_conversations_direct_key CHECK (conversation_type <> 'DIRECT' OR direct_key IS NOT NULL),
    CONSTRAINT uq_conversations_direct_key UNIQUE (direct_key)
);

CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_read_message_id UUID,
    last_read_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX idx_conversation_participants_user ON conversation_participants(user_id);

CREATE TABLE messages (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES app_users(id),
    message_type VARCHAR(20) NOT NULL,
    text_content TEXT,
    status VARCHAR(20) NOT NULL,
    client_message_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT ck_messages_type CHECK (message_type IN ('TEXT', 'VOICE')),
    CONSTRAINT ck_messages_status CHECK (status IN ('SENT', 'DELIVERED', 'READ')),
    CONSTRAINT ck_messages_text_content CHECK (
        (message_type = 'TEXT' AND text_content IS NOT NULL AND LENGTH(TRIM(text_content)) > 0)
        OR (message_type = 'VOICE' AND text_content IS NULL)
    ),
    CONSTRAINT uq_messages_sender_client_id UNIQUE (sender_id, client_message_id)
);

CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at DESC, id DESC);

CREATE TABLE voice_attachments (
    id UUID PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    storage_key VARCHAR(500) NOT NULL,
    original_file_name VARCHAR(255),
    content_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    duration_ms INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_voice_attachments_message UNIQUE (message_id),
    CONSTRAINT ck_voice_attachments_file_size CHECK (file_size > 0),
    CONSTRAINT ck_voice_attachments_duration CHECK (duration_ms > 0)
);

ALTER TABLE conversation_participants
    ADD CONSTRAINT fk_participants_last_read_message
    FOREIGN KEY (last_read_message_id) REFERENCES messages(id) ON DELETE SET NULL;
