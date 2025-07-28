# Raspberry Pi k3s Setup Plan (Detailed)

This document outlines the step-by-step plan to configure a Raspberry Pi 5 with k3s and Cloudflare Tunnel for securely hosting applications. Each step includes detailed commands, configurations, and verification procedures.

**User-Specific Information:**
*   **Hostname:** `pi.taehoonlee.dev`
*   **Routing Strategy:** Path-based (`/` for frontend, `/api/...` for backends)
*   **Static IP:** `10.0.0.200`
*   **Tunnel Name:** `k3s-tunnel`

---

### **Phase 1: Raspberry Pi & k3s Initial Setup**

**(This phase remains unchanged)**

1.  **Configure Static IP Address:**
    *   **Objective:** Ensure the Pi has a predictable IP for stable `kubectl` and SSH access.
    *   **File:** `/etc/netplan/50-cloud-init.yaml`
    *   **Command (on Pi):** `sudo netplan apply`

2.  **Install k3s:**
    *   **Objective:** Install Kubernetes, disabling the default Traefik for a controlled Helm installation.
    *   **Command (on Pi):** `curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik" sh -s - --write-kubeconfig-mode 644`

3.  **Configure Local `kubectl` Access:**
    *   **Objective:** Enable cluster management from your local development machine.
    *   **Action:** Copy `/etc/rancher/k3s/k3s.yaml` from the Pi to your local `~/.kube/config` and change the server IP to `https://10.0.0.200:6443`.
    *   **Verification:** `kubectl get nodes`

---

### **Phase 2: Cloudflare Tunnel Configuration**

**Goal:** Establish a secure connection from Cloudflare to the Raspberry Pi.

**Prerequisite:** The domain `taehoonlee.dev` must be active in your Cloudflare account.

1.  **Install `cloudflared` Daemon:**
    *   **Objective:** Install the tunnel software on the Pi.
    *   **Commands (on Pi):**
        ```bash
        curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
        sudo dpkg -i cloudflared.deb
        ```

2.  **Authenticate and Create Tunnel:**
    *   **Objective:** Register a new, named tunnel with Cloudflare.
    *   **Command (on Pi):** `cloudflared tunnel login` (Select `taehoonlee.dev`)
    *   **Command (on Pi):** `cloudflared tunnel create k3s-tunnel` (**Save the UUID and credentials file path**)

3.  **Configure Tunnel Ingress Rules:**
    *   **Objective:** Route traffic for `pi.taehoonlee.dev` to the local Traefik service.
    *   **File:** `/etc/cloudflared/config.yml`
    *   **Content:**
        ```yaml
        tunnel: <YOUR_TUNNEL_UUID>
        credentials-file: /root/.cloudflared/<YOUR_TUNNEL_UUID>.json
        ingress:
          # Route traffic for the specific hostname to our Traefik service.
          - hostname: pi.taehoonlee.dev
            service: http://localhost:8080
          # Required catch-all rule.
          - service: http_status:404
        ```

4.  **Route DNS and Run as a Service:**
    *   **Objective:** Create the public DNS record and run the tunnel automatically.
    *   **Command (on Pi):** `cloudflared tunnel route dns k3s-tunnel pi.taehoonlee.dev`
    *   **Command (on Pi):** `sudo cloudflared service install`
    *   **Verification:** Check for a `CNAME` record for `pi` in your Cloudflare DNS dashboard and run `sudo systemctl status cloudflared`.

---

### **Phase 3: Traefik Ingress Controller Installation**

**(This phase remains unchanged)**

1.  **Add Traefik Helm Repository:**
    *   **Commands (on Local Machine):**
        ```bash
        helm repo add traefik https://helm.traefik.io/traefik
        helm repo update
        ```

2.  **Install Traefik via Helm:**
    *   **Commands (on Local Machine):**
        ```bash
        kubectl create namespace traefik
        helm install traefik traefik/traefik \
          --namespace=traefik \
          --set="ports.web.port=8080" \
          --set="ports.web.expose=true" \
          --set="ports.websecure.tls.enabled=false"
        ```
    *   **Verification:** `kubectl get pods -n traefik`

---

### **Phase 4: Application Deployment & Path-Based Routing**

**Goal:** Deploy the frontend and backend applications, routing traffic based on the URL path.

**Concept:** We will create multiple `IngressRoute` resources. Traefik will process them in order of specificity. More specific paths (`/api/my-service`) must be defined before the general catch-all path (`/`).

1.  **Deploy a Backend API:**
    *   **Objective:** Expose a backend service at `https://pi.taehoonlee.dev/api/my-api`.
    *   **Step 1: Deploy your API.** First, deploy your API application (e.g., using a `Deployment` and `Service`) into a namespace, for example `my-api-namespace`. Your service should expose the application's port (e.g., port `8000`).
    *   **Step 2: Create the `StripPrefix` Middleware.** When a request comes in to `/api/my-api`, Traefik needs to forward only `/` to your application pod. This middleware does that.
        *   **File:** `app/my-api/middleware.yaml`
        ```yaml
        apiVersion: traefik.io/v1alpha1
        kind: Middleware
        metadata:
          name: my-api-strip-prefix
          namespace: my-api-namespace # Must be in the same namespace as the IngressRoute
        spec:
          stripPrefix:
            prefixes:
              - /api/my-api
        ```
    *   **Step 3: Create the `IngressRoute`.** This rule tells Traefik how to route the traffic.
        *   **File:** `app/my-api/ingress-route.yaml`
        ```yaml
        apiVersion: traefik.io/v1alpha1
        kind: IngressRoute
        metadata:
          name: my-api-ingress-route
          namespace: my-api-namespace
        spec:
          entryPoints:
            - web
          routes:
            - match: Host(`pi.taehoonlee.dev`) && PathPrefix(`/api/my-api`)
              kind: Rule
              services:
                - name: my-api-service # The name of your Kubernetes Service
                  port: 8000 # The port your Service exposes
              middlewares:
                - name: my-api-strip-prefix # Apply the middleware
        ```
    *   **Step 4: Apply the manifests.**
        ```bash
        kubectl apply -f app/my-api/
        ```

2.  **Deploy the Next.js Frontend:**
    *   **Objective:** Expose the Next.js application at `https://pi.taehoonlee.dev/`.
    *   **Step 1: Deploy your Next.js app.** Deploy your frontend (e.g., using a `Deployment` and `Service`) into a namespace, for example `frontend-namespace`. Your service should expose the application's port (e.g., port `3000`).
    *   **Step 2: Create the `IngressRoute`.** This is the "catch-all" route for the domain. Because its `PathPrefix` is `/`, it is less specific than the API routes and will only match if no other path-based rules do.
        *   **File:** `app/frontend/ingress-route.yaml`
        ```yaml
        apiVersion: traefik.io/v1alpha1
        kind: IngressRoute
        metadata:
          name: frontend-ingress-route
          namespace: frontend-namespace
        spec:
          entryPoints:
            - web
          routes:
            - match: Host(`pi.taehoonlee.dev`) && PathPrefix(`/`)
              kind: Rule
              services:
                - name: nextjs-frontend-service # The name of your Kubernetes Service
                  port: 3000 # The port your Service exposes
        ```
    *   **Step 3: Apply the manifest.**
        ```bash
        kubectl apply -f app/frontend/
        ```
