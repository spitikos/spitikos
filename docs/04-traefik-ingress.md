# Documentation: Traefik Ingress Controller

This document covers the installation and configuration of the Traefik Ingress Controller, which is responsible for routing external traffic to the correct services within the Kubernetes cluster.

## 1. Architecture: Declarative Deployment via GitOps

Traefik is a critical piece of the platform infrastructure. As such, it is managed declaratively using the same GitOps principles as our own applications. We do not install or upgrade it manually with `helm` commands.

- **Wrapper Chart:** The configuration is defined in a dedicated **wrapper chart** located in the `spitikos/charts` repository at `charts/traefik`. This chart includes the official `traefik/traefik` chart as a dependency.
- **Declarative Configuration:** All configuration is defined in the `charts/traefik/values.yaml` file in the `spitikos/charts` repository.
- **GitOps Management:** The entire Traefik deployment is managed by an Argo CD `Application` manifest located in the `spitikos/spitikos` repository at `argocd/apps/traefik.yaml`. Argo CD ensures that the Traefik deployment in the cluster always matches the configuration defined in the `charts` repository.

## 2. Key Configuration Choices

The configuration in `charts/traefik/values.yaml` is critical for integrating with the rest of our platform.

- `ports.web.expose: true`: This enables the `web` entrypoint.
- `ports.web.exposedPort: 30080`: This sets the `NodePort` to a predictable value (`30080`). This is the port that `cloudflared` is configured to forward traffic to.
- `ports.websecure`: We do not define a `websecure` port. TLS is terminated at the Cloudflare edge, and traffic within our cluster is plain HTTP. This simplifies the setup.
- `api.dashboard: true` & `api.insecure: true`: These settings enable the Traefik dashboard and expose it internally for diagnostic purposes.

## 3. Traefik Dashboard

For diagnostics and visibility into the ingress routing, the Traefik dashboard is exposed at:

**https://traefik.spitikos.dev**

This is achieved via a dedicated `IngressRoute` template within the `charts/traefik` chart, which routes traffic to the internal `api@internal` Traefik service.
