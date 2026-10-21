# Preflight checklist — before the paid GPU session

## Local workstation

- Git, Terraform, Google Cloud CLI (`gcloud`), `kubectl`, Helm (optional), Python 3.12+
- A readable GCP project with appropriate permissions. Avoid broad permanent privileges or long-lived service-account keys.
- GitHub access for keeping the lab documentation and test evidence up to date.

## Cloud prerequisites

1. Use a separate **lab GCP project** linked to an eligible billing account.
2. Check required APIs and GPU quota for the selected region/zone (initial candidate: NVIDIA T4).
3. Check support for the chosen GKE mode, zone, GPU machine combination and GKE version.
4. Compute the **whole-hourly-system price**, not just the GPU SKU: GPU + VM + disks + cluster management + network + potential egress.
5. Confirm any limits/trial restrictions. An ordinary non-billable Google Cloud Free Trial does not provide straightforward GPU creation.
6. Understand that **GKE Standard node pools** and **GKE Autopilot GPU pod provisioning** are not interchangeable workflows.

## Planned initial lab decisions

- Start with a **GKE Standard zonal cluster** for node-pool learning.
- Target **one GPU node**, with one T4 and one vLLM serving replica.
- Use a tiny model that is verified compatible with the pinned version of vLLM and T4.
- Keep the vLLM Service **internal**. Start FastAPI locally; only later deploy a small CPU pod.
- Separate infrastructure lifecycle (`terraform`) from model-serving rollout (`kubectl` / Helm).
- Store verified commands and actual observed outputs in docs, never invent successful runs.

## When billing is ready

Record the following **privately** before starting (do not commit sensitive IDs):

```text
Account state: active paid billing or eligible credit account?
Region / zone:
T4 (or alternate) quota:
Machine type availability:
Estimated total cost per hour:
Maximum planned wall-clock runtime:
Notification/reminder in place:
Model + serving container pinned:
Teardown dry-run reviewed:
```

## Reference material

- [GKE GPU documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus)
- [GKE Autopilot GPUs](https://cloud.google.com/kubernetes-engine/docs/how-to/autopilot-gpus)
- [GKE pricing](https://cloud.google.com/kubernetes-engine/pricing)
- [Google Cloud pricing calculator](https://cloud.google.com/products/calculator)
- [vLLM documentation](https://docs.vllm.ai/)
