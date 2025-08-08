# Documentation: GitOps with Argo CD

This document describes the GitOps workflow used in this project, which is powered by Argo CD. GitOps is a paradigm where the entire desired state of the system is declaratively defined in a Git repository. Argo CD acts as the in-cluster operator that makes reality (the cluster's state) match the desired state in Git.

## 1. GitOps Workflow

The automated deployment workflow is as follows:

1.  A developer pushes code to an application repository (e.g., `spitikos/homepage`).
2.  The application's CI pipeline builds a new Docker image and pushes it to `ghcr.io`.
3.  The CI pipeline then checks out the `spitikos/charts` repository and updates the image `tag` in the corresponding Helm chart's `values.yaml` file.
4.  **Argo CD**, which constantly monitors the `spitikos/charts` repository, detects the change to `values.yaml`.
5.  Argo CD automatically "syncs" the application. It renders the Helm chart with the new values and applies the resulting manifests to the cluster. The new version is now live.

The `spitikos/charts` repository is the single source of truth for what is running in the cluster. To deploy a change, you push a commit. To roll back, you revert a commit.

## 2. Argo CD Architecture

### Installation and Configuration

Argo CD is installed via its official Helm chart. The configuration is managed declaratively in `spitikos/charts` in the `charts/argocd/values.yaml` file. Key settings include:

- **Disabling the chart-managed ingress:** We create our own `IngressRoute` for full control.
- **Enabling insecure mode:** The `server.insecure: "true"` parameter is set, which is crucial for running behind our TLS-terminating reverse proxy (Cloudflare Tunnel and Traefik). This prevents redirect loops.

### Ingress and Access

Argo CD is accessible at **https://argocd.spitikos.dev**. This is managed by a dedicated `IngressRoute` located in the `spitikos/spitikos` repository at `argocd/ingress.yaml`.

### "App of Apps" Pattern

We use the "App of Apps" pattern to manage our application landscape.

- **Root Application:** A single `Application` manifest, `argocd/root-app.yaml` in the `spitikos/spitikos` repo, is manually applied to the cluster. This is the only imperative step.
- **App Discovery:** The `root` application is configured to monitor the `argocd/apps/` directory in the `spitikos/spitikos` repository.
- **Child Applications:** For every `.yaml` file in the `argocd/apps/` directory, Argo CD automatically creates a corresponding `Application`. Each of these files defines a service (e.g., `homepage`, `traefik`), pointing to its Helm chart in the **`spitikos/charts`** repository.

This pattern ensures that adding a new application to the cluster is as simple as adding a new `Application` manifest to the `argocd/apps/` directory and committing it to Git.
