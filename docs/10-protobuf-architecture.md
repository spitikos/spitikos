# Documentation: Protobuf API Architecture

This document outlines the architecture for managing and consuming Protobuf API definitions across different services in the project.

## 1. Core Principle: Centralized API Repository

To ensure a single source of truth for all API contracts, the Protobuf (`.proto`) files are managed in a dedicated, central Git repository: [`pi-protos`](https://github.com/ethn1ee/pi-protos).

This approach provides several key advantages:
-   **Consistency:** All services (backend, frontend, etc.) are guaranteed to be working from the exact same API definition.
-   **Clear Ownership:** The `pi-protos` repository is the designated location for all API contract changes.
-   **Versioning:** API changes can be versioned and tagged, allowing consumer applications to pin to specific, stable versions of the API.

## 2. Consumption Strategy: Git Submodules

Both producer and consumer applications integrate with the `pi-protos` repository by adding it as a **Git submodule**. This allows them to pull in the `.proto` files directly during their build process without needing a separate package manager.

### 2.1. Backend (`api-stats`) Integration

-   **Location:** The `pi-protos` repository is included as a submodule at the path `proto/` within the `apps/api/stats` application.
-   **Code Generation:** The existing `go generate` command in the backend's `Makefile` uses the `.proto` files from the submodule to generate the necessary Go server stubs and message types.

### 2.2. Frontend (`homepage`) Integration

-   **Location:** The `pi-protos` repository is included as a submodule at the path `src/proto/` within the `apps/homepage` application.
-   **Code Generation:** The frontend uses [`@bufbuild/buf`](https://buf.build/) to generate a type-safe TypeScript client from the Protobuf definitions.
    -   **Configuration:** A `buf.gen.yaml` file in the `homepage` root configures the code generation plugins and output directory (`src/gen`).
    -   **Execution:** A `pnpm build:proto` script runs the `buf generate` command, which is integrated into the main `pnpm build` process. This ensures the client is always up-to-date with the Protobuf definitions before the application is built.
