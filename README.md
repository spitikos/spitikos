# Raspberry Pi Kubernetes Platform

This repository contains the complete, declaratively defined infrastructure for a Kubernetes platform running on a Raspberry Pi. The entire system is managed via a **GitOps** workflow.

## ✨ Core Philosophy

This is not just a collection of configuration files; it is a fully automated platform where **Git is the single source of truth.**

-   **Declarative:** All resources (applications, infrastructure, etc.) are defined as code.
-   **Automated:** [**GitHub Actions**](https://github.com/features/actions) build and publish container images, which automatically triggers [**Argo CD**](https://argo-cd.readthedocs.io/) to deploy the new version to the cluster.
-   **Modular:** Each application is a versioned [**Git submodule**](https://git-scm.com/book/en/v2/Git-Tools-Submodules), and all deployments are managed by reusable [**Helm charts**](https://helm.sh/).

## 🚀 Services

All services are exposed via [**Cloudflare Tunnel**](https://www.cloudflare.com/products/tunnel/) and routed internally by [**Traefik**](https://traefik.io/traefik/).

| Service | URL |
| :--- | :--- |
| **Homepage** | [`pi.taehoonlee.dev`](https://pi.taehoonlee.dev) |
| **Argo CD** (GitOps Dashboard) | [`argocd-pi.taehoonlee.dev`](https://argocd-pi.taehoonlee.dev) |
| **Kubernetes Dashboard** | [`kube-pi.taehoonlee.dev`](https://kube-pi.taehoonlee.dev) |
| **Traefik Dashboard** | [`traefik-pi.taehoonlee.dev`](https://traefik-pi.taehoonlee.dev) |

## 📚 Documentation

For a complete guide to the architecture, setup, and workflows, please see the [**project documentation in the `docs/` directory**](./docs/00-architecture-overview.md).

