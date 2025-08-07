# Documentation: Implementation Plan for Metrics Dashboard

This document outlines the comprehensive plan to build a metrics dashboard within the `pi-homepage` application. The dashboard will display both real-time and historical metrics about the Raspberry Pi host by querying the in-cluster Prometheus monitoring stack.

## 1. Architecture Overview: The BFF Proxy Pattern

To securely and efficiently get data from the in-cluster Prometheus server to the end-user's browser, we will use the **Backend for Frontend (BFF)** pattern. The `pi-homepage`'s Next.js server will act as a proxy.

This approach provides several key benefits:
-   **Security:** The Prometheus server is never exposed to the public internet. All queries are handled by our trusted BFF.
-   **Type Safety:** We will use gRPC and Protobuf to define a strict, type-safe API contract between our frontend and backend. This eliminates an entire class of data-related bugs.
-   **Decoupling:** The frontend is completely decoupled from the data source. It only knows how to talk to our BFF's gRPC API. If we were to change the monitoring backend from Prometheus to something else in the future, the frontend code would not need to change.

### 1.1. Data Flow Diagram

The end-to-end flow of a user request will be as follows:

```
[Browser]           [Next.js Server (BFF)]          [Kubernetes Cluster]
----------          ----------------------          --------------------

React Component  ->  gRPC call to /api/grpc/prometheus  ->  HTTP/JSON call to Prometheus  ->  [Prometheus Server]
(useQuery)                                                  (e.g., /api/v1/query_range)

[Recharts Chart] <-  gRPC response from BFF         <-  JSON response from Prometheus <-
```

## 2. Implementation Phases

### Phase 1: Infrastructure Setup (Completed)

This phase is complete. We have successfully deployed the `kube-prometheus-stack` Helm chart into the cluster via our GitOps workflow. This provides us with:
-   A running Prometheus server.
-   The Prometheus Operator for managing monitoring resources.
-   A running `node-exporter` instance on the Raspberry Pi, exposing host metrics.
-   Automatic discovery configured, so Prometheus is already scraping metrics from `node-exporter`.

### Phase 2: API Contract Definition (Protobuf)

This is the next step. We will define the formal API contract that our system will use.

1.  **Create Protobuf File:** Create a new file at `pi-protos/proto/prometheus/v1/prometheus.proto`.
2.  **Define Service:** Define a `PrometheusService` with two RPCs:
    -   `Query(QueryRequest)`: For fetching single, real-time metric values.
    -   `QueryRange(QueryRangeRequest)`: For fetching a series of data points for historical charts.
3.  **Define Messages:** Create all necessary request and response messages (`QueryRequest`, `QueryRangeResponse`, `TimeSeries`, `Sample`, etc.) that mirror the structure of the Prometheus JSON API.
4.  **Publish & Update:** Commit the new `.proto` file and publish a new version of the `pi-protos` packages.

### Phase 3: Backend Implementation (BFF Proxy in `pi-homepage`)

Once the API contract is defined, we will implement the server-side logic in the `pi-homepage` application.

1.  **Update Dependency:** Update `pi-homepage`'s `package.json` to use the new version of the generated TypeScript client from `pi-protos`.
2.  **Create API Route:** Create a new Next.js API route that implements the `PrometheusService` gRPC service.
3.  **Implement Proxy Logic:** Inside the API route, for each RPC:
    -   Receive and validate the incoming gRPC request.
    -   Construct the corresponding HTTP request URL for the internal Prometheus service (e.g., `http://prometheus-operated.prometheus.svc.cluster.local:9090/api/v1/query_range`).
    -   Execute the HTTP request.
    -   Receive the JSON response from Prometheus.
    -   Translate the JSON data into the appropriate Protobuf response message.
    -   Send the Protobuf message back to the client.

### Phase 4: Frontend Implementation (UI & Visualization)

With the backend in place, we will build the user-facing components.

1.  **Install Libraries:** Add `@tanstack/react-query` (for data fetching), `@connectrpc/connect-query` (for seamless integration between TanStack Query and our gRPC service), and `recharts` (for charting) to `pi-homepage`.
2.  **Create gRPC Client:** Instantiate the generated `PrometheusService` client, configured to talk to our BFF API route.
3.  **Build "Real-Time" Components:**
    -   Create React components to display live stats (e.g., gauges, single numbers).
    -   Use the `useQuery` hook to call the `Query` RPC.
    -   Configure `useQuery` with a `refetchInterval` of **10-15 seconds** to balance responsiveness with efficiency.
4.  **Build "Historical Chart" Components:**
    -   Create React components using `recharts` to display line charts.
    -   Use the `useQuery` hook to call the `QueryRange` RPC. This query will typically run only once on component load.
    -   Add UI controls (e.g., buttons, dropdowns) to allow the user to select different time ranges and manually refresh the chart data.

## 3. Storage Strategy: `emptyDir`

For this initial implementation, the Prometheus server is configured to use an `emptyDir` volume for its time-series database. This is a deliberate choice:
-   **It is simple:** It requires no complex storage configuration.
-   **It is sufficient:** It can easily store the last 24+ hours of metrics from our single node, which is more than enough for our dashboard's needs.
-   **Data is not critical:** The loss of historical metric data upon a pod restart is an acceptable trade-off for this project.

We will reconsider using a `PersistentVolume` if future requirements include long-term trend analysis or high-reliability alerting.
