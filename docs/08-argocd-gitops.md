# Documentation: GitOps with Argo CD

This document describes the GitOps workflow used in this project, which is powered by Argo CD. GitOps is a paradigm where the entire desired state of the system is declaratively defined in a Git repository. Argo CD acts as the in-cluster operator that makes reality (the cluster's state) match the desired state in Git.

## 1. GitOps Workflow

The automated deployment workflow is as follows:

1.  A developer pushes code to an application submodule (e.g., `apps/homepage`).
2.  The submodule's CI pipeline builds and pushes a new Docker image, tagged with the commit SHA.
3.  The CI pipeline updates the image `tag` in the corresponding Helm chart's `values.yaml` file in the parent `pi` repository and commits the change.
4.  **Argo CD**, which constantly monitors the `pi` repository, detects the change to `values.yaml`.
5.  Argo CD automatically "syncs" the application. It renders the Helm chart with the new values and applies the resulting manifests to the cluster. The new version is now live.

This repository is the single source of truth. To deploy a change, you push a commit. To roll back, you revert a commit.

## 2. Argo CD Architecture

### Installation and Configuration
Argo CD is installed via its official Helm chart. The configuration is managed declaratively in `argocd/values.yaml`. Key settings include:
-   **Disabling the chart-managed ingress:** We create our own `IngressRoute` for full control.
-   **Enabling insecure mode:** The `server.insecure: "true"` parameter is set, which is crucial for running behind our TLS-terminating reverse proxy (Cloudflare Tunnel and Traefik). This prevents redirect loops.

### Ingress and Access
Argo CD is accessible at **https://argocd-pi.taehoonlee.dev**. This is managed by a dedicated `IngressRoute` located at `argocd/ingress.yaml`, which routes traffic based on the hostname.

### "App of Apps" Pattern
We use the "App of Apps" pattern to manage our application landscape.
-   **Root Application:** A single `Application` manifest, `argocd/root-app.yaml`, is manually applied to the cluster. This is the only imperative step.
-   **App Discovery:** The `root` application is configured to monitor the `argocd/apps/` directory in the Git repository.
-   **Child Applications:** For every `.yaml` file in the `argocd/apps/` directory, Argo CD automatically creates a corresponding `Application`. Each of these files defines a service (e.g., `homepage`, `api-stats`), pointing to its Helm chart in the `charts/` directory.

This pattern ensures that adding a new application to the cluster is as simple as adding a new `Application` manifest to the `argocd/apps/` directory and committing it to Git.
