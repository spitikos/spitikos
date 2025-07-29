# Documentation: Architecture Overview

This document provides a high-level overview of the architecture, design patterns, and core concepts used in this project.

## 1. Core Philosophy

The goal of this project is to create a scalable, maintainable, and automated platform for hosting containerized applications on a Raspberry Pi. The key principles are:

-   **Infrastructure as Code (IaC):** All aspects of the system, from Kubernetes deployments to CI/CD pipelines, are defined as code in this Git repository.
-   **Modularity:** Each application is a self-contained unit, managed in its own Git repository and included here as a Git submodule. This enforces clean separation of concerns.
-   **Don't Repeat Yourself (DRY):** Common patterns, especially for Kubernetes deployments and CI/CD, are abstracted into reusable components (`common` Helm chart, reusable GitHub workflows).

## 2. System Components

The platform consists of several key layers:

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Hardware** | Raspberry Pi 5 | The physical server running the platform. |
| **Operating System** | Ubuntu Server | The base OS for the Raspberry Pi. |
| **Container Orchestration** | k3s | A lightweight, certified Kubernetes distribution. |
| **Ingress & Networking** | Cloudflare Tunnel & Traefik | Provides secure public access to services without opening firewall ports. Traefik routes traffic internally based on URL paths. |
| **Application Packaging** | Helm | Manages Kubernetes deployments using a reusable library chart pattern. |
| **CI/CD** | GitHub Actions | Automates building container images for each submodule and updating the parent repository's submodule pointers. |

## 3. Project Structure

The repository is organized as follows:

-   `apps/`: Contains the source code for all applications. Each subdirectory is a Git submodule pointing to a separate repository.
-   `charts/`: Contains all the Helm charts for deploying applications. This includes a `_common` library chart and wrapper charts for each application.
-   `.github/workflows/`: Contains the reusable GitHub Actions workflows for CI/CD.
-   `doc/`: Contains all project documentation.
-   `Makefile`: Provides convenient shortcuts for common development tasks like updating Helm dependencies and installing all applications.
