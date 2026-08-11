package com.looply.backend.message;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;

@Service
public class VoiceStorageService {
    private final Path root;

    public VoiceStorageService(@Value("${app.voice.storage-path:./data/voice}") String storagePath) {
        root = Path.of(storagePath).toAbsolutePath().normalize();
        try {
            Files.createDirectories(root);
        } catch (IOException exception) {
            throw new IllegalStateException("Could not initialize voice storage", exception);
        }
    }

    public String store(UUID attachmentId, String extension, InputStream input) {
        String key = attachmentId + extension;
        Path target = resolve(key);
        try (input) {
            Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
            return key;
        } catch (IOException exception) {
            throw new IllegalStateException("Could not store voice message", exception);
        }
    }

    public Resource load(String key) {
        try {
            Resource resource = new UrlResource(resolve(key).toUri());
            if (!resource.exists() || !resource.isReadable()) {
                throw new IllegalArgumentException("Voice file is unavailable");
            }
            return resource;
        } catch (IOException exception) {
            throw new IllegalArgumentException("Voice file is unavailable", exception);
        }
    }

    public void deleteQuietly(String key) {
        try { Files.deleteIfExists(resolve(key)); } catch (IOException ignored) { }
    }

    private Path resolve(String key) {
        Path resolved = root.resolve(key).normalize();
        if (!resolved.startsWith(root)) throw new IllegalArgumentException("Invalid storage key");
        return resolved;
    }
}
