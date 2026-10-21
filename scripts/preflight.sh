#!/usr/bin/env bash
set -euo pipefail
echo "OFFLINE PREFLIGHT ONLY — this script creates no GCP resources."
command -v terraform >/dev/null || { echo "Missing terraform"; exit 1; }
command -v python3 >/dev/null || { echo "Missing python3"; exit 1; }
terraform -chdir=infra/terraform fmt -check
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
python3 -m compileall -q app
echo "Offline checks complete. GPU quota and GCP budget must still be confirmed."
