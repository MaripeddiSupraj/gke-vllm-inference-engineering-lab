#!/usr/bin/env bash
# Read-only GCP checks. Does NOT create resources or modify quotas.
set -euo pipefail
PROJECT_ID="${1:?Usage: bash scripts/check-cloud-readiness.sh PROJECT_ID}"
REGION="${2:-us-central1}"
ZONE="${3:-us-central1-a}"
echo "Project: ${PROJECT_ID} | Region: ${REGION} | Zone: ${ZONE}"
echo "Billing enabled (does not prove a paid-account status):"
gcloud billing projects describe "${PROJECT_ID}" --format="yaml(billingEnabled)"
echo "Compute Engine API state:"
gcloud services list --project "${PROJECT_ID}" --enabled --filter="config.name=compute.googleapis.com" --format="table(config.name)"
echo "Regional GPU quotas (read-only):"
gcloud compute regions describe "${REGION}" --project "${PROJECT_ID}" --format="json(quotas)"
echo "Global GPU quota (read-only):"
gcloud compute project-info describe --project "${PROJECT_ID}" --format="json(quotas)"
echo "Accelerator types advertised in selected zone (NOT stock availability):"
gcloud compute accelerator-types list --project "${PROJECT_ID}" --filter="zone:('${ZONE}') AND name:nvidia-tesla-t4"
echo "No resources were created. Confirm quotas, pricing, and budget shutdown separately."
