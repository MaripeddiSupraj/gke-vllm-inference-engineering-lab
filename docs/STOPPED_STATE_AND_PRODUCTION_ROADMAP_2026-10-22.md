# STOPPED STATE — 2026-10-22 — GCP GPU / GKE LLM inference lab

**Status: PAUSED BY OPERATOR, END OF PHASE 1.** This file is the durable handoff and scope baseline for the next session and future technical blog series. **Updated after operator CLI receipts: GKE cluster and L4 GPU VM deletion verified by empty project-wide listings; one Artifact Registry repository remains.** See teardown verification section below. PR #11 has since been merged into main; production readiness is not claimed.

## Repository and change control
- Repo: `MaripeddiSupraj/gke-vllm-inference-engineering-lab`; feature branch `feat/gke-l4-inference-manifests-20261022`; **PR #11 merged into main** by operator authorization, squash commit `f4e0a4fca88e0ecd4b7ae1c44551018640d47b8f`.
- Operator uses local Mac repository `~/gke-vllm-inference-engineering-lab`.
- Prior evidence: `docs/LIVE_LAB_2026-10-22.md`, `docs/GPU_BENCHMARK_2026-10-22.md`, `docs/L4_CONCURRENCY_SCALING_2026-10-22.md`; inspect actual source manifests and Terraform rather than assuming their latest state.
- Preserve Terraform state, variables, image tags/digests, benchmark scripts, service configuration, screenshots and proof logs before teardown. Do not commit secrets, API keys, credentials, Terraform state, model tokens, or private IP access tokens.

## Verified Phase 1 (as observed 2026-10-22)
- Project `gke-vllm-learning-lab`, zone `asia-southeast1-a`.
- GPU VM `l4-capacity-test`, `g2-standard-4`, 4 vCPU, 16 GiB RAM, 1 NVIDIA L4 (23034 MiB visible VRAM), Debian 12; NVIDIA driver 615.71.10; CUDA UMD 13.4.
- vLLM Docker `vllm/vllm-openai:v0.11.0`, container `vllm-qwen`, model `Qwen/Qwen2.5-0.5B-Instruct`; loopback `127.0.0.1:8000`; `/health` HTTP 200; OpenAI-compatible chat completions work.
- GKE Standard cluster `gke-vllm-lab` has one **CPU-only** pool `cpu-system` (`e2-standard-2`, Kubernetes `1.36.4-gke.1495002`); namespace `inference-lab` contained healthy FastAPI and Nginx Pods. **No GPU node pool was deployed; GPU is on a separate Compute Engine VM.**
- FastAPI image `asia-southeast1-docker.pkg.dev/gke-vllm-learning-lab/ai-inference/fastapi-inference:lab-amd64-v1`; `/api/v1/chat` uses `X-API-Key` and K8s Secret. Private peering GKE VPC ↔ GPU VM VPC and a **temporary unauthenticated HTTP private proxy** provided lab connectivity; not production-safe. No public GPU port was intentionally opened.
- GPU scheduling negative test: requesting `nvidia.com/gpu: 1` on CPU-only cluster yielded `Insufficient nvidia.com/gpu`, `Preemption is not helpful`, `NotTriggerScaleUp`. Test Pod should be removed during teardown.
- Regional quotas observed: `NVIDIA_L4_GPUS` limit 1/used 1; `PREEMPTIBLE_NVIDIA_L4_GPUS` limit 1/used 0; `COMMITTED_NVIDIA_L4_GPUS` limit 1/used 0. **Committed quota is not proof of an active commitment or free GPU.** Additional standard L4 cannot be assumed available; Spot quota does not guarantee Spot capacity.
- Monitoring containers `observability-prometheus-1`, `observability-grafana-1`, `observability-dcgm-1` were running; Prometheus targets `vllm` and `nvidia-dcgm` both UP. Grafana UI/dashboards/alerts **not verified**. DCGM sampled GPU util 0%, temperature 77°C, power 41.02W, frame-buffer used 16662 MiB. vLLM sampled 0 running, 0 waiting, KV cache usage 0; allocated VRAM is not the same as KV cache occupancy.
- Concurrency scaling, identical short prompts, temp 0, max_tokens 400: 8 → 1215.7 output tok/s (2.63s batch, 2.62s avg latency); 16 → 2170.4 (2.95s, 2.91s); 32 → 3514.3 (3.64s, 3.52s); 48 → 4315.4 (4.45s, 4.26s); 64 → 4898.4 (5.23s, 4.96s). These are short bursts, not sustained production SLOs; peak saturation not demonstrated; identical prefixes may influence caching.
- Additional 32-request burst: 32/32 succeeded, 14814 output tokens in 4.42s (~3348 output tok/s as measured); scheduler sampled 32 running/0 waiting. Different long-prompt 48-request burst: 48/48 succeeded, 15.29s, 66858 input tokens, 36266 output tokens (~2371.9 output tok/s); transient scheduler waiting observed (27 running/7 waiting); KV usage peak ~3.72%. Distinguish prompt workload differences.
- Concepts covered: prefill vs decode, continuous batching, GPU compute vs VRAM allocation, vLLM scheduler queues, TTFT histograms, GKE GPU scheduling, taints/tolerations, GPU quotas, DCGM/Prometheus scrape targets.
- **Not completed:** GPU-backed GKE serving, gateway, Kueue, autoscaling, production authentication/security, dashboard/alerts, cloud monitoring integration, end-to-end SLO testing, SGLang comparison.

