#!/usr/bin/env bash
# Read-only inventory, NOT proof of zero billable resources.
set -euo pipefail
PROJECT_ID="${1:?Usage: bash scripts/verify-cleanup.sh PROJECT_ID}"
echo "READ-ONLY inventory for project: ${PROJECT_ID}"
gcloud container clusters list --project "${PROJECT_ID}"
gcloud compute instances list --project "${PROJECT_ID}"
gcloud compute disks list --project "${PROJECT_ID}"
gcloud compute addresses list --project "${PROJECT_ID}"
gcloud compute forwarding-rules list --project "${PROJECT_ID}"
echo "Review any remaining resources and billing reports. Do not assume zero charges."
