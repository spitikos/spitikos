# Documentation: Naming Conventions

This document outlines the strict naming conventions used across the project. Consistency is critical for the automation and GitOps workflows to function correctly.

## 1. Resource Naming

| Resource Type | Convention | Example |
| :--- | :--- | :--- |
| **Git Repository** | `pi-<app-name>` | `pi-homepage` |
| **Docker Image** | `pi-<app-name>` | `ghcr.io/ethn1ee/pi-homepage` |
| **Argo CD Application** | `<app-name>` | `homepage` |
| **Kubernetes Namespace** | `<app-name>` | `homepage` |
| **Helm Chart Name** | `<app-name>` | `homepage` |
| **Kubernetes Service** | `<app-name>` | `homepage` |

### Summary of Rules:

-   **Rule:** In-cluster resources, such as the **Argo CD Application Name**, the **Kubernetes Namespace**, and all resources defined in the Helm chart (Deployments, Services, etc.), must be named after the application's purpose, **without any prefixes** (e.g., `homepage`, `api-stats`).
-   **Rule:** External assets, such as the **Git Repository** and the **Docker Image**, must use the `pi-` prefix.
-   **Exception:** Third-party applications (e.g., `traefik`, `kube-dashboard`) do not follow these prefixing rules.
