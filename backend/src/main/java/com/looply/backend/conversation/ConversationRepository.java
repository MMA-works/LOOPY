package com.looply.backend.conversation;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ConversationRepository extends JpaRepository<Conversation, UUID> {

    @EntityGraph(attributePaths = {"participants", "participants.user"})
    Optional<Conversation> findByDirectKey(String directKey);

    @EntityGraph(attributePaths = {"participants", "participants.user"})
    @Query("select distinct c from Conversation c join c.participants p where p.user.id = :userId order by c.updatedAt desc")
    List<Conversation> findAllForUser(@Param("userId") UUID userId);

    @EntityGraph(attributePaths = {"participants", "participants.user"})
    @Query("select distinct c from Conversation c join c.participants p where c.id = :conversationId and p.user.id = :userId")
    Optional<Conversation> findAccessibleById(@Param("conversationId") UUID conversationId, @Param("userId") UUID userId);
}
