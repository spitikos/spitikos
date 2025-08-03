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

### 2.1. Backend (Go) Consumption

The Go backend (`api-stats`) consumes the protobuf definitions directly from the `protos` submodule located at the root of this repository.

-   **Local Development:** A `replace` directive in the `api-stats` `go.mod` file points to the local submodule using a relative path (`../../protos`). This allows for rapid, offline-first development, as changes to the protos are immediately available to the Go compiler.
-   **Code Generation:** The `protos` submodule contains its own `Makefile` for generating the Go gRPC server code into a `gen/` directory.

### 2.2. Frontend (TypeScript) Consumption: NPM Package

The frontend (`homepage`) consumes a pre-generated, type-safe TypeScript client, following standard JavaScript ecosystem practices.

-   **Mechanism:** The `protos` submodule is also a fully-fledged npm package. A GitHub Action workflow within the submodule is configured to automatically build and publish the TypeScript client to the npm registry whenever a new version tag is pushed.
-   **Dependency:** The `homepage` application adds this package (e.g., `@ethantlee/pi-protos`) as a standard `dependency` in its `package.json`.
-   **Benefits:** This approach completely decouples the frontend from the Protobuf tooling. Frontend developers do not need to manage Git submodules or install `protoc`/`buf`; they simply install a versioned package from the registry.
