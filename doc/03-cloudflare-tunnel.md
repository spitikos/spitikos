# Documentation: Cloudflare Tunnel

This document explains how to set up `cloudflared` to create a secure, outbound-only connection from the Raspberry Pi to the Cloudflare network, exposing services without opening any ports on your router.

## 1. Install `cloudflared`

The `cloudflared` daemon runs as a service on the Pi.

### Installation Steps

1.  **Download the ARM64 package:**
    ```bash
    curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
    ```

2.  **Install the package:**
    ```bash
    sudo dpkg -i cloudflared.deb
    ```

## 2. Authenticate and Create the Tunnel

1.  **Login:** Authenticate `cloudflared` with your Cloudflare account. This will open a browser window for you to authorize access to your domain.
    ```bash
    cloudflared tunnel login
    ```

2.  **Create Tunnel:** Register a new, persistent tunnel with Cloudflare. We use the name `pi` for this project.
    ```bash
    cloudflared tunnel create pi
    ```
    This command will output a **Tunnel UUID** and the path to a **credentials file** (e.g., `/root/.cloudflared/<UUID>.json`). **Save these values.**

## 3. Configure Ingress Rules

The configuration file tells `cloudflared` how to route incoming traffic.

1.  **Create the directory:**
    ```bash
    sudo mkdir -p /etc/cloudflared
    ```

2.  **Create the configuration file** at `/etc/cloudflared/config.yml` with the following content:
    ```yaml
    # The Tunnel UUID from the 'tunnel create' command
    tunnel: <YOUR_TUNNEL_UUID>
    # The path to the credentials file
    credentials-file: <YOUR_CREDENTIALS_FILE_PATH>
    # Ingress rules
    ingress:
      # This rule handles traffic for the project's hostname.
      - hostname: pi.taehoonlee.dev
        # It points to the Traefik NodePort service on the Pi's LAN IP.
        service: http://10.0.0.200:30080
      # A required catch-all rule.
      - service: http_status:404
    ```
    *   **Note:** Replace `<YOUR_TUNNEL_UUID>` and `<YOUR_CREDENTIALS_FILE_PATH>` with the values from the previous step.

## 4. Route DNS and Run as a Service

1.  **Create DNS Record:** This command creates a `CNAME` record in your Cloudflare DNS, pointing `pi.taehoonlee.dev` to your tunnel.
    ```bash
    cloudflared tunnel route dns pi pi.taehoonlee.dev
    ```

2.  **Install the Service:** This installs `cloudflared` as a `systemd` service, ensuring it starts automatically on boot.
    ```bash
    sudo cloudflared service install
    ```

3.  **Verify:** Check the service status to ensure it's running correctly.
    ```bash
    sudo systemctl status cloudflared
    ```
The tunnel is now active and routing traffic to your Pi.
