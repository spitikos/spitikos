# Documentation: Traefik Ingress Controller

This document covers the installation and configuration of the Traefik Ingress Controller, which is responsible for routing external traffic to the correct services within the Kubernetes cluster.

## 1. Why a Manual Install?

We disabled the k3s-bundled Traefik to allow for a manual installation via Helm. This provides granular control over the configuration, which was necessary to solve port conflicts and correctly integrate with our `cloudflared` setup.

## 2. Installation via Helm

The installation is managed from your **local machine**.

1.  **Add the Traefik Helm Repository:**
    ```bash
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update
    ```

2.  **Create the Namespace:**
    ```bash
    kubectl create namespace traefik
    ```

3.  **Install the Chart with Custom Configuration:**
    The following command installs Traefik with a specific configuration tailored for our architecture.

    ```bash
    helm install traefik traefik/traefik \
      --namespace=traefik \
      --set="service.type=NodePort" \
      --set="ports.web.nodePort=30080" \
      --set="entryPoints.websecure.address="
    ```

### Key Configuration Parameters Explained

*   `--set="service.type=NodePort"`: This is the crucial setting that exposes Traefik on a high-numbered port on the Raspberry Pi's own network interface. This allows the `cloudflared` service (running on the host) to connect to it.
*   `--set="ports.web.nodePort=30080"`: We explicitly set the `NodePort` to a predictable value (`30080`). This is the port that `cloudflared` is configured to forward traffic to.
*   `--set="entryPoints.websecure.address="`: We disable the `websecure` (HTTPS) entrypoint by setting its address to an empty string. This is because TLS is terminated at the Cloudflare edge, and traffic within our cluster is plain HTTP. This prevents port conflicts and simplifies the setup.

## 3. Verification

After the installation, you can verify that the Traefik service is correctly configured by running:

```bash
kubectl get service traefik -n traefik
```

The output should show a `TYPE` of `NodePort` and a `PORT(S)` mapping of `8080:30080/TCP`. This confirms that the internal port `8080` of the Traefik service is correctly exposed on port `30080` of the Raspberry Pi node.

```