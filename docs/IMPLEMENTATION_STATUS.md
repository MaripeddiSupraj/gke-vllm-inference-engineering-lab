# Implementation status

As of initial implementation commit:

- **Committed as templates**: Terraform for zonal Standard GKE, one CPU node pool, zero GPU nodes by default, one-T4 optional node pool, namespace/Deployment/ClusterIP for vLLM, FastAPI HTTP client, preflight and diagnostic scripts.
- **Not yet validated in this session**: Terraform provider schema validation against a downloaded provider, Kubernetes server-side validation, vLLM image/model/T4 compatibility, Python dependency installation, end-to-end tests.
- **Not provisioned**: GKE cluster, GPU VM, vLLM pod, model download.
- **Blocking prerequisites**: global GPU quota increase 0 → 1 is pending Google support; budget alerts do not hard-cap spending; emergency shutdown and security preflight remain incomplete.
- **Operator approval required**: any `terraform apply`, GPU node count change, cluster deployment, or billable experiment.

## Planned verification improvements

- Add mock-based FastAPI unit tests and Python linting.
- Add CI that runs offline checks with no cloud credentials.
- Validate provider version compatibility and Kubernetes manifests locally.
- Pin vLLM image by digest and model revision after compatibility review.
- Add safe teardown and independent resource inventory verification.