## Explicit end-of-day teardown (requested; operator execution pending)
**Before deletion**: confirm Terraform state location and backups; record `terraform state list` and `terraform plan -destroy` in the original workspace; preserve any needed Terraform-managed resources and artifacts. Avoid deleting shared VPCs, Artifact Registry, DNS, billing project, or unrelated assets accidentally. Existing peering and networking may be Terraform-managed; plan the dependency order. Check whether the VM, disks, IPs, VPC peering, GKE cluster, or other resources are tracked by Terraform before mixing manual deletes and `terraform destroy`. Never run `terraform destroy` blindly.
1. Record live inventory and billing-relevant resources: `gcloud container clusters list --project=gke-vllm-learning-lab`, `gcloud compute instances list --project=gke-vllm-learning-lab`, `gcloud compute disks list --project=gke-vllm-learning-lab`, `gcloud compute addresses list --project=gke-vllm-learning-lab`, `gcloud compute forwarding-rules list --project=gke-vllm-learning-lab`.
2. Remove the disposable GKE cluster `gke-vllm-lab` in `asia-southeast1-a` and separate GPU VM `l4-capacity-test` in the same zone, using the chosen IaC-controlled teardown path or explicitly approved gcloud deletes, not both indiscriminately. VM deletion can destroy boot-disk data; ensure no unique benchmark/scripts/config live only on VM.
3. Audit residual persistent disks, static IPs, load balancers, snapshots, Artifact Registry storage, Cloud NAT, logging/metrics charges, networking, and service-specific resources. Retain repo and IaC state securely for recreation.
4. Verify cluster/VM absent in GCP and document actual command output, timestamps, residual assets, and costs. **Only then change status to TEARDOWN VERIFIED.**
5. No automatic recreation tomorrow; quota, capacity, driver support and projected cost must be checked first.


## Operator-reported teardown verification — 2026-10-22, approximately 21:43 IST

The operator supplied the following **read-only GCP CLI outputs** for project `gke-vllm-learning-lab` after requesting teardown. These are operator-provided receipts; no GCP command was run directly by this GitHub update.

| Resource check | Observed result |
| --- | --- |
| `gcloud container clusters list` | `Listed 0 items.` |
| `gcloud compute instances list` | `Listed 0 items.` — **the former NVIDIA L4 VM is absent from the project-wide VM inventory; no active Compute Engine GPU VM remains listed** |
| `gcloud compute disks list` | `Listed 0 items.` |
| `gcloud compute addresses list` | `Listed 0 items.` |
| `gcloud compute forwarding-rules list` | `Listed 0 items.` |
| `gcloud compute routers list` | `Listed 0 items.` |
| `gcloud compute snapshots list` | `Listed 0 items.` |
| `gcloud storage buckets list` | `Listed 0 items.` |
| `gcloud artifacts repositories list` | **One retained repository**: `ai-inference` (Docker, `asia-southeast1`, 98.002 MB at check time) |

