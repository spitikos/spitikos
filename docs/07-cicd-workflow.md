# Documentation: CI/CD and GitOps Workflow

This document explains the project's fully automated CI/CD pipeline, which is designed for modularity and to enable a seamless GitOps workflow with Argo CD.

## 1. Git Strategy: Submodules and HTTPS

Each application's source code (e.g., `homepage`, `stats` API) is maintained in its own separate Git repository. These are included in this main `pi` repository as **Git submodules** inside the `apps/` directory.

-   **Parent Repository (`pi`):** Acts as a "pinboard" or "table of contents." It doesn't contain the application code itself, but rather a pointer to a specific commit in each submodule's repository.
-   **Submodule Repositories:** Are completely independent projects with their own history and CI.
-   **HTTPS URLs:** The `.gitmodules` file is configured to use public `https://` URLs. This is a critical requirement for Argo CD, as it allows the platform to clone the submodules without needing private SSH keys.

## 2. The CI/CD Pipeline: From Code to Live Deployment

The pipeline is a chain reaction that starts with a `git push` to a submodule and ends with a live deployment, with no manual intervention required.

### Step 1: Application CI (The Trigger)

-   **Location:** Each submodule (e.g., `apps/homepage/.github/workflows/ci.yaml`) has its own CI workflow.
-   **Trigger:** Runs on a `push` to the submodule's `main` branch.
-   **Action:** This workflow's sole purpose is to call the reusable `release.yaml` workflow in the parent repository, passing its own specific parameters (like image name and chart path).

### Step 2: Reusable Release Workflow (`release.yaml`)

-   **Location:** `.github/workflows/release.yaml` in the parent `pi` repository.
-   **Purpose:** This is the heart of the CI pipeline. It's a generic, reusable workflow that performs two critical jobs.

#### Job 1: `docker-publish`
-   Builds a multi-platform (`linux/amd64`, `linux/arm64`) Docker image for the application.
-   Tags the image with the short commit SHA of the triggering commit.
-   Pushes the new image to the GitHub Container Registry (ghcr.io).

#### Job 2: `update-chart`
-   This job runs only after `docker-publish` succeeds.
-   It checks out the parent `pi` repository.
-   It runs a `sed` command to find the `values.yaml` file for the specific application (e.g., `charts/homepage/values.yaml`).
-   It replaces the `image.tag` value with the new commit SHA tag from the previous job.
-   It commits this change directly to the `pi` repository with a message like `ci: deploy homepage version <sha>`.
-   It pushes the commit to `main`.

### Step 3: Argo CD (The Deployer)

-   The `git push` from the `update-chart` job is the trigger for the final step.
-   Argo CD, which is constantly monitoring the `pi` repository, detects this new commit.
-   Because its sync policy is set to `automated`, it immediately begins a sync process.
-   It pulls the new Helm chart configuration, renders the templates with the updated image tag, and applies the changes to the cluster.

The new version of the application is now live. This entire process, from code to deployment, is fully automated.
