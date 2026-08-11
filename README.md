# Looply

Looply is an original mobile chat MVP. It takes general usability inspiration from modern messengers without copying WhatsApp branding or copyrighted assets.

## Current phase

Phase 7 completes the locally verified MVP: two authenticated users can exchange persisted real-time text and voice messages, play voice notes, receive sent/delivered/read receipts, and recover their sessions and chat history after reload. Development audio files are stored locally.

## Run the mobile app

```powershell
cd mobile
flutter pub get
flutter test
flutter run
```

## Phase 2 backend

The Spring Boot backend provides username/password registration and login, BCrypt password hashing, JWT authentication, Flyway-managed PostgreSQL tables, and a protected current-user endpoint.

Copy `.env.example` values into your shell or a local `.env` file. Never commit real credentials.

```powershell
$env:POSTGRES_PASSWORD='choose-a-local-password'
docker compose up -d postgres

$env:JAVA_HOME='C:\Users\M. Ali\development\jdk-21\jdk-21.0.12+8'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:DB_URL='jdbc:postgresql://localhost:5433/looply'
$env:DB_USERNAME='looply'
$env:DB_PASSWORD=$env:POSTGRES_PASSWORD
$env:JWT_SECRET='replace-with-at-least-32-random-characters'
$env:VOICE_STORAGE_PATH='.\data\voice'

cd backend
.\mvnw.cmd spring-boot:run
```

Backend base URL: `http://localhost:8081`

Authentication endpoints:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me` with `Authorization: Bearer <token>`

User and direct-conversation endpoints:

- `GET /api/v1/users`
- `POST /api/v1/conversations/direct` with `{"userId":"<target-user-id>"}`
- `GET /api/v1/conversations`
- `GET /api/v1/conversations/{conversationId}`
- `GET /api/v1/conversations/{conversationId}/messages?limit=50&before=<cursor>`

All user, conversation, and message endpoints require a bearer token. Direct conversation creation is idempotent for the same user pair, and conversation details and history are visible only to participants.

Real-time text messaging:

- WebSocket/STOMP endpoint: `ws://localhost:8081/ws`
- Connect header: `Authorization: Bearer <token>`
- Send destination: `/app/chat.send`
- Delivered acknowledgement: `/app/chat.delivered`
- Read acknowledgement: `/app/chat.read`
- Message subscription: `/user/queue/messages`
- Status subscription: `/user/queue/message-status`
- Error subscription: `/user/queue/errors`

The server validates the WebSocket token, verifies conversation membership, persists each text message before broadcasting it to both participants, and returns history newest-first through a cursor-paginated API. Receipt updates are authorized, persisted with `readAt`, broadcast to the sender in real time, and guarded against concurrent status regression.

Voice messaging:

- `POST /api/v1/conversations/{conversationId}/voice` as multipart form data
- Fields: `clientMessageId`, `durationMs`, and `file`
- `GET /api/v1/voice/{attachmentId}/content`
- Allowed development formats: WebM, OGG, M4A/MP4, MP3, and WAV
- Maximum file size: 10 MB; maximum duration: 5 minutes

Voice content endpoints require the same bearer authentication and conversation membership as message history. Local files default to `backend/data/voice`; set `VOICE_STORAGE_PATH` to change it. S3-compatible storage remains a later deployment substitution.

Run checks:

```powershell
cd backend
.\mvnw.cmd verify
```
