# Pi Homelab

Monorepo of my Raspberry Pi Kubernetes cluster

## Apps

Visit [pi.taehoonlee.dev](https://pi.taehoonlee.dev). All apps deployed in this pi cluster exist as microservices, deployed using Helm charts. All pages and APIs are publicly available.

### Pages

| Route                                                         | Description          |
| ------------------------------------------------------------- | -------------------- |
| [`/`](https://pi.taehoonlee.dev)                              | Homepage             |
| [`/kube-dashboard`](https://pi.taehoonlee.dev/kube-dashboard) | Kubernetes Dashboard |

### API

| Route                                                 | Description                                                |
| ----------------------------------------------------- | ---------------------------------------------------------- |
| [`/api/stats`](https://pi.taehoonlee.dev/api/stats)   | Pi resource stats (cpu, memory, temperature, etc.)         |
| [`/api/whoami`](https://pi.taehoonlee.dev/api/whoami) | [Traefik whoami](https://github.com/traefik/whoami) server |

## Project Structure

```sh
.
├── apps            # git submodules to apps deployed in the pi cluster
├── charts          # helm charts
├── docs            # documentation of the pi setup and architecture
├── GEMINI.md       # Gemini agent config
├── Makefile
└── README.md
```
