# Paid deployment gate — STOP until checked

This project now has implementation templates and offline CI. **No cloud resources have been created by this repository.**

## Required before any apply

- [ ] Global GPU quota **actually reports 1** after approval (not just a support acknowledgment)
- [ ] Regional NVIDIA T4 quota reports 1 in us-central1
- [ ] Selected zone supports the T4 and has available capacity at provisioning time
- [ ] GCP project billing active and expected promotional credit expiry reviewed
- [ ] ₹1,000 budget scoped to lab project, includes all services, and tracks gross cost before promotional credits
- [ ] Account MFA and IAM/service-account access reviewed
- [ ] Emergency spending protection/automatic shutdown strategy implemented or residual risk explicitly accepted
- [ ] Exact whole-system hourly cost estimated for GKE Standard + e2-standard-2 CPU node + n1-standard-4/T4 GPU node + disks/networking
- [ ] Terraform offline CI green and provider schema validated
- [ ] vLLM image, model revision, driver compatibility and Kubernetes readiness validated
- [ ] Operator available for entire session; **independent** timer set to end experiment
- [ ] Terraform state storage and teardown permissions reviewed; scripts/verify-cleanup.sh understood
- [ ] User explicitly approves billable `terraform apply`

## Commands after gate clears (do not run yet)

```bash
# READ-ONLY preflight
bash scripts/check-cloud-readiness.sh gke-vllm-learning-lab us-central1 us-central1-a
# PREPARE ONLY, no apply:
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
# Set project_id and carefully review acknowledgments; do not share secrets.
terraform init
terraform plan
# Only then explicitly approve apply.
```

**Do not treat Terraform precondition variables as a real cloud billing cap.** They are operator friction, not protection against account compromise.

**GKE networking note:** A private, isolated VPC without outbound NAT/egress cannot automatically pull container images or download model weights. Current manifests assume ordinary external node egress, which needs to be validated and secured before live tests. Do not enable a public inference load balancer.

**No automatic deploy** is configured in GitHub Actions.
