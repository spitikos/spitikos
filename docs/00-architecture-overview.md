# Documentation: Architecture Overview

This document provides a high-level overview of the architecture, design patterns, and core concepts used in this project.

## 1. Core Philosophy: GitOps

The entire project is built around a **GitOps** philosophy. This repository is the **single source of truth** for the entire platform. The desired state of all applications, infrastructure, and configurations is defined declaratively here. [Argo CD](https://argo-cd.readthedocs.io/) acts as the GitOps operator, continuously ensuring the live state of the cluster matches the state defined in this repository.

The key principles are:
-   **Declarative:** All configuration is declarative code, primarily Kubernetes and Helm manifests.
-   **Versioned and Auditable:** All changes are Git commits, providing a clear audit trail and the ability to revert changes.
-   **Automated:** The entire lifecycle, from code commit to live deployment, is automated.
-   **Monorepo:** All first-party application code, Kubernetes configurations, and infrastructure definitions are stored in this single repository, simplifying dependency management and ensuring atomic cross-cutting changes.
-   **Don't Repeat Yourself (DRY):** Common patterns are abstracted into reusable components (the `common` Helm chart, reusable GitHub workflows).

## 2. System Components

The platform consists of several key layers:

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Hardware** | Raspberry Pi 5 | The physical server running the platform. |
| **Operating System** | Ubuntu Server | The base OS for the Raspberry Pi. |
| **Container Orchestration** | k3s | A lightweight, certified Kubernetes distribution. |
| **Public Ingress** | Cloudflare Tunnel | Provides a secure, outbound-only connection to the Cloudflare network, handling TLS termination. |
| **Internal Ingress** | Traefik | Routes traffic within the cluster from the tunnel to the correct service based on hostname. |
| **Application Packaging** | Helm | Manages Kubernetes deployments using a reusable "wrapper chart" pattern. |
| **Continuous Integration** | GitHub Actions | Builds and pushes container images; automatically updates Helm values in this repository. |
| **Continuous Deployment** | Argo CD | Detects changes in this repository and automatically syncs them to the Kubernetes cluster. |

## 3. Project Structure

The repository is organized as follows:

-   `apps/`: Contains the source code for all first-party applications (e.g., `homepage`, `api-stats`).
-   `protos/`: A Git submodule containing the Protobuf API definitions.
-   `charts/`: Contains all the Helm charts for deploying applications and platform services (like Traefik).
-   `argocd/`: Contains the Argo CD application manifests that define what should be deployed.
-   `.github/workflows/`: Contains the reusable GitHub Actions workflows for CI.
-   `docs/`: Contains all project documentation.
-   `Makefile`: Provides convenient shortcuts for common development tasks.
