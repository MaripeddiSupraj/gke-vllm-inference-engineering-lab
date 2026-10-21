# GKE Standard + NVIDIA T4 infrastructure (UNDEPLOYED)

## Safety gates

The Terraform configuration intentionally fails its paid-cluster precondition unless `acknowledge_paid_infrastructure=true`. The GPU pool defaults to **zero nodes** and additionally requires `acknowledge_gpu_cost=true` to enable one GPU. **A GKE cluster with CPU node(s) still costs money.** These variables prevent accidental execution, but are not a security boundary or financial cap.

Before deployment:
- Confirm **global GPU quota >= 1** (currently pending Google support approval).
- Confirm regional T4 quota, VM CPU quota and zone capacity.
- Review GKE Standard cluster fees, e2 CPU pool, n1-standard-4 + T4, disks, networking and logging costs.
- Confirm budget is scoped to project and tracks gross usage before credits.
- Set up and test emergency controls and independently scheduled cleanup.
- Review service account/IAM and enable required APIs separately. The lab does not auto-enable APIs.
- Use the intended project only. Do not expose inference services publicly.

## Offline checks (no GCP changes)

```bash
cd infra/terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```

The repository deliberately does **not** have automatic Terraform apply in CI.

## Paid deployment (LATER — only after explicit authorization)

```bash
# Ensure gcloud is authenticated and project ID is correct.
cp terraform.tfvars.example terraform.tfvars
# Edit project_id and approved values in ignored terraform.tfvars
terraform init
terraform plan -out=lab.tfplan
# Review full plan and pricing before explicitly running:
# terraform apply lab.tfplan
```

**Important:** Setting GPU count 0 does not make a created cluster free. The cluster, CPU pool and networking can still bill. The first paid apply must be deliberately time-boxed.

## Teardown

```bash
terraform destroy
gcloud container clusters list --project YOUR_PROJECT_ID
gcloud compute instances list --project YOUR_PROJECT_ID
gcloud compute disks list --project YOUR_PROJECT_ID
gcloud compute addresses list --project YOUR_PROJECT_ID
gcloud compute forwarding-rules list --project YOUR_PROJECT_ID
```

Verify leftovers, including any resources created outside Terraform, and check billing after reporting delay. If Terraform state is lost, do not assume the infrastructure is gone.
