# Private VM inference monitoring

Runs Prometheus, Grafana, and NVIDIA DCGM Exporter on the **existing** L4 VM. No GKE resources are created.

## Preflight
- VM must already have NVIDIA drivers, NVIDIA Container Toolkit, Docker, and Docker Compose plugin.
- vLLM must be listening on VM loopback port 8000.
- Check `sudo docker compose version` and `sudo docker info | grep -i runtime`.
- Confirm ports 3000, 9090, 9400 are unused.
- Review image tags and security privileges before starting. DCGM requires access to NVIDIA devices and SYS_ADMIN.
- Docker host networking requires Linux. Do not run this Compose stack on macOS.
- No public firewall ingress is needed; all HTTP endpoints bind to VM loopback.

## Start on the VM
```bash
cd observability/vm
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(openssl rand -hex 24)" > .env
chmod 600 .env
sudo docker compose config --quiet
sudo docker compose up -d
sudo docker compose ps
curl -fsS http://127.0.0.1:9090/-/healthy
curl -fsS http://127.0.0.1:9400/metrics | grep -m 1 DCGM_FI_DEV_GPU_UTIL
```
The DCGM image/runtime and listener settings may require adjustment for your driver/exporter version; check container logs if exporter is unhealthy.

## Open Grafana from your Mac
```bash
gcloud compute ssh l4-capacity-test --project=gke-vllm-learning-lab --zone=asia-southeast1-a -- -N -L 3000:127.0.0.1:3000
```
Browse http://127.0.0.1:3000. Username `admin`; password is in VM-local `.env`.

PromQL examples:
- `vllm:num_requests_running`
- `vllm:kv_cache_usage_perc`
- `rate(vllm:generation_tokens_total[5m])`
- `DCGM_FI_DEV_GPU_UTIL`
- `DCGM_FI_DEV_FB_USED`

## Cleanup
```bash
cd observability/vm
sudo docker compose down
```
To delete stored monitoring history too: `sudo docker compose down -v`.

**Costs:** Monitoring containers consume resources on the existing billable VM. Stop the VM when finished, only with the owner's explicit approval.
