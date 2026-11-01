# Monitoring

| File | Purpose |
|---|---|
| `prometheus.yml` | Scrape jobs: Flask (3 targets), Node Exporter, cAdvisor, kube-state-metrics, Prometheus |
| `alert_rules.yml` | 6 alert rules: host health, CPU, memory, disk, Flask instance down, Kubernetes replica mismatch |
| `grafana-application.json` | Application dashboard |
| `grafana-containers.json` | Container monitoring dashboard |
| `grafana-kubernetes.json` | Kubernetes monitoring dashboard |
| `grafana-linux.json` | Linux infrastructure dashboard |

## Using these files

- Copy `prometheus.yml` and `alert_rules.yml` to `/etc/prometheus/`, validate with `promtool check config /etc/prometheus/prometheus.yml`, then restart Prometheus.
- Import each dashboard in Grafana: Dashboards, New, Import, upload the JSON, and select your Prometheus data source.
- The `kube-state-metrics` job expects a port-forward on `localhost:8081` while Minikube is running.

Alert rules are verified to fire in Prometheus. Notification delivery (Alertmanager) is not configured.
