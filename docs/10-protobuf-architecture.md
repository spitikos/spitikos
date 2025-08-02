# Documentation: Protobuf API Architecture

This document outlines the architecture for managing and consuming Protobuf API definitions across different services in the project.

## 1. Core Principle: Centralized API Repository

To ensure a single source of truth for all API contracts, the Protobuf (`.proto`) files are managed in a dedicated, central Git repository: [`pi-protos`](https://github.com/ethn1ee/pi-protos).

This approach provides several key advantages:
-   **Consistency:** All services (backend, frontend, etc.) are guaranteed to be working from the exact same API definition.
-   **Clear Ownership:** The `pi-protos` repository is the designated location for all API contract changes.
-   **Versioning:** API changes can be versioned and tagged, allowing consumer applications to pin to specific, stable versions of the API.

## 2. Consumption Strategy: Hybrid Approach

To optimize the developer experience for different ecosystems, the project uses a hybrid consumption strategy. The backend consumes the raw `.proto` source files for local code generation, while the frontend consumes a pre-generated, language-specific package.

### 2.1. Backend (Go) Consumption: Git Submodule

The Go backend (`api-stats`) requires the raw `.proto` files to generate server-side code at build time.

-   **Mechanism:** The `pi-protos` repository is included as a **Git submodule** at the path `proto/` inside the `api-stats` application.
-   **Local Development:** A `replace` directive in the `api-stats` `go.mod` file points to this local submodule. This allows for rapid, offline-first development, as changes to the protos are immediately available to the Go compiler.
-   **Code Generation:** A `Makefile` within the `pi-protos` submodule is responsible for running `protoc` to generate the Go files into a `gen/` directory, which are then used by the application.

### 2.2. Frontend (TypeScript) Consumption: NPM Package

The frontend (`homepage`) consumes a pre-generated, type-safe TypeScript client, following standard JavaScript ecosystem practices.

-   **Mechanism:** The `pi-protos` repository is responsible for generating the TypeScript client and publishing it as an NPM package (e.g., `@ethanlee/pi-protos`).
-   **Dependency:** The `homepage` application adds this package as a standard `dependency` in its `package.json`.
-   **Benefits:** This approach completely decouples the frontend from the Protobuf tooling. Frontend developers do not need to manage Git submodules or install `protoc`/`buf`; they simply install a package from the registry.
