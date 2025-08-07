# Documentation: Protobuf API Architecture

This document outlines the architecture for managing and consuming Protobuf API definitions across different services in the project.

## 1. Core Principle: Centralized API Repository & Packages

To ensure a single source of truth for all API contracts, the Protobuf (`.proto`) files are managed in a dedicated, central Git repository: [`pi-protos`](https://github.com/ethn1ee/pi-protos).

This repository is configured with a CI/CD pipeline that automatically generates and publishes versioned packages for different languages whenever a new version tag is pushed.

This approach provides several key advantages:
-   **Consistency:** All services are guaranteed to be working from the exact same versioned API definition.
-   **Decoupling:** Consumer applications are completely decoupled from the `protoc` toolchain.
-   **Versioning:** API changes are managed through standard package versioning, allowing applications to upgrade their dependencies deliberately.

## 2. Consumption Strategy: Package-Based

Both the backend and frontend services consume the API definitions as standard, pre-generated packages from their respective registries.

### 2.1. Backend (Go) Consumption

The Go backend (`api-stats`) consumes the generated Go package for the Protobuf definitions.

-   **Dependency:** The `pi-api-stats` service adds the `github.com/ethn1ee/pi-protos` package as a standard dependency in its `go.mod` file.
-   **Workflow:** To update to a new API version, a developer simply runs `go get` to fetch the new version of the package.

### 2.2. Frontend (TypeScript) Consumption: The BFF Proxy Pattern

The frontend (`homepage`) does **not** connect directly to the gRPC `api-stats` service. Doing so would require exposing the service publicly and dealing with complex cross-origin (CORS) issues.

Instead, we use a **Backend for Frontend (BFF)** proxy pattern, implemented as a generic Next.js API Route.

-   **Proxy Route:** A single API route (`/api/grpc/[...path]`) within the `pi-homepage` application acts as a proxy.
-   **Client Configuration:** The gRPC client transport in the browser is configured to point to this local proxy route (e.g., `baseUrl: "/api/grpc"`).
-   **Data Flow:**
    1.  The browser-side component makes a type-safe gRPC call to the `/api/grpc` endpoint.
    2.  The Next.js server receives this request.
    3.  It forwards the request, including the binary Protobuf payload, to the internal `api-stats` service address (`http://api-stats.api-stats.svc.cluster.local:50051`).
    4.  It streams the binary response from `api-stats` directly back to the browser.

-   **Benefits:** This approach is both secure and type-safe. The `api-stats` service remains private within the cluster, and the end-to-end binary Protobuf contract is preserved all the way to the browser.
