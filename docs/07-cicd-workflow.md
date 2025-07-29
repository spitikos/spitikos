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

### Application CI (Caller Workflows)

-   **Location:** Each submodule (e.g., `apps/homepage/.github/workflows/ci.yaml`) has its own simple CI workflow.
-   **Purpose:** This workflow triggers the build of a new Docker image whenever code is pushed to the submodule.
-   **Steps:**
    1.  **Trigger:** Runs on a `push` to the submodule's `main` branch.
    2.  **Job: `build-and-publish`:** It `uses:` the `docker-publish.yaml` workflow from the parent repository to build and publish its own Docker image.

## 3. Manual Submodule Update Workflow

After a submodule's CI has successfully published a new image, the pointer in the parent `pi` repository must be updated manually.

1.  **Fetch Changes:** In your local clone of the `pi` repository, fetch the latest changes for all submodules:
    ```bash
    git submodule update --remote
    ```
2.  **Review and Commit:** Running `git status` will show the submodules that have new commits (e.g., `modified: apps/homepage (new commits)`).
3.  **Commit the Pointer:** Stage the change to the submodule pointer and commit it to the parent repository.
    ```bash
    git add apps/homepage
    git commit -m "feat(homepage): Update to latest version"
    git push
    ```

This manual but deliberate process ensures that the parent repository is always pinned to a specific, tested version of each application.
