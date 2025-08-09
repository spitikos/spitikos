# Documentation: Cloudflare Tunnel

This document explains how to set up `cloudflared` to create a secure, outbound-only connection from the Raspberry Pi to the Cloudflare network. This exposes services to the internet without opening any firewall ports, and provides a managed TLS certificate at the Cloudflare edge.

## 1. Installation and Authentication

(The installation and authentication steps remain the same as before: install the `cloudflared` package, log in, and create a tunnel, saving the UUID and credentials file path.)

## 2. DNS Configuration: Subdomain-based Routing

To avoid issues with path-based routing and SSL certificates, we use a clean, subdomain-based routing strategy. Each service gets its own unique hostname.

In the Cloudflare DNS dashboard for your domain, create the following `CNAME` records. They should all point to your tunnel's public address (e.g., `<UUID>.cfargotunnel.com`).

| Type    | Name         | Target                    |
| :------ | :----------- | :------------------------ |
| `CNAME` | `pi`         | `<UUID>.cfargotunnel.com` |
| `CNAME` | `argocd-pi`  | `<UUID>.cfargotunnel.com` |
| `CNAME` | `kube-pi`    | `<UUID>.cfargotunnel.com` |
| `CNAME` | `traefik-pi` | `<UUID>.cfargotunnel.com` |

This setup ensures that Cloudflare's Universal SSL certificate properly covers all hostnames.

## 3. Tunnel Configuration (`config.yml`)

The `cloudflared` service on the Raspberry Pi must be configured to accept traffic for all public hostnames and route them to the correct internal services.

The configuration file at `/etc/cloudflared/config.yml` should be structured with the most specific rules first.

```yaml
# The Tunnel UUID from the 'tunnel create' command
tunnel: <YOUR_TUNNEL_UUID>
# The path to the credentials file
credentials-file: <YOUR_CREDENTIALS_FILE_PATH>

# Ingress rules define which hostnames are accepted and where they go.
ingress:
  # 1. Specific services that do not go to the Traefik ingress controller.
  - hostname: "k8s.spitikos.dev"
    service: https://127.0.0.1:6443
    originRequest:
      noTLSVerify: true
  - hostname: "ssh.spitikos.dev"
    service: ssh://127.0.0.1:22

  # 2. The root domain for the homepage, which goes to Traefik.
  - hostname: "spitikos.dev"
    service: http://10.0.0.200:30080

  # 3. A wildcard for all other subdomains, which also go to Traefik.
  - hostname: "*.spitikos.dev"
    service: http://10.0.0.200:30080

  # 4. A required catch-all rule to terminate the list.
  - service: http_status:404
```

After creating this configuration, install and start the `cloudflared` service on the Pi.

```bash
sudo cloudflared service install
sudo systemctl start cloudflared
```

The tunnel is now active and routing traffic for all configured services.
