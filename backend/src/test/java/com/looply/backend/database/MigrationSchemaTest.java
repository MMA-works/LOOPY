package com.looply.backend.database;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest
class MigrationSchemaTest {

    @Autowired
    JdbcTemplate jdbcTemplate;

    @Test
    void flywayCreatesAllCoreMvpTables() {
        List<String> tables = jdbcTemplate.queryForList(
                "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
                String.class);

        assertThat(tables).contains(
                "app_users",
                "conversations",
                "conversation_participants",
                "messages",
                "voice_attachments",
                "flyway_schema_history");
    }
}
