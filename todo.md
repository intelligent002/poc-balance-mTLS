# 🌐 Envoy mTLS Load Balancer — Technical Specification
### Project: Multi-Node mTLS Load-Balancing Proxy Using Envoy

## 📌 Overview
We require an Envoy configuration that functions as:

- a **strict mTLS gateway** (frontend)
- a **secure mTLS upstream load balancer** (backend)
- balancing across **three backend nodes**
- each node requiring **unique SNI and Host headers**
- including **health checks**, **failover**, **retries**, **circuit breakers**, and **structured logs**

The final deliverable must be a complete, validated `envoy.yaml`, deployable via Docker.

---

# 🧩 1. Frontend (Downstream) Requirements

Envoy must accept mTLS traffic on:

```
Host: node-00.intel.r7g.org
Port: 8400
```

### Mandatory Requirements
- TLS termination at Envoy  
- Client certificate **required** (strict mTLS)  
- Allow only certificates signed by `/ssl/CA/ca.crt`  
- Envoy server certificate:
  - `/ssl/nodes/node-00.intel.r7g.org/node-00.intel.r7g.org.crt`
  - `/ssl/nodes/node-00.intel.r7g.org/node-00.intel.r7g.org.key`
- TLS version: **TLSv1.3 only**
- Enforce SNI: `node-00.intel.r7g.org`

---

# 🧩 2. Backend (Upstream) Requirements

Envoy must send traffic to three backend nodes:

| Node   | Hostname              | Port | Required Host Header      | Required SNI              |
|--------|------------------------|------|-----------------------------|----------------------------|
| node01 | node-01.intel.r7g.org | 8401 | node-01.intel.r7g.org | node-01.intel.r7g.org |
| node02 | node-02.intel.r7g.org | 8402 | node-02.intel.r7g.org | node-02.intel.r7g.org |
| node03 | node-03.intel.r7g.org | 8403 | node-03.intel.r7g.org | node-03.intel.r7g.org |

### Upstream TLS Requirements
- TLSv1.3 required  
- mTLS with client cert:
  - `/ssl/users/admin/admin.crt`
  - `/ssl/users/admin/admin.key`
- Upstream trust: `/ssl/CA/ca.crt`
- Each backend node must be contacted with:
  - its own **SNI**
  - its own **Host header**

---

# 🧩 3. Load Balancing Requirements
- Switchable load balancing algorithms: **round_robin** / **least_request** / ... 
- Even traffic distribution across healthy nodes  
- Immediate removal of failed nodes  
- **Never return 503 while at least one node is UP**  
- No stale or half-open connections allowed  

---

# 🧩 4. Health Check Requirements

Health checks should use the same route as the regular requests in scope of host Header & SNI requirements.
It may be duplicated if required, but the same.

### Health Check Settings
| Setting             | Value |
|---------------------|--------|
| Interval            | 15s   |
| Timeout             | 2s    |
| Unhealthy threshold | 1     |
| Healthy threshold   | 2     |
| Path                | `/health` |
| Expected Status     | 200   |

On failure:
- Node marked **UNHEALTHY** immediately  
- All connections closed  
- Node excluded from routing  

---

# 🧩 5. Retry & Failover Requirements

### Retry Policy
```
retry_on: connect-failure, reset, 5xx
num_retries: 3
per_try_timeout: 1s
host_selection_retry_max_attempts: 3
```

### Critical
```
close_connections_on_host_health_failure: true
```

---

# 🧩 6. Circuit Breakers & Timeouts
### Circuit Breakers
```
max_connections: 1024
max_pending_requests: 1024
max_requests: 1024
max_retries: 3
```

### Required Timeout Categories
- connect timeout  
- request timeout  
- idle timeout  
- stream idle timeout  
- connection idle timeout  

---

# 🧩 7. Panic Mode Requirements
```
healthy_panic_threshold: 0
```

---

# 🧩 8. Logging Requirements

### Structured JSON Logs should include:

#### Downstream TLS Fields
- TLS version  
- cipher suite  
- client cert CN  
- certificate subject & issuer  
- SNI  

#### HTTP Request Fields
- timestamp  
- method  
- path  
- authority  
- client IP  
- bytes sent/received  
- upstream host  
- upstream cluster  
- upstream service time  
- response code  
- flags  

#### Health Check Logs
Write to:
```
/var/log/envoy/healthcheck.log
```

Include:
- SNI used  
- Host used  
- TLS result  
- HTTP result  
- state changes (HEALTHY/UNHEALTHY)  

---

# 🧩 9. Admin Interface Requirements
Admin should run on:

```
0.0.0.0:9000
```

---

# 🧩 10. Envoy Version Requirements

- choose compatible Envoy version (recommended: **>= 1.20.x**)  
- ensure all mTLS/SNI/Health/Balancing features are supported  
- validate with:
```
envoy --mode validate -c /etc/envoy/envoy.yaml
```

---

# 🧩 11. Deliverables

### Must provide:
- fully working `envoy.yaml`
- strict mTLS frontend
- mTLS upstream for 3 nodes
- per-node SNI + Host
- round-robin balancing
- retries + health checks + circuit breakers
- structured logs
- no deprecated fields
- no validation errors
- optional tuning suggestions  

---

# 🧩 12. Acceptance Criteria
- Config loads with zero warnings/errors  
- All nodes pass health checks  
- Even load balancing  
- Instant failover  
- No 503 while ≥1 node alive  
- Correct SNI & Host applied  
- Full mTLS in both directions  
- Logs contain all mandatory fields  
