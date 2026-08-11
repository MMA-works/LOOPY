ALTER TABLE messages DROP CONSTRAINT ck_messages_type;
ALTER TABLE messages ADD CONSTRAINT ck_messages_type
    CHECK (message_type IN ('TEXT', 'VOICE', 'IMAGE'));

ALTER TABLE messages DROP CONSTRAINT ck_messages_text_content;
ALTER TABLE messages ADD CONSTRAINT ck_messages_text_content CHECK (
    (message_type = 'TEXT' AND text_content IS NOT NULL AND LENGTH(TRIM(text_content)) > 0)
    OR (message_type IN ('VOICE', 'IMAGE') AND text_content IS NULL)
);

CREATE TABLE image_attachments (
    id UUID PRIMARY KEY,
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    storage_key VARCHAR(500) NOT NULL,
    original_file_name VARCHAR(255),
    content_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT uq_image_attachments_message UNIQUE (message_id),
    CONSTRAINT ck_image_attachments_file_size CHECK (file_size > 0)
);
