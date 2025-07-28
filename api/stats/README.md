# Raspberry Pi Stats SSE Server

A SSE (Server-Sent Events) server that provides a real-time monitoring of cpu, disk, memory, etc. every second, utilizing the `gopsutil` package. The server is built for a personal use for monitoring the Raspberry Pi's system resources, but it can be easily adapted for any other platforms.

## Sample Stat

```json
{
  "cpu": [
    0.9999999996844054,
    1.9801980194952786,
    1.9801980198483422,
    0.9999999998399289
  ],
  "disk": {
    "total": 503541698560,
    "free": 475694473216,
    "used": 7334039552,
    "usedPercent": 1.5183450579288185
  },
  "host": {
    "bootTime": 1753640757,
    "uptime": 25761,
    "processes": 203,
    "os": "linux",
    "platform": "ubuntu",
    "architecture": "aarch64"
  },
  "memory": {
    "total": 8321318912,
    "available": 6326927360,
    "used": 1779929088,
    "used_percent": 21.389987654880063
  },
  "temperature": {
    "cpuTemperature": 54.55,
    "nvmeTemperature": 50.85
  }
}

```
