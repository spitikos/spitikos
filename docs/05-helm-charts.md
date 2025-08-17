# Documentation: Helm Chart Architecture

This document explains the reusable and maintainable Helm chart architecture used in this project. The design is based on the idiomatic **Wrapper Chart** pattern, with all charts being centrally managed in the dedicated `spitikos/charts` repository. This pattern is used for both our own applications and for third-party platform services like Traefik.

## 1. Core Concept: Wrapper and Library Charts

The architecture consists of two types of charts:

- **Library Charts:** These charts provide reusable, generic templates but cannot be deployed themselves. Our `charts/_common` chart is a library chart that defines standard templates for a `Deployment`, `Service`, and `IngressRoute`.
- **Wrapper Charts:** These are deployable charts that "wrap" one or more other charts (either library or deployable) as dependencies. They provide a layer of configuration (`values.yaml`) and can add their own templates on top of the dependencies.

### gRPC Service Annotation

To support gRPC services, the common `_service.tpl` template was modified. It now automatically adds the `traefik.ingress.kubernetes.io/service.serversscheme: h2c` annotation to any `Service` where the `service.portName` in `values.yaml` is set to `grpc`. This is critical for telling Traefik to use the HTTP/2 Cleartext protocol when communicating with the backend pod.

## 2. Application Charts (e.g., `charts/homepage`)

Our own applications use a simple wrapper chart pattern:

1.  **`Chart.yaml`**: Defines the application's metadata and declares a dependency on our local `_common` library chart.

    ```yaml
    dependencies:
      - name: common
        version: "0.1.0"
        repository: "file://../_common"
    ```

2.  **`values.yaml`**: Provides the specific values that the `_common` chart's templates will use. This is where we define the application's unique properties, such as its container image, ingress hostname, and service port.

3.  **`templates/` directory**: Contains simple, one-line "pass-through" template files. Each file explicitly calls a corresponding template from the `_common` chart.

    **Example: `charts/homepage/templates/manifests.yaml`**

    ```yaml
    { { - include "common.deployment" . | nindent 0 } }
    ---
    { { - include "common.service" . | nindent 0 } }
    ---
    { { - include "common.ingress-route" . | nindent 0 } }
    ```

    This tells Helm: "For the `homepage` chart, render a Deployment, Service, and IngressRoute using the templates from `_common` and the values from `homepage/values.yaml`."

    > **Note:** For details on the ongoing issues with routing gRPC traffic via `IngressRoute`, see the `12-grpc-routing-issue.md` document.

## 3. Platform Service Charts (e.g., `charts/traefik`)

Third-party services are also managed using the wrapper chart pattern. This allows us to manage their configuration declaratively and deploy them with Argo CD.

1.  **`Chart.yaml`**: Declares a dependency on the official third-party chart (e.g., `traefik/traefik`).
2.  **`values.yaml`**: Contains two sections:
    - A top-level key (e.g., `traefik:`) that passes a block of configuration directly to the subchart.
    - A section for values used by custom templates in our wrapper chart (e.g., the `ingress:` block for the dashboard).
3.  **`templates/`**: Contains any additional custom resources we want to layer on top, such as the `IngressRoute` for the Traefik dashboard.

This pattern gives us the power of official, community-maintained charts while retaining full control over configuration in a way that integrates perfectly with our GitOps workflow.
