# StatusWatch

[![CI Build and Test](https://github.com/chiranke-beep/statuswatch-service/actions/workflows/build.yml/badge.svg)](https://github.com/chiranke-beep/statuswatch-service/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A small integration service written in Ballerina. It checks the live status of GitHub, Cloudflare, and npm at the same time and returns one clean JSON summary.

## How it works

Instead of checking services one by one, StatusWatch checks all 3 APIs in parallel using Ballerina workers. This keeps response times fast.

```
                      ┌──> worker: GitHub Status
                      │
Client ──> /overview ─┼──> worker: Cloudflare Status
                      │
                      └──> worker: npm Registry Status
```

- **Parallel checks:** Uses Ballerina workers (`worker` and `wait`) so requests run at the same time.
- **Unified status:** Converts different status texts into standard values: `OPERATIONAL`, `DEGRADED`, `OUTAGE`, or `UNREACHABLE`.
- **Response times:** Measures response time for each service in milliseconds.
- **Safe error handling:** If one service fails or times out, the API still returns data for the other services and marks the status as `PARTIAL_OUTAGE`.

## Endpoints

### 1. Health check
```bash
curl http://localhost:9090/health/ping
```

Response:
```json
{
  "status": "ok",
  "timestamp": "2026-11-13T19:40:00Z"
}
```

### 2. Status overview
```bash
curl http://localhost:9090/health/overview
```

Response:
```json
{
  "overallStatus": "PARTIAL_OUTAGE",
  "totalMonitored": 3,
  "healthyCount": 2,
  "timestamp": "2026-11-13T19:45:04.727659700Z",
  "services": [
    {
      "name": "GitHub",
      "status": "OPERATIONAL",
      "details": "All Systems Operational",
      "responseTimeMs": 367.67
    },
    {
      "name": "Cloudflare",
      "status": "DEGRADED",
      "details": "Partially Degraded Service",
      "responseTimeMs": 619.37
    },
    {
      "name": "npm Registry",
      "status": "OPERATIONAL",
      "details": "All Systems Operational",
      "responseTimeMs": 604.38
    }
  ]
}
```

## Running locally

### Requirements
- Ballerina Swan Lake (Update 14 or newer)
- Java 17 or 21

### Start the service
```bash
bal run
```
The server runs on `http://localhost:9090`.

### Run tests
```bash
bal test
```

## Configuration

You can change port numbers, timeouts, and URLs in `Config.toml` without changing the code:

```toml
port = 9090
requestTimeoutSeconds = 5.0

githubStatusUrl = "https://www.githubstatus.com"
cloudflareStatusUrl = "https://www.cloudflarestatus.com"
npmStatusUrl = "https://status.npmjs.org"
```

## License
Apache 2.0
