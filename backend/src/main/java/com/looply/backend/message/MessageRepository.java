package com.looply.backend.message;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import org.springframework.data.repository.query.Param;

public interface MessageRepository extends JpaRepository<Message, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @EntityGraph(attributePaths = {"sender", "conversation"})
    @Query("select m from Message m where m.id = :id")
    Optional<Message> findLockedById(@Param("id") UUID id);

    @EntityGraph(attributePaths = {"sender", "conversation"})
    Optional<Message> findBySenderIdAndClientMessageId(UUID senderId, String clientMessageId);

    @EntityGraph(attributePaths = {"sender", "conversation"})
    @Query("select m from Message m where m.conversation.id = :conversationId order by m.createdAt desc, m.id desc")
    List<Message> findLatest(@Param("conversationId") UUID conversationId, Pageable pageable);

    @EntityGraph(attributePaths = {"sender", "conversation"})
    @Query("""
            select m from Message m
            where m.conversation.id = :conversationId
              and (m.createdAt < :beforeCreatedAt
                   or (m.createdAt = :beforeCreatedAt and m.id < :beforeId))
            order by m.createdAt desc, m.id desc
            """)
    List<Message> findBefore(
            @Param("conversationId") UUID conversationId,
            @Param("beforeCreatedAt") Instant beforeCreatedAt,
            @Param("beforeId") UUID beforeId,
            Pageable pageable);

    @EntityGraph(attributePaths = {"sender", "conversation"})
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select m from Message m where m.conversation.id = :conversationId "
            + "and m.sender.id <> :userId and m.status <> com.looply.backend.message.MessageStatus.READ "
            + "order by m.createdAt")
    List<Message> findUnreadIncoming(@Param("conversationId") UUID conversationId,
            @Param("userId") UUID userId);
}
