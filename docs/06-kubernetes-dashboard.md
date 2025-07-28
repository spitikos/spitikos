# Documentation: Kubernetes Dashboard

This document details the deployment of the Kubernetes Dashboard, a general-purpose web UI for Kubernetes clusters.

## 1. Architecture: Wrapper Chart

We deploy the dashboard using a **wrapper chart** located at `charts/kubernetes-dashboard`. This approach allows us to use the official, community-maintained Kubernetes Dashboard chart while layering our own custom configuration on top of it.

The wrapper chart's `Chart.yaml` declares a dependency on the official `kubernetes-dashboard` chart. Our custom configuration is managed in the `values.yaml` file and our additional resources (like the `IngressRoute`) are defined in the `templates/` directory.

## 2. Deployment Steps

The deployment is managed from your **local machine**.

1.  **Update Helm Dependencies:** This command downloads the official dashboard chart into our wrapper chart's `charts/` subdirectory.
    ```bash
    helm dependency update ./charts/kubernetes-dashboard
    ```

2.  **Create the Namespace:**
    ```bash
    kubectl create namespace kubernetes-dashboard
    ```

3.  **Install the Chart:**
    ```bash
    helm install kubernetes-dashboard ./charts/kubernetes-dashboard --namespace kubernetes-dashboard
    ```

## 3. Authentication: Service Account and Token

The dashboard is configured to use token-based authentication. The Helm chart creates a `ServiceAccount` named `admin-user` with `cluster-admin` privileges, providing full access to the cluster.

### How to Log In

1.  **Generate a Login Token:** From your local machine, run the following command to generate a temporary access token for the `admin-user`.
    ```bash
    kubectl create token admin-user -n kubernetes-dashboard
    ```
    *   **Note:** By default, this token is short-lived. You can request a longer duration with the `--duration` flag (e.g., `--duration=8h`).

2.  **Copy the entire token** that is printed to the console.

3.  **Access the Dashboard:**
    *   Open your browser and navigate to **https://pi.taehoonlee.dev/kubernetes-dashboard/**.
    *   Select the **Token** authentication method.
    *   Paste the token into the field and click **Sign in**.

## 4. Ingress and Networking

The wrapper chart includes templates for three crucial Traefik resources:

*   **`Middleware`**: Strips the `/kubernetes-dashboard` URL prefix before forwarding the request.
*   **`ServersTransport`**: This important resource tells Traefik to skip TLS verification when connecting to the dashboard's internal service. This is necessary because the dashboard uses a self-signed certificate, and without this transport, Traefik would reject the connection.
*   **`IngressRoute`**: Defines the rule that maps `pi.taehoonlee.dev/kubernetes-dashboard` to the correct backend service (`kubernetes-dashboard-kong-proxy`), applying the middleware and transport.
