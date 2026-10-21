#!/usr/bin/env bash
set -euo pipefail
echo "READ-ONLY: inspecting GPU resources in current kubectl context"
kubectl config current-context
kubectl get nodes -o wide
kubectl get nodes -o custom-columns='NAME:.metadata.name,GPU_CAPACITY:.status.capacity.nvidia\\.com/gpu,GPU_ALLOCATABLE:.status.allocatable.nvidia\\.com/gpu'
kubectl -n inference-lab get pods -o wide || true
echo "For NVIDIA driver inspection, exec into an authorized GPU diagnostic pod and run nvidia-smi."
