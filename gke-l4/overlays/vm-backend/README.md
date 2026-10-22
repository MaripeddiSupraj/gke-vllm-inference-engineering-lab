# GKE CPU FastAPI → existing L4 VM (lab-only overlay)

This overlay reproduces the **observed** FastAPI image and `VLLM_URL` from the 2026-10-22 live lab without modifying the generic Kubernetes base. The model is served on the existing standalone L4 VM, **not** on a Kubernetes GPU node.

## Prerequisites

- Current kubeconfig points to the intended `gke-vllm-lab` cluster in project `gke-vllm-learning-lab`.
- Namespace `inference-lab` and Secret `inference-api` already exist; do not commit or print secret values.
- Artifact Registry IAM permits the GKE node service account to pull the image.
- Private VPC peering and restricted ingress from GKE are active; the VM-private proxy is listening only on `10.148.0.2:8000`.
- This overlay's image tag is the observed AMD64 build, not an immutable digest. Pin the digest in a future hardened revision.
- This is an **unencrypted, unauthenticated backend hop**; do not use outside a tightly restricted lab.

## Preview before applying

```bash
kubectl config current-context
kubectl kustomize gke-l4/overlays/vm-backend
kubectl diff -k gke-l4/overlays/vm-backend
```

Inspect the diff: it should only update the FastAPI Deployment and Service in `inference-lab`. **Do not apply** if it shows unexpected changes. If acceptable:

```bash
kubectl apply -k gke-l4/overlays/vm-backend
kubectl -n inference-lab rollout status deployment/fastapi --timeout=180s
kubectl -n inference-lab get pods,svc -o wide
```

Note: `kubectl diff` may return exit code 1 when differences exist; that is expected, not an apply failure.

## Why Kustomize?

The base manifest defines **what** FastAPI needs: security context, probes, resources, Secret reference and a Service. The overlay defines **where** this particular lab runs: the registry image tag and temporary VM endpoint. Kubernetes injects `VLLM_URL` into the Pod environment; Python reads it with `os.getenv` and uses it for its `httpx` POST. Updating the Deployment Pod template creates a rolling replacement of Pods.

The overlay intentionally does **not** deploy `10-vllm.yaml`: the current GKE cluster has no GPU node pool.

## Validation

Use an existing local port-forward, or start one in a separate terminal:

```bash
kubectl -n inference-lab port-forward svc/fastapi 8080:8080
```

In another terminal, verify `GET http://localhost:8080/health`. For an authenticated generation request, retrieve the existing key locally from the Kubernetes Secret and send it as `X-API-Key`; never put it in source control or shell history.

## Known gaps

The current lab was configured with imperative commands before this overlay existed; **overlay application has not yet been independently validated**. Private IP and image tag are lab-specific; IAM/peering/firewall/proxy remain external changes and must be reconciled for full reproducibility. Production requires authenticated encrypted backend traffic, digest pinning, operational monitoring, and a defined deployment/rollback pipeline.
