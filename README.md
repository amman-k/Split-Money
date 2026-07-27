# Split-Money

Split-Money is a cross-platform application designed to help groups of friends track shared expenses, calculate individual debts, and simplify balances to settle up efficiently.

## 🏗 Architecture

The project is structured into two main components:
- **`backend/`**: A RESTful API built with Go.
- **`frontend/`**: A cross-platform mobile/web client built with Flutter.

### Backend (Go)
- **Framework**: [Gin](https://gin-gonic.com/) for HTTP routing.
- **Database**: PostgreSQL with [pgx](https://github.com/jackc/pgx) for connection pooling.
- **Type-safe SQL**: [sqlc](https://sqlc.dev/) to generate Go code from SQL queries.
- **Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate) to manage database schemas.
- **Architecture**: Standard Go layout (`cmd/`, `internal/`, `pkg/`).

### Frontend (Flutter)
- **Architecture**: Feature-first architecture (`lib/features/[feature_name]`) with distinct presentation, domain, and data layers.
- **State Management**: [Riverpod](https://riverpod.dev/) (`AsyncNotifier` and `@riverpod` codegen).
- **Routing**: [go_router](https://pub.dev/packages/go_router) for centralized, declarative routing.
- **Data Models**: [Freezed](https://pub.dev/packages/freezed) and `json_serializable` for immutable state and JSON parsing.
- **Additional Features**: PDF generation for expense summaries.

## 🚀 Getting Started

### Prerequisites
- Go 1.20+
- Flutter SDK (>=3.10.7)
- PostgreSQL

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Configure your environment variables in `.env` (e.g., database connection string, JWT secrets).
3. Run database migrations to set up the schema:
   ```bash
   # Adjust connection string as needed
   migrate -path internal/db/migrations -database "postgresql://user:pass@localhost:5432/splitmoney?sslmode=disable" up
   ```
4. Start the server:
   ```bash
   go run cmd/server/main.go
   ```

### Frontend Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run code generation (required after modifying any Riverpod/Freezed annotated files):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run
   ```

