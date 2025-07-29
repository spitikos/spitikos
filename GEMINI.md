# Gemini Project Guide: Raspberry Pi Kubernetes Platform

Welcome to the `pi` project. This document is your guide to understanding and contributing to this repository. Adhering to the established patterns is crucial for maintaining the project's stability and scalability.

**First Action:** Before performing any task, review the detailed documentation in the `doc/` directory to understand the full context of the request.

---

## 1. Core Architecture & Design Patterns

This project is not a simple collection of files; it is a highly structured platform built on specific, idiomatic patterns. You **must** follow these patterns.

### 1.1. Application Code as Git Submodules

-   **Rule:** All application source code is located in the `apps/` directory. Every subdirectory within `apps/` (e.g., `apps/homepage`, `apps/api/stats`) is a **Git submodule**, pointing to its own independent repository.
-   **Implication:** Do not modify application code directly in this repository. Changes must be made within the submodule, committed, and pushed to the submodule's own remote. The parent repository only stores a pointer to a specific commit of the submodule.

### 1.2. Helm "Common Library Chart" Pattern

-   **Rule:** All applications are deployed via Helm charts located in the `charts/` directory. The architecture uses a **common library chart** (`charts/_common`) to define all the standard Kubernetes resources.
-   **Mechanism:**
    -   The `_common` chart's `Chart.yaml` is `type: library`. Its templates are defined in `_helpers.tpl` as callable functions (e.g., `common.deployment`).
    -   Application charts (e.g., `charts/homepage`) are lightweight wrappers. They declare a dependency on the `_common` chart and contain simple, pass-through templates that `include` the resource templates from `_common`.
-   **Implication:** When creating a new application chart, you **must** follow this pattern. Do not create full resource definitions in the application chart.

### 1.3. Decentralized CI/CD with Reusable Workflows

-   **Rule:** The CI/CD pipeline is decentralized. Each application submodule has its own CI workflow file (e.g., `apps/homepage/.github/workflows/ci.yaml`).
-   **Mechanism:**
    -   The parent `pi` repository contains two **reusable workflows** in `.github/workflows/`: `docker-publish.yaml` and `sync-submodule.yaml`.
    -   A submodule's CI workflow is a simple "caller" that triggers these reusable workflows. It first calls `docker-publish.yaml` to build its image. Upon success, it triggers `sync-submodule.yaml` via a `workflow_dispatch` API call to update its pointer in the parent repository.
-   **Implication:** Do not create a monolithic CI workflow in the parent repository. All application-specific CI logic belongs in the submodule's own repository.

### 1.4. Namespace per Application

-   **Rule:** Every application is deployed into its own dedicated Kubernetes namespace.
-   **Convention:** The namespace name should match the application's chart name (e.g., the `pi-homepage` chart is deployed to the `pi-homepage` namespace).

---

## 2. Standard Operating Procedures (SOPs)

### SOP: Adding a New Application

1.  **Create the Submodule:** Create the application's source code in a new, separate Git repository. Then, add it as a submodule within the `apps/` directory (e.g., `git submodule add <url> apps/new-app`).
2.  **Create the Helm Chart:** Create a new wrapper chart in the `charts/` directory (e.g., `charts/new-app`). Follow the established "Common Library Chart" pattern precisely.
3.  **Create the CI Workflow:** Add a `.github/workflows/ci.yaml` file to the new submodule. This workflow should call the `docker-publish.yaml` and `sync-submodule.yaml` reusable workflows, following the pattern in the existing submodules.
4.  **Update Documentation:** Add a new document to the `doc/` directory explaining the new application.

### SOP: Updating an Application

1.  **Code Changes:** `cd` into the submodule directory (e.g., `apps/homepage`), make your changes, commit, and push *to the submodule's remote*. This will trigger its CI to build a new Docker image and automatically update the pointer in the parent repository.
2.  **Configuration Changes:** If you only need to change the deployment configuration (e.g., the number of replicas), modify the `values.yaml` file in the application's Helm chart (e.g., `charts/homepage/values.yaml`) and run `helm upgrade`.

### SOP: Updating the Common Chart

1.  Modify the templates in `charts/_common/templates/`.
2.  Run `make helm-deps` from the project root to propagate the changes to all application charts that depend on it.
3.  Run `make helm-install-all` or `helm upgrade` for each application to apply the changes to the cluster.
