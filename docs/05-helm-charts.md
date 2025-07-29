# Documentation: Helm Chart Architecture

This document explains the reusable and maintainable Helm chart architecture used in this project. The design is based on the idiomatic **Common Library Chart** pattern.

## 1. The `_common` Library Chart

Instead of creating nearly identical templates for every application, we use a single, generic **library chart** located at `charts/_common`.

-   **`Chart.yaml`:** The chart is defined with `type: library`. This tells Helm that it only provides template helpers and cannot be deployed directly.
-   **`templates/_helpers.tpl`:** This file contains all the boilerplate Kubernetes resource definitions (`Deployment`, `Service`, `IngressRoute`, etc.), but each one is wrapped in a named `{{ define "..." }}` block. This turns them into callable functions. For example, `{{ define "common.deployment" . }}`.

## 2. Application (Wrapper) Charts

Each application (e.g., `homepage`, `stats`) has its own lightweight **wrapper chart**.

These charts are very simple and consist of three key parts:

1.  **`Chart.yaml`**: Defines the application's metadata and, most importantly, declares a **dependency** on the `_common` chart.
    ```yaml
    dependencies:
      - name: common
        version: "0.1.0"
        repository: "file://../_common" # Relative path to the common chart
    ```

2.  **`values.yaml`**: Provides the specific values that the `_common` chart's templates will use. This is where we define the application's unique properties, such as its container image, ingress path, and service port.

3.  **`templates/` directory**: This directory contains simple, one-line "pass-through" template files. Each file explicitly calls a corresponding template from the `_common` chart.
    
    **Example: `charts/homepage/templates/deployment.yaml`**
    ```yaml
    {{- include "common.deployment" . -}}
    ```
    This tells Helm: "For the `homepage` chart, render a Deployment using the `common.deployment` template and the values from `homepage/values.yaml`."

## 3. How to Deploy a New Application

1.  Create a new application chart directory (e.g., `charts/api/new-app`).
2.  Create `Chart.yaml` with a dependency on `_common`.
3.  Create `values.yaml` with the specific configuration for the new app.
4.  Create a `templates/` directory containing the pass-through template files (e.g., `deployment.yaml`, `service.yaml`) that `include` the desired templates from the `_common` chart.
5.  Run `make helm-deps` to update all dependencies.
6.  Run `make helm-install-all` or install the specific chart manually.
