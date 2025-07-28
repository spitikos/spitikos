# Documentation: Helm Chart Architecture

This document explains the reusable and maintainable Helm chart architecture used in this project, which is based on a "common library" pattern.

## 1. The "Common" Library Chart

Instead of creating nearly identical templates for every application, we use a single, generic **library chart** located at `charts/common`.

*   **Purpose:** This chart contains all the boilerplate templates for deploying a standard web application (`Deployment`, `Service`, `IngressRoute`, `Middleware`).
*   **Type:** Its `Chart.yaml` defines it as `type: library`. This means it cannot be deployed directly but is intended to be used as a dependency by other charts.
*   **Templates:** The templates in this chart are completely generic and use Helm variables (e.g., `{{ .Values.image.repository }}`) to render the final resources.

## 2. Application (Wrapper) Charts

Each application (e.g., `whoami`, `stats`) has its own lightweight **wrapper chart** located in `charts/api/` or `charts/frontend/`.

These charts are very simple and consist of only two key files:

*   **`Chart.yaml`**: This file defines the application's metadata (name, version, etc.) and, most importantly, declares a **dependency** on the `common` chart.

    ```yaml
    dependencies:
      - name: common
        version: "0.1.0"
        # The path is relative to the application chart's location
        repository: "file://../../common"
    ```

*   **`values.yaml`**: This file provides the specific values that the `common` chart's templates will use. This is where we define the application's unique properties, such as its container image, ingress path, and service port.

    ```yaml
    # Example values.yaml for the 'stats' app
    image:
      repository: ghcr.io/ethn1ee/pi-stats
      tag: "latest"

    ingress:
      host: pi.taehoonlee.dev
      path: /api/stats
    ```

## 3. How to Deploy a New Application

1.  **Create a new wrapper chart directory** (e.g., `charts/api/new-app`).
2.  **Create `Chart.yaml`** inside it, adding the dependency on the `common` chart.
3.  **Create `values.yaml`** inside it, specifying the image, ingress path, and other necessary values for your new application.
4.  **Update Helm dependencies:** From the project root, run:
    ```bash
    helm dependency update ./charts/api/new-app
    ```
5.  **Install the chart:**
    ```bash
    helm install new-app ./charts/api/new-app --namespace api
    ```

This architecture ensures that all applications are deployed consistently and makes the entire system much easier to maintain and scale.
