package com.looply.backend.message;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ImageAttachmentRepository extends JpaRepository<ImageAttachment, UUID> {
    @Query("select i from ImageAttachment i join fetch i.message m join fetch m.conversation c "
            + "where i.id = :id and exists (select p from ConversationParticipant p where p.conversation = c and p.user.id = :userId)")
    Optional<ImageAttachment> findAccessible(UUID id, UUID userId);
}
