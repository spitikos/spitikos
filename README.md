# Pi Homelab

Monorepo of my Raspberry Pi Kubernetes cluster

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

## Apps

All apps deployed in this pi cluster exist as microservices, deployed using Helm charts.

### Routes

```sh
 /
├── /kube-dashboard
├── /api
│  ├── /stats

```
