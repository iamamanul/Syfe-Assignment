# WordPress Kubernetes Monitoring

## Metrics Being Monitored

### 1. WordPress/MySQL Pod Metrics
- CPU Usage: `rate(container_cpu_usage_seconds_total{container="wordpress"}[5m])`
- Memory Usage: `container_memory_working_set_bytes{container="wordpress"}`
- Disk Usage: `kubelet_volume_stats_used_bytes`

### 2. Nginx Metrics (if deployed)
- Requests per second: `rate(nginx_http_requests_total[5m])`
- 5xx Error rate: `rate(nginx_http_requests_total{status=~"5.."}[5m])`
- Response time: `nginx_http_request_duration_seconds`

### 3. Cluster Metrics
- Node CPU: `rate(node_cpu_seconds_total[5m])`
- Node Memory: `node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes`
- Pod count: `count(kube_pod_info)`

## Alerts Configured

1. **High CPU Usage**
   - Alert when: `container_cpu_usage_seconds_total > 0.8 for 5m`
   - Severity: Warning

2. **High Memory Usage**
   - Alert when: `container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.8`
   - Severity: Warning

3. **Pod CrashLoopBackOff**
   - Alert when: `kube_pod_container_status_restarts_total > 3`
   - Severity: Critical

4. **Persistent Volume Full**
   - Alert when: `kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.85`
   - Severity: Warning
