# Documentation: CI/CD and Git Workflow

This document explains the project's CI/CD pipeline and the Git workflow, which are designed for modularity and automation.

## 1. Git Submodule Strategy

Each application's source code (e.g., `homepage`, `stats` API) is maintained in its own separate Git repository. These repositories are then included in this main `pi` repository as **Git submodules** inside the `apps/` directory.

-   **Parent Repository (`pi`):** Acts as a "pinboard" or "table of contents." It doesn't contain the application code itself, but rather a pointer to a specific commit in each submodule's repository.
-   **Submodule Repositories:** Are completely independent projects with their own history, CI, and versioning.

This approach enforces a clean separation of concerns and allows each application to be developed and tested independently.

## 2. CI/CD with Reusable GitHub Actions

The CI/CD pipeline is built on a pattern of **reusable workflows**.

### `docker-publish.yaml` (Reusable Workflow)

-   **Location:** `.github/workflows/docker-publish.yaml` in the parent `pi` repository.
-   **Purpose:** Provides a generic, reusable set of steps for building a multi-platform (`linux/amd64`, `linux/arm64`) Docker image and publishing it to the GitHub Container Registry (ghcr.io).
-   **Trigger:** `workflow_call`. It is designed to be called by other workflows, not to run on its own.

### `sync-submodule.yaml` (Reusable Workflow)

-   **Location:** `.github/workflows/sync-submodule.yaml` in the parent `pi` repository.
-   **Purpose:** Automates the second step of the submodule workflow. After a submodule has been updated, this workflow checks out the parent repository, updates the submodule pointer to the latest commit on its `main` branch, and pushes the change.
-   **Trigger:** `workflow_dispatch`. It is designed to be triggered remotely via an API call from a submodule's CI.

### Application CI (Caller Workflows)

-   **Location:** Each submodule (e.g., `apps/homepage/.github/workflows/ci.yaml`) has its own simple CI workflow.
-   **Purpose:** This workflow orchestrates the build and update process.
-   **Steps:**
    1.  **Trigger:** Runs on a `push` to the submodule's `main` branch.
    2.  **Job 1: `build-and-publish`:** It `uses:` the `docker-publish.yaml` workflow to build and publish its own Docker image.
    3.  **Job 2: `update-pointer`:** After the build succeeds, it makes an API call to trigger the `sync-submodule.yaml` workflow in the parent repository, telling it to update the pointer.

This decentralized approach is highly scalable. To add a new application, you simply create a new submodule and add a similar two-job CI workflow to it, without ever needing to modify the parent repository's CI configuration.
