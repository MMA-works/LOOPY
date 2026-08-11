package com.looply.backend.message;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface VoiceAttachmentRepository extends JpaRepository<VoiceAttachment, UUID> {
    @Query("select v from VoiceAttachment v join fetch v.message m join fetch m.conversation c "
            + "join c.participants p where v.id = :id and p.user.id = :userId")
    Optional<VoiceAttachment> findAccessible(UUID id, UUID userId);
}
