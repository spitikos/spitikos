# Documentation: Local Development with Telepresence

This document explains how to set up and use [Telepresence](https://www.telepresence.io/) to enable a seamless local development experience when working with services that run inside the Kubernetes cluster.

This approach allows you to run a service (e.g., the `homepage` frontend) on your local machine and have it communicate directly with backend services (e.g., the `api-stats` gRPC server) running in the cluster, without needing `kubectl port-forward` or separate development configurations.

## 1. The Problem: Accessing In-Cluster Services

When a service like the `api-stats` server is deployed without an ingress, it is only accessible from within the cluster's network. This is great for security but poses a challenge for local development. `kubectl port-forward` is a possible solution, but it requires developers to constantly switch between using `localhost` in development and the real service name in production.

## 2. The Solution: Telepresence

Telepresence solves this by creating a smart proxy that makes your local machine part of the Kubernetes cluster's network. When connected, you can:
-   **Resolve Cluster DNS:** Access services using their standard Kubernetes DNS names (e.g., `api-stats.api-stats.svc.cluster.local`).
-   **Access Cluster IPs:** Directly communicate with `ClusterIP` and `PodIP` addresses.

This means your local development server can use the exact same production configuration to connect to its backend dependencies.

**Note for Web Frontends:** For browser-based applications (like the Next.js `homepage`), the backend gRPC server (e.g., `api-stats`) must also be configured with a Cross-Origin Resource Sharing (CORS) policy. While Telepresence handles the network connection, the browser will still enforce CORS checks. The server needs to send the appropriate headers to allow requests from the frontend's origin (e.g., `http://localhost:3000`).

## 3. Setup and Usage

### 3.1. Installation

Telepresence must be installed on your local machine.

1.  **Install the CLI (macOS):**
    ```bash
    # This is the correct tap for the open-source version
    brew install telepresenceio/telepresence/telepresence-oss
    ```

2.  **Install the Traffic Manager:**
    The Telepresence Traffic Manager is a service that runs inside your cluster and manages the connection.
    ```bash
    telepresence helm install
    ```
    *Note: By default, this installs to the `traffic-manager` namespace.*

### 3.2. Connecting to the Cluster

Once installed, you can connect your machine to the cluster.

```bash
# Connect to the cluster using sudo to grant the daemon the necessary
# root permissions to manage networking.
sudo telepresence connect
```

If successful, you will see output confirming the connection. Your machine now has direct access to the cluster's network.

### 3.3. Running a Local Service

With Telepresence connected, you can run your application locally as you normally would.

**Example: Running the `homepage` frontend:**
1.  `cd` into the `apps/homepage` directory.
2.  Run `pnpm dev`.
3.  The Next.js application's gRPC client is configured to talk to its own backend proxy at `/api/grpc`. When a request comes in, the server-side code of the proxy attempts to connect to the internal service address: `api-stats.api-stats.svc.cluster.local:50051`.
4.  Because Telepresence is connected, your local machine can resolve this internal Kubernetes address, and the connection succeeds.

### 3.4. Disconnecting

When you are finished with your development session, you can disconnect from the cluster.

```bash
telepresence quit
```
