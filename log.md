# Gemini Development Log - Raspberry Pi k3s Setup

**Objective:** To configure a Raspberry Pi 5 running Ubuntu Server for hosting applications with k3s, accessible via a custom domain.

---

### **Phase 1: Initial Pi Network Configuration**

*   **Goal:** Assign a static IP address to the Raspberry Pi for stable network access.
*   **Initial Discussion:** Considered editing `/boot/firmware/config.txt` but determined the modern Ubuntu method is using `netplan`.
*   **Action:** Configured `netplan` for a static IP.
*   **Key Configuration (`/etc/netplan/50-cloud-init.yaml`):**
    ```yaml
    network:
      version: 2
      renderer: networkd
      wifis:
        wlan0:
          dhcp4: no
          addresses:
            - 10.0.0.200/24
          routes:
            - to: default
              via: 10.0.0.1
          nameservers:
            addresses: [8.8.8.8, 8.8.4.4]
          access-points:
            "924HL":
              auth:
                key-management: "psk"
                password: "af7a105bc05922a6b887d55a4759ce3733891dc33f6c1d19487577f7600ce9da"
    ```
*   **Outcome:** Pi successfully assigned the static IP `10.0.0.200`.

---

### **Phase 2: k3s Installation & Dashboard Access**

*   **Goal:** Install k3s, deploy the Kubernetes Dashboard, and access it from the local network.
*   **Action (User):** Installed k3s and deployed the dashboard via Helm.
*   **Action (Gemini):** Provided steps to access the dashboard.
*   **Access Method:** Used `kubectl port-forward` to create a secure tunnel from the local machine to the dashboard service.
*   **Key Command:**
    ```bash
    kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 8443:443
    ```
*   **Outcome:** Successfully accessed the dashboard at `https://localhost:8443`.

---

### **Phase 3: Public Exposure via `kube.taehoonlee.dev`**

*   **Goal:** Make the dashboard securely accessible from the internet via a custom domain.
*   **Chosen Technology:** Cloudflare Tunnel for its security benefits (no open ports on the router).

#### **Step 3.1: Initial Tunnel Setup (Non-Scalable Method)**

*   **Action:** Configured a Cloudflare Tunnel to point to the `kubectl port-forward` process on the Pi.
*   **Problem 1:** The `kubectl port-forward` process was not persistent.
*   **Solution 1:** Created a `systemd` service (`k3s-port-forward.service`) to ensure the port-forward runs automatically on boot.
*   **Problem 2:** The overall approach was not scalable for hosting multiple websites.

#### **Step 3.2: Refactoring to a Scalable Ingress Model**

*   **Goal:** Use the built-in Traefik Ingress Controller to manage all traffic, making the setup scalable.
*   **Action:** Re-configured the Cloudflare Tunnel to point directly to the internal Traefik service.
*   **Key Configuration (`/etc/cloudflared/config.yml`):**
    ```yaml
    ingress:
      - hostname: '*.taehoonlee.dev'
        service: http://10.43.199.221:80 # Traefik's Cluster-IP
      - service: http_status:404
    ```
*   **Action:** Disabled and removed the `k3s-port-forward.service`.

#### **Step 3.3: Configuring the Ingress Route**

*   **Problem:** A standard `Ingress` resource failed because it couldn't specify the `https` scheme for the backend dashboard service, resulting in a middleware error in Traefik logs.
*   **Solution:** Used a Traefik-specific `IngressRoute` Custom Resource, which is more powerful.
*   **Action:** Created the definitive manifest to route traffic for `kube.taehoonlee.dev` to the dashboard.
*   **Key Manifest (`app/kubernetes-dashboard/ingressroute-dashboard.yaml`):**
    ```yaml
    apiVersion: traefik.io/v1alpha1
    kind: IngressRoute
    metadata:
      name: kubernetes-dashboard-ingressroute-dashboard
      namespace: kubernetes-dashboard
    spec:
      entryPoints:
        - web
      routes:
        - match: Host(`kube.taehoonlee.dev`)
          kind: Rule
          services:
            - name: kubernetes-dashboard-kong-proxy
              port: 443
              scheme: https
    ```
*   **Outcome:** The dashboard is now successfully and securely exposed to the internet at `https://kube.taehoonlee.dev`. The entire setup is persistent across reboots and scalable for future applications.

---

### **Phase 4: Establishing Conventions**

*   **Goal:** Define a set of rules for consistent development and configuration.
*   **Action:** Created and iterated on rules within the `GEMINI.md` file.
*   **Final Convention for Kubernetes Manifests:**
    *   **File Path:** `app/<namespace>/<kind>-<descriptor>.yaml`
    *   **Resource `metadata.name`:** `<namespace>-<kind>-<descriptor>`
*   **Outcome:** A clear and organized structure for managing Kubernetes resources is now in place.
