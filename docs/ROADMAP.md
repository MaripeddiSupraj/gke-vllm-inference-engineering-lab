# Task-by-task learning roadmap

**State definitions:** `planned` = documented idea; `implemented` = committed files; `offline-validated` = tests without GCP; `GPU-verified` = ran on a real cluster with supporting evidence.

## Phase 0 — no-cost preparation

- [ ] **P0-01** Confirm Cloud Billing mode, dedicated project, available T4 quota by region and estimate total hourly resource cost.
- [ ] **P0-02** Terraform structure, pinned providers, zonal Standard GKE, networking and one T4 node pool; outputs and explicit delete commands.
- [ ] **P0-03** GPU and Kubernetes diagnostic manifests + script, instructions for interpreting driver/CUDA/device-plugin errors.
- [ ] **P0-04** vLLM single-replica Deployment/Service with pinned container version, one GPU request, image/model compatibility, model access, readiness and failure logs.
- [ ] **P0-05** FastAPI test client, local port-forward workflow, optional CPU deployment, integration and streaming tests, timeout controls.
- [ ] **P0-06** Offline validation (formatters, Terraform validate, Python tests), no cloud API changes on PR.

**Entry gate to paid lab:** working teardown, budget alerts, quota, GPU zone selection, pinned image/model, all possible offline checks completed. Neither Terraform plan nor an estimate guarantees available capacity.

## Paid GPU session — one T4, resource-time-boxed

| ID | Practical experiment | Evidence / acceptance | Cost impact |
| --- | --- | --- | --- |
| A01 | Provision one zonal Standard GKE and GPU node pool | Terraform apply receipt, node names, GPU allocatable | Paid |
| A02 | Inspect host and GPU integration | Node info, GPU plugin pods, `nvidia-smi`, driver details | Same GPU |
| A03 | Pod requesting `nvidia.com/gpu: 1` | Pod scheduled to GPU node; `kubectl describe` events | Same GPU |
| B01 | Start vLLM / load tiny model | Healthy readiness, model named by `/v1/models`, logs | Same GPU |
| B02 | Inspect model and cache memory | `nvidia-smi` before/after model startup; label observations | Same GPU |
| C01 | FastAPI from Mac uses port-forward | One successful `/chat` answer; actual HTTP request/response | Same GPU |
| C02 | FastAPI CPU pod calls ClusterIP | Service DNS and request result; no public GPU endpoint | Possible extra CPU |
| C03 | Stream generated output | Streaming response and disconnect behavior | Same GPU |
| D01 | Compare short versus long prompts | Token counts, TTFT and latency measurements | Same GPU |
| D02 | Compare short versus long outputs | Output token counts, TPOT and latency | Same GPU |
| D03 | Concurrent requests / continuous batching | Queue/running-request metrics and timings | Same GPU |
| D04 | Prefix cache A/B with repeated prefix | Observed prefix hits where available; don't guess | Same GPU |
| D05 | KV cache and PagedAttention | Metrics plus source/config walkthrough; limit claims to evidence | Same GPU |
| E01 | Failed request and server restart | Error handling, restart/model reload time | Same GPU |
| E02 | Inspect CPU, GPU, vLLM metrics | Annotated logs and figures | Same GPU |
| E03 | Controlled 1 → 0 → 1 scale | Termination and model reinitialization; no extra GPU | Same GPU |
| G01 | Destroy resources and verify no chargeable leftovers | Terraform output, residual resource checks, billing follow-up | Stop charges |

**Prioritization if running out of time:** A01 → A02 → B01 → C01 → C03 → D01 → D03 → G01. G01 is mandatory.

## Deferred/optional sessions requiring more time, quota or budget

- GKE Autopilot GPU provisioning versus Standard node pools.
- Two independent 1-GPU vLLM replicas, load distribution, scale-out, cold starts.
- Tensor parallelism on 2+ compatible GPUs; GPU-to-GPU bandwidth/NVLink concepts.
- Advanced KServe / autoscaling, HPA/KEDA and inference-aware routing.
- Production auth, workload identity, NetworkPolicy, private storage, observability and SLOs.
- GPU profiling and CUDA kernels on a suitable compatible GPU with appropriate tools.

## Reproducible evidence format

For every lab, capture:

```text
Experiment:
Date/UTC and GCP region/zone:
Terraform revision / Git commit:
GKE version, node type, GPU model:
vLLM image digest/version and model revision:
Commands executed:
Expected behavior:
Observed output (redacted):
Success / failure / not run:
TTFT / latency / GPU memory (when measured):
Approximate duration and actual/estimated billable cost:
Cleanup verification:
Lessons learned:
```

Never claim `GPU-verified` unless a real GPU run has produced suitable evidence.
