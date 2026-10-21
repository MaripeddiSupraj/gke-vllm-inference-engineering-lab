# GCP cost, access and teardown guardrails

## The budget is a target, not a guarantee

The initial ambition is **USD $3–$5 total incremental spend** for a short one-T4 learning session. It is **not** a hard billing limit. GPU allocation, VM vCPUs/RAM, disks, networking, load balancers, regional availability, cluster-management fees and runtime can all affect cost. Always calculate actual prices for the chosen region and machine family before provisioning.

Cloud Billing budget **alerts are not automatic Compute Engine/GKE shutdowns**. Adding a payment method or prepaying a small amount must never be assumed to cap spend.

Before `terraform apply`, verify:
- [ ] Project is dedicated to the lab; Cloud Billing account status is known
- [ ] T4 quota (or chosen GPU) and resource availability are sufficient in desired zone
- [ ] Compute Engine, GKE and other required APIs are available/allowed
- [ ] Current GPU/VM/disk/cluster pricing estimated using official pricing calculator
- [ ] Budget notifications and independent elapsed-time reminder configured
- [ ] Model image/version and manifest constraints prevalidated as far as possible
- [ ] Teardown commands and access confirmed; no live public model endpoint
- [ ] An explicit target end-time for the paid lab is chosen

## No secrets in Git

Never commit `*.tfstate`, `*.tfvars` containing private information, `*.json` service-account keys, access tokens, `.env`, kubeconfig, or account/billing IDs. Use ADC/workload identity appropriately for the scenario, least-privilege roles, and private access where practical.

The tutorial should prefer **ClusterIP + `kubectl port-forward`** over a publicly exposed inference API. Authn/authz, network policies and a secure ingress are separate production exercises.

## Operational plan

1. Prepare scripts and test inputs offline.
2. Confirm actual quota and cost estimate; use the smallest viable resources.
3. Create resources only for the scheduled test window; capture creation time.
4. Run tests in priority order; stop if model startup, access or quota is blocked.
5. **Run `terraform destroy` in the correct workspace/project**; verify the command completed.
6. Query the project for remaining GKE clusters, GPU/Compute Engine VMs, disks, external IP addresses, forwarding rules/load balancers, images and storage buckets.
7. Review billing after usage data arrives; billing reporting is not instantaneous.
8. Redact IPs/account identifiers and secrets from published evidence.

## Teardown verification commands (illustrative; replace PROJECT_ID)

```bash
gcloud config set project PROJECT_ID
gcloud container clusters list --project PROJECT_ID
gcloud compute instances list --project PROJECT_ID
gcloud compute disks list --project PROJECT_ID
gcloud compute addresses list --project PROJECT_ID
gcloud compute forwarding-rules list --project PROJECT_ID
```

Some resources are regional/global or managed outside Terraform, so inspect the full project inventory and Terraform state. Zero listed GPU VMs alone does not prove zero charges.

## Security and publication

- Don't publish personal Cloud Billing screenshots, access tokens, kubeconfig, GCP project secrets, or public IP details.
- Do not configure automatic, unlimited GPU scale-out.
- Set resource quotas/limits carefully; avoid using `latest` as production evidence.
- A failed experiment is useful learning: record it honestly and stop billable infrastructure.
