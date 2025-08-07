# Documentation: CI/CD and GitOps Workflow

This document explains the project's fully automated CI/CD pipeline, which is designed for a monorepo structure and enables a seamless GitOps workflow with Argo CD.

## 1. Git Strategy: Monorepo

All first-party application source code (e.g., `homepage`, `api-stats`) is maintained in this single `pi` repository inside the `apps/` directory. This simplifies development by allowing for atomic commits that can span multiple applications and their configurations.

The `pi-protos` directory contains the shared Protobuf API definitions, which are consumed as versioned packages.

## 2. The CI/CD Pipeline: From Code to Live Deployment

The pipeline is a chain reaction that starts with a `git push` to this repository and ends with a live deployment, with no manual intervention required.

### Step 1: The Trigger

-   **Location:** Each application directory (e.g., `apps/homepage/`) contains its own CI workflow file (e.g., `.github/workflows/ci.yaml`).
-   **Trigger:** The workflow is configured to run only when changes are detected within its specific application directory (e.g., a push that modifies files under `apps/homepage/`).

### Step 2: Reusable Release Workflow

-   **Location:** The application's workflow uses the `uses:` clause to call a **reusable workflow** located in the central `ethn1ee/pi` repository.
-   **Purpose:** This reusable workflow is responsible for the entire release process.

#### Job 1: `docker-publish`
-   Builds a single-platform (`linux/arm64`) Docker image for the application.
-   Tags the image with the short commit SHA of the triggering commit.
-   Pushes the new image to the GitHub Container Registry (ghcr.io).

#### Job 2: `update-chart`
-   This job runs only after `docker-publish` succeeds.
-   It checks out this `pi` repository.
-   It finds the `values.yaml` file for the specific application (e.g., `charts/homepage/values.yaml`).
-   It replaces the `image.tag` value with the new commit SHA tag from the previous job.
-   It commits this change directly back to this repository with a message like `ci: deploy homepage version <sha>`.
-   It pushes the commit to `main`.

### Step 3: Argo CD (The Deployer)

-   The `git push` from the `update-chart` job is the trigger for the final step.
-   Argo CD, which is constantly monitoring this repository, detects the new commit.
-   Because its sync policy is set to `automated`, it immediately begins a sync process.
-   It pulls the new Helm chart configuration, renders the templates with the updated image tag, and applies the changes to the cluster.

The new version of the application is now live. This entire process, from code to deployment, is fully automated.