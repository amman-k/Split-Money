# Antigravity Agent Rules: Flutter & Go Project

# Project Context
This is a money-splitting application that allows groups of friends to track shared expenses, calculate individual debts, and simplify balances to settle up efficiently.

## 1. General Principles
- **Think Before Acting:** Always outline a brief step-by-step plan before writing code or running commands. Wait for my approval before executing complex refactors.
  - **Complex refactor** = touches more than 3 files, OR changes a public API/contract, OR alters state-management architecture, OR modifies the database schema. Anything crossing this threshold requires a plan and explicit approval before execution.
- **Fail Fast:** If a command fails or a build breaks, stop immediately. Do not attempt to guess the fix without showing me the error logs first.
- **No Hallucinated Libraries:** Only use widely adopted, stable packages. If a specific package is required to solve a problem, ask for permission before adding it to `pubspec.yaml` or `go.mod`.
- **Definition of Done:** A task is not complete until `flutter analyze` / `golangci-lint` pass with zero warnings AND the full relevant test suite passes locally — not just before final submission, but as a gate before moving to the next step.

---

## 2. Flutter Client Guidelines

### Architecture & State
- **Structure:** Use a feature-driven architecture (`lib/features/[feature_name]`). Each feature must have its own `presentation`, `domain`, and `data` layers.
- **State Management:** Strictly use **Riverpod**.
  - Prefer `AsyncNotifier` and `@riverpod` annotations for asynchronous state.
  - Never use `StatefulWidget` unless strictly necessary for local animation controllers or text field focus nodes.
  - Use `.select()` on provider watches to avoid unnecessary widget rebuilds when only a sub-field of state is needed.
- **Routing:** Use `go_router` for all navigation. Define routes in a centralized configuration file.
- **Code Generation:** After writing or editing any `@riverpod`, `@freezed`, or `json_serializable`-annotated class, run:
  ```
  dart run build_runner build --delete-conflicting-outputs
  ```
  Never hand-edit generated (`.g.dart`, `.freezed.dart`) files.

### Imports
- Use absolute `package:` imports for all local project files (e.g. `import 'package:my_app/...'`).
- **Exception:** `part`/`part of` directives (required by Riverpod codegen and Freezed) must remain relative — this is a Dart language requirement, not a style choice.

### UI & UX (Preventing the "AI Look")
- **Theming:** NEVER hardcode colors, padding, typography, or border radii.
  - All colors must come from `Theme.of(context).colorScheme`.
  - All text styles must come from `Theme.of(context).textTheme`.
  - Define custom padding values in a shared `AppSpacing` class (e.g., `AppSpacing.md`, `AppSpacing.lg`).
- **Aesthetics:** The app should have a clean, modern aesthetic. Prioritize whitespace, subtle shadows, and soft rounded corners over harsh borders.Do not use neon colors or AI purple/pink gradients.
- **Interactions:** Always include visual feedback for user actions. Use `InkWell` for taps and implement empty/loading/error states for all async UI components.
- **Strings:** No raw strings in the UI. Use `flutter_localizations` and define all strings in ARB files.
- **Accessibility:** All interactive elements need `Semantics` labels where the visual label isn't sufficient. Minimum tappable target size is 48x48. Respect system text-scaling; do not clip or truncate scaled text silently.
- **Performance:** Prefer `const` constructors wherever possible. Use `ListView.builder`/`SliverList` for any dynamic or long list — never `Column` + `SingleChildScrollView` for lists of unbounded length.Instead of building monolithic screens, try and break it down into reusable componenets, which can be used across multiple screens.

### Configuration & Secrets
- Never hardcode API base URLs, keys, or environment-specific values in Dart source.Use a .env file instead.
- Use flavors (dev/staging/prod) or `--dart-define` / `--dart-define-from-file` for environment configuration, with config files gitignored.

### Code Quality
- **Lints:** Ensure the code passes `flutter analyze`. Fix all warnings before submitting changes.
- **Formatting:** Code must be formatted using `dart format`.
- **Logging:** No bare `print()` calls. Use a logging package gated by build mode (e.g. only verbose in debug builds).

---

## 3. Go Backend Guidelines

### Architecture & Design
- **Structure:** Follow the standard Go layout.
  - `/cmd/[app_name]` for main applications.
  - `/internal` for private application and library code.
  - `/pkg` for library code that is ok to use by external applications.
- **Routing & HTTP:** Use `gin`.
- **Database:** Use `sqlc` to generate type-safe Go code from SQL queries. Avoid heavy ORMs. Use `pgx` for PostgreSQL connections. Manage schema migrations with `golang-migrate` (or `atlas`) as the single source of truth that `sqlc` reads from.
- **Dependency Injection:** Keep it simple. Pass dependencies explicitly via struct constructors.
- **Context Propagation:** Any function performing I/O (DB calls, HTTP calls, etc.) must accept `context.Context` as its first parameter and respect cancellation/timeouts. Never store `context.Context` in a struct.
- **Concurrency:** Avoid unbounded goroutine spawning per request. Any goroutine must have a clear termination path (no leaks) and any shared state must be protected with a mutex or channel — flag this explicitly in review if introduced.

### Client-Server Communication
- **API Contracts:** Always adhere to the established OpenAPI/Swagger specifications. Do not invent new endpoints or modify payload structures without updating the contract first.
  - The Flutter client's API layer should be generated or kept in lockstep with the OpenAPI spec (e.g. via `openapi-generator`, or hand-written `dio`/`retrofit` repositories reviewed against the spec) — client and server must not drift independently.
- **JSON Handling:** Use `encoding/json`. Ensure all JSON structs have explicit `json:"..."` tags. Always handle missing fields gracefully.
- **Error Responses:** Use a consistent JSON error envelope across all endpoints, e.g.:
  ```json
  { "data": null, "error": { "code": "invalid_input", "message": "..." } }
  ```

### Security & Config
- Never hardcode secrets, API keys, or connection strings. Load configuration via a typed struct populated from environment variables at startup; fail fast (panic on startup only, never mid-request) if required vars are missing.
- Validate all user input at the API boundary before it touches business logic or the database.

### Observability
- Use `log/slog` for structured logging with contextual fields (request ID, user ID where applicable). Never use `fmt.Println`/`log.Println` in request-handling code paths.

### Code Quality
- **Errors:** Handle errors explicitly. Never use `panic()` for control flow. Wrap errors with context using `fmt.Errorf("failed to do X: %w", err)`.
- **Lints:** Code must pass `golangci-lint` without warnings.
- **Formatting:** Code must be formatted using `gofmt`.

---

## 4. Testing Requirements
- **Flutter:**
  - Write widget tests for critical UI components and unit tests for Riverpod notifiers and repositories.
  - Add golden tests for key screens/components to catch unintentional visual drift (this is the actual enforcement mechanism behind the theming rules in §2).
- **Go:**
  - Write unit tests for all business logic. Use table-driven tests.
  - Minimum coverage target: 80% for all packages under `internal/`. Flag any PR that drops below this.

---

