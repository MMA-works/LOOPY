package com.looply.backend.message;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "voice_attachments")
public class VoiceAttachment {
    @Id private UUID id;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "message_id")
    private Message message;
    @Column(name = "storage_key", nullable = false) private String storageKey;
    @Column(name = "original_file_name") private String originalFileName;
    @Column(name = "content_type", nullable = false) private String contentType;
    @Column(name = "file_size", nullable = false) private long fileSize;
    @Column(name = "duration_ms", nullable = false) private int durationMs;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    protected VoiceAttachment() {}

    public VoiceAttachment(UUID id, Message message, String storageKey, String originalFileName,
            String contentType, long fileSize, int durationMs, Instant createdAt) {
        this.id = id;
        this.message = message;
        this.storageKey = storageKey;
        this.originalFileName = originalFileName;
        this.contentType = contentType;
        this.fileSize = fileSize;
        this.durationMs = durationMs;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public Message getMessage() { return message; }
    public String getStorageKey() { return storageKey; }
    public String getOriginalFileName() { return originalFileName; }
    public String getContentType() { return contentType; }
    public long getFileSize() { return fileSize; }
    public int getDurationMs() { return durationMs; }
}