**Updated shutdown assessment:** GKE cluster, GPU VM, disks, addresses, forwarding rules, routers, snapshots and GCS buckets are absent in the inspected project listings. **GPU VM compute teardown is verified from the project-wide VM listing.** The Artifact Registry repository remains intentionally retained for possible next-day reuse; small storage charges may continue. This is not a claim of zero project spend or exhaustive resource inventory. Billing reports can lag; inspect Billing Reports, Terraform state drift, service-specific resources and remaining IAM/network objects before asserting total cleanup. The explicit named-instance `describe` command was not supplied, but the project-wide instance list is empty.

**Tomorrow:** Confirm the retained image tags, Terraform state reconciliation, standard L4 GPU quota and spend approval before provisioning GKE GPU node pool. Do not automatically recreate resources.

## Full production architecture and tracked pending work

See **[Production target Mermaid architecture + complete pending/acceptance register](PRODUCTION_TARGET_ARCHITECTURE_AND_PENDING_REGISTER.md)**. This is the primary architecture and status index for future sessions, including authentication, rate limiting, gateways, Kueue, llm-d, GPU scheduling, scaling, observability, security, SRE, cost and the later SGLang parity lab.

## Next session — Phase 2 priority: GKE GPU-first deployment
1. Verify project/billing/quota (standard L4 limit 1), zone GPU capacity, GKE version compatibility, node image and driver support; establish budget/alerts. Existing GPU VM must be gone or quota raised before attempting a new standard L4.
2. Terraform provision GKE Standard and **one GPU node pool** (e.g. `g2-standard-4` L4), plus small CPU system pool; document GPU node taints, tolerations, node affinity, GPU resource requests/limits, service accounts, image pull permissions, Pod Security, GPU driver/device plugin, optional GPU sharing, maintenance and upgrade policy.
3. Run `kubectl get nodes`, inspect allocatable `nvidia.com/gpu`, driver/device-plugin readiness, and scheduling events; explain node readiness vs GPU readiness vs model readiness.
4. Deploy vLLM as an actual **GPU Pod inside GKE**, with explicit version-pinned image, model artifact strategy (GCS/HF), secrets, probes (startup/readiness/liveness), graceful shutdown, termination/draining, resource limits, priority, storage and cold-start measurement.
5. Connect FastAPI through internal K8s Service; validate authenticated end-to-end requests, networking and service discovery; remove temporary VM proxy.
6. Baseline load tests with comparable prompts, request rates, concurrency, TTFT, TPOT/inter-token latency, p50/p95/p99 latency, output throughput, errors, KV cache, GPU metrics, cost/token. Record warm vs cold start, prompt-cache effects and tail latency. Do not claim production readiness from a single burst.

## Complete production inference platform syllabus and blog backlog
Suggested **10-part blog series**, each article must include: prerequisites, architecture Mermaid diagram, GCP services and roles, real commands/manifests, observed output vs expected output clearly distinguished, failure modes, security/cost considerations, validation and cleanup. Never invent benchmark results or imply an unrun lab was tested.

