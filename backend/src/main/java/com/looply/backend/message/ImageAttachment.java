package com.looply.backend.message;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "image_attachments")
public class ImageAttachment {
    @Id private UUID id;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "message_id", nullable = false)
    private Message message;
    @Column(name = "storage_key", nullable = false, length = 500) private String storageKey;
    @Column(name = "original_file_name") private String originalFileName;
    @Column(name = "content_type", nullable = false, length = 100) private String contentType;
    @Column(name = "file_size", nullable = false) private long fileSize;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    protected ImageAttachment() {}

    public ImageAttachment(UUID id, Message message, String storageKey, String originalFileName,
            String contentType, long fileSize, Instant createdAt) {
        this.id = id;
        this.message = message;
        this.storageKey = storageKey;
        this.originalFileName = originalFileName;
        this.contentType = contentType;
        this.fileSize = fileSize;
        this.createdAt = createdAt;
    }

    public UUID getId() { return id; }
    public String getStorageKey() { return storageKey; }
    public String getContentType() { return contentType; }
    public long getFileSize() { return fileSize; }
}
