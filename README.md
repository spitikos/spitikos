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

## Pages

| Route           | Description          |
| --------------- | -------------------- |
| /               | Homepage             |
| /kube-dashboard | Kubernetes Dashboard |

## API

| Route       | Description                                                |
| ----------- | ---------------------------------------------------------- |
| /api/whoami | [Traefik whoami](https://github.com/traefik/whoami) server |
| /api/stats  | Pi resource stats (cpu, memory, temperature, etc.)         |
