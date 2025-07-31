# Documentation: Kubernetes Dashboard

This document details the deployment of the Kubernetes Dashboard.

## 1. Architecture: Wrapper Chart

We deploy the dashboard using a **wrapper chart** located at `charts/kube-dashboard`. This approach allows us to use the official, community-maintained Kubernetes Dashboard chart while layering our own custom configuration on top of it.

The wrapper chart's `Chart.yaml` declares two dependencies:
1.  The official `kubernetes-dashboard` chart.
2.  Our local `_common` chart, which provides helpers for our custom resources.

Our custom configuration is managed in the `values.yaml` file, and our additional resources (the `IngressRoute`, `ServiceAccount`, etc.) are defined in the `templates/` directory.

## 2. Deployment Steps

The deployment is managed from your **local machine**.

1.  **Update Helm Dependencies:**
    ```bash
    make helm-deps
    ```

2.  **Install the Chart:**
    ```bash
    helm install kube-dashboard ./charts/kube-dashboard --namespace kube-dashboard --create-namespace
    ```
    Alternatively, use the Makefile target: `make helm-install-all`.

## 3. Authentication: Service Account and Token

The dashboard is configured to use token-based authentication. The Helm chart creates a `ServiceAccount` named `admin-user` with `cluster-admin` privileges.

### How to Log In

1.  **Generate a Login Token:** From your local machine, run the following command:
    ```bash
    kubectl create token admin-user -n kube-dashboard
    ```
    *   **Note:** By default, this token is short-lived. You can request a longer duration with the `--duration` flag (e.g., `--duration=8h`).

2.  **Copy the entire token** that is printed to the console.

3.  **Access the Dashboard:**
    *   -   Open your browser and navigate to **https://kube-pi.taehoonlee.dev**.
    *   Select the **Token** authentication method.
    *   Paste the token into the field and click **Sign in**.

## 4. Ingress and Networking

The wrapper chart includes templates for three crucial Traefik resources:

-   **`Middleware`**: Strips the URL prefix before forwarding the request.
-   **`ServersTransport`**: Tells Traefik to skip TLS verification when connecting to the dashboard's internal HTTPS service. This is necessary because the dashboard uses a self-signed certificate.
-   **`IngressRoute`**: Defines the rule that maps the public path to the correct backend service (`kube-dashboard-kong-proxy`), applying the middleware and transport.