1. **Foundation and reference architecture** — GCP IAM, project, billing, regions/zones/quotas, VPC/subnets/firewalls/private clusters, Artifact Registry, Terraform, CPU/GPU architecture, tenancy and threat model; baseline architecture and decisions.
2. **GPU infrastructure on GKE** — G2/L4 sizing, GPU drivers, NVIDIA device plugin, CUDA/container runtime, allocatable GPU, taints/tolerations, GPU sharing (time-slicing/MPS and limitations), MIG availability by GPU type, node pools, Spot/reservations, GPU cold starts, cluster upgrades.
3. **Model artifacts and serving engines** — GCS/HF model distribution, checksum/provenance, pinned revisions, licenses, container security, model download/caching, vLLM internals (prefill, decode, continuous batching, paged attention, KV/prefix cache), OpenAI API compatibility, probes and warm-up.
4. **Inference networking and intelligent gateways** — Kubernetes Gateway API, GatewayClass/Gateway/HTTPRoute, GKE Inference Gateway and supported version/features, InferencePool and Endpoint Picker, llm-d routing, prefix-cache-aware and load-aware routing, model/LoRA-aware routing, service discovery, L7/L4 LB, TLS/mTLS, internal vs external ingress, traffic splitting, retries/timeouts, connection handling, streaming/SSE.
5. **Workload admission and GPU capacity** — Kueue LocalQueue/ClusterQueue/ResourceFlavor, quotas, fair sharing, priority, preemption, batch inference vs online serving, Kubernetes scheduler vs Kueue vs gateway responsibilities; HPA/KEDA/custom metrics, GKE Cluster Autoscaler/node auto-provisioning, scaling from zero, node provisioning, model loading, admission control, capacity planning, queue backpressure.
6. **Advanced distributed inference** — llm-d architecture, prefill/decode disaggregation, tensor/pipeline/data parallelism, multi-GPU and multi-node networking, NCCL/RDMA considerations, routing, SGLang, Triton, TensorRT-LLM, Ray Serve, KServe, trade-offs and hardware feasibility; avoid implying L4 single-GPU can demonstrate multi-GPU features.
7. **Identity, security and governance** — client auth (OIDC/JWT/API keys), gateway authentication and authorization, tenant isolation, quotas/rate limiting, abuse protection, IAM/Workload Identity Federation for GKE, Secret Manager/KMS, private networking, VPC Service Controls where appropriate, TLS/mTLS, image/model supply chain scanning/signing, sandboxing, Pod Security, RBAC, NetworkPolicy, prompt-injection/data exfiltration controls, sensitive data handling, audit logs, retention, compliance, model license/policy.
8. **Production observability and SRE** — DCGM exporter, vLLM metrics, Prometheus/Grafana, Google Cloud Managed Service for Prometheus/Cloud Monitoring/Logging/Trace, OpenTelemetry, correlation IDs, TTFT/TPOT, p50/p95/p99, tokens/sec, queue, KV-cache utilization, GPU power/temp/memory, errors, request cancellation, alerting, dashboards, SLIs/SLOs/error budgets, on-call runbooks, failure injection.
9. **Performance, resilience and FinOps** — realistic load profiles, benchmark reproducibility, saturation and tail latency, dynamic batching, quantization/LoRA/prefix caching, capacity/replica sizing, per-tenant fairness, cost per million tokens, Spot interruption, scale-to-zero, graceful draining, model rollout/canary/shadow, failover, DR, multi-region, quotas, GPU utilization economics, rollback and cleanup.
10. **Managed services and reproducible comparison** — GKE vs Compute Engine vs Vertex AI endpoints vs Cloud Run GPU; cost/latency/security/operability decision matrix; reproduce matched vLLM and **SGLang** labs on equivalent GKE GPU hardware with same model, input distributions, token budgets, measurement methodology, config and explicit caveats. SGLang is a separate later phase, not yet implemented.

## Additional acceptance checklist (must not be omitted in production guide)
- API contract: request schema, model IDs, max context/output, streaming, errors, timeouts, idempotency where relevant, versioning, client SDK.
- AuthN/AuthZ: workload-to-workload identities, end-user tokens, scoped model access, per-tenant quotas, API key rotation, gateway enforcement.
- Traffic controls: per-user/tenant RPM and TPM, max in-flight requests, admission/backpressure, overload 429/503, fairness, circuit breakers, retries with jitter and retry budgets, cancellation, streaming disconnect handling.
- Security: no unauthenticated public inference, no broad firewall rules, encrypted transport, data minimization, logging redaction, secrets rotation, supply-chain integrity, isolation, least privilege, model provenance.
- Operations: rollout/rollback, model versioning, readiness, startup, draining, node disruption, Spot interruption, maintenance windows, capacity buffer, restore, incident runbooks, auditability.
- Quality: model correctness, safety, deterministic regression fixtures, performance tests, hallucination and prompt-injection evaluation appropriate to application, data leakage checks.
- Observability: gateway and engine traces, per-tenant usage, token accounting, latency distributions, GPU metrics, alert thresholds, SLO burn rates, ingestion costs.
- Reproducibility: pinned versions, exact command receipts, hardware/software matrix, diagrams, costs at time of test, and teardown receipts.

## Next-day explicit gates
- **Gate A**: verify teardown receipt and preserved IaC state.
- **Gate B**: confirm L4 quota and spend approval for GKE GPU node pool.
- **Gate C**: GKE GPU node advertises `nvidia.com/gpu`.
- **Gate D**: vLLM Pod healthy and FastAPI authenticated inference passes.
- **Gate E**: production controls and measurement progressively implemented; no premature production-ready label.
- **Gate F**: SGLang comparison only after vLLM baseline is repeatable.

**Final state after operator receipts:** Phase 1 paused; GKE and GPU VM compute resources absent; retained Artifact Registry repository (98.002 MB); complete zero-cost cleanup not asserted. This is intentionally strict.
