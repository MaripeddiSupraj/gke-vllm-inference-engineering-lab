# GKE L4 inference deployment — CPU GKE to external L4 VM validated

This directory contains an offline-prepared example for **GKE Standard**: FastAPI (CPU) -> internal vLLM Service -> vLLM (one NVIDIA L4 GPU) -> Qwen2.5-0.5B-Instruct. The GPU-on-GKE target is not yet validated; CPU FastAPI on GKE → external L4 VM inference was verified on 2026-10-22. See [live lab](../docs/LIVE_LAB_2026-10-22.md) and [VM backend overlay](overlays/vm-backend/README.md).

## What is already verified
On the standalone Compute Engine L4 VM, vLLM v0.11.0 served Qwen2.5-0.5B-Instruct, FastAPI forwarded chat requests, API-key authentication rejected missing keys and accepted correct keys, and a Mac reached FastAPI through an SSH tunnel. This does **not** prove GKE deployment works.

## Before spending money
- Historical preflight: GKE cluster list was empty. A billable CPU-only GKE cluster was subsequently created on 2026-10-22.
- Singapore regional L4 GPU quota was 1 used of 1 (standalone VM). **Quota and zonal stock are different constraints**. Do not provision GKE GPU resources while the standalone VM uses the only quota without a conscious migration plan.
- Investigate the previously observed ₹43.3k gross billing figure and confirm credits and budget. Budget alerts are not hard spending caps.
- No GKE cluster, public LoadBalancer, Ingress, or Gateway is created by these files. All Services are internal ClusterIP.
- This example's vLLM Hugging Face cache uses ephemeral emptyDir; model downloads recur after pod recreation. Check node disk space and image pull behavior.
- GKE GPU driver/device plugin availability must be verified on the selected cluster/node pool; these files do not install them.

## Build the FastAPI image (from repo root, once Artifact Registry exists)
```bash
gcloud builds submit gke-l4/app --tag REGION-docker.pkg.dev/PROJECT/REPOSITORY/fastapi-inference:lab-v1
```
For the verified VM-backed lab, use the [Kustomize overlay](overlays/vm-backend/README.md), which sets the AMD64 image and private vLLM endpoint without editing the generic base. IAM access was granted manually.

## Target GPU-on-GKE deployment (ONLY after GPU node and image exist)
```bash
kubectl apply -f gke-l4/k8s/00-namespace.yaml
# Do not commit secrets. This prompts locally, without echoing the key.
read -rs "API_KEY?API key: "; echo
kubectl -n inference-lab create secret generic inference-api --from-literal=api-key="$API_KEY"
unset API_KEY
kubectl apply -f gke-l4/k8s/10-vllm.yaml
kubectl apply -f gke-l4/k8s/20-fastapi.yaml
kubectl -n inference-lab get pods -w
```
The `read` command above is for **zsh** on macOS. For Bash, use `read -rsp "API key: " API_KEY; echo`. The Kubernetes Secret is not encrypted by this manifest; configure GKE secret encryption, RBAC, and secret management appropriately for production.

## Verified CPU-on-GKE / external GPU VM variant

See the [lab-specific overlay](overlays/vm-backend/README.md). Preview with `kubectl kustomize` and `kubectl diff -k` before applying. This overlay is committed but has not yet been independently applied.

## Test privately
```bash
kubectl -n inference-lab port-forward service/fastapi 8080:8080
```
In another Mac terminal:
```bash
read -rs "API_KEY?API key: "; echo
curl -i http://127.0.0.1:8080/api/v1/chat -H 'Content-Type: application/json' -H "X-API-Key: $API_KEY" -d '{"message":"Explain GPU inference in one sentence."}'
unset API_KEY
```
Expected: HTTP 200 if inference is ready, or HTTP 401 for a missing/wrong key.

## Design limitations and follow-ups
- CPU FastAPI and GPU vLLM are separate Deployments. vLLM requests `nvidia.com/gpu: 1`; verify device plugin, GPU driver and scheduling on the real node.
- vLLM has startup/readiness/liveness probes; readiness at `/health` is basic health, not a representative generation test.
- A single GPU pod is not highly available. There is no autoscaling, network policy, ingress, metrics stack, PVC, external gateway, or TLS in this phase.
- The FastAPI image uses pinned Python dependency versions, but the base image, vLLM image and model are not digest/revision pinned. Pin and scan before production.
- For a shared cluster, add default-deny NetworkPolicies and explicit allowed paths, Workload Identity, restricted RBAC, observability, and gateway authentication before exposing any endpoint.
- The CPU-only FastAPI Deployment can schedule onto the GPU node if no separate CPU pool exists. Prefer a separate CPU node pool for isolation.
- GPU VM must not be deleted before confirming backups/documentation; stopping it releases GPU quota but reacquiring zonal capacity is not guaranteed.

## Cleanup
```bash
kubectl delete namespace inference-lab
```
This deletes the namespaced lab workloads but **not** the GKE cluster, GPU node pool, Artifact Registry, or VM. Clean up and verify those separately after experiments.
