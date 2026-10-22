# GPU Lab Progress — 2026-10-22

## Status
**In progress — standalone NVIDIA L4 VM allocated; NVIDIA driver verified successfully via nvidia-smi.** This is a Compute Engine capacity/driver learning step, **not a successful GKE/vLLM deployment**.

## Environment
- GCP project: `gke-vllm-learning-lab`
- VM: `l4-capacity-test`
- Zone: `asia-southeast1-a`
- Machine: `g2-standard-4` (NVIDIA L4, 24 GiB GPU VRAM)
- OS: Debian 12; 30 GiB boot disk
- VM observed RUNNING and accessible by SSH. External IP is ephemeral; do not hard-code it.

## Verified progress
1. GKE T4 GPU node-pool attempts in `us-central1-a` and `us-central1-b` failed with `ZONE_RESOURCE_POOL_EXHAUSTED`.
2. Failed GKE resources were torn down; `gcloud container clusters list` was observed empty at that point. **This does not verify present-day billing or resources.**
3. Standalone T4 VM allocation attempts in `asia-south1-a`, `asia-south1-b`, and `asia-southeast1-a` failed with `ZONE_RESOURCE_POOL_EXHAUSTED`.
4. Standalone L4 VM allocation succeeded in Singapore. **GPU capacity allocated ≠ NVIDIA driver working.**
5. Downloaded Google's GPU installer archive to `~/cuda_installer.pyz` from `https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz`.
6. Ran installer in repository mode on production branch. Installer log showed packages/kernel headers installed, then automatic reboot to continue.
7. Reconnected successfully after reboot. `nvidia-smi` returned `command not found`; `sudo python3 ~/cuda_installer.pyz verify_driver` reported: `Couldn't find nvidia-smi, the driver is not installed.`
8. `/opt/google/cuda-installer/installer.log` showed `The system needs to be rebooted to complete the installation process. The process will be continued after the reboot.` Follow-up entries only showed machine-type detection and working-directory selection. No definitive driver-install error in the supplied log tail.

## Driver verification — confirmed 2026-10-22 07:08:34
After prerequisite reboot, reran the installer:

```bash
sudo python3 ~/cuda_installer.pyz install_driver \
  --installation-mode repo \
  --installation-branch prod
```

The package installation built NVIDIA Open DKMS module version 615.71.10. The user then ran:

```bash
nvidia-smi
sudo python3 ~/cuda_installer.pyz verify_driver
```

Observed successful `nvidia-smi` output: NVIDIA L4, NVIDIA-SMI 615.71.10, KMD 615.71.10, CUDA UMD 13.4, 23034 MiB total GPU memory, 0 MiB used, 0% GPU utilization, no GPU processes. Driver works; CUDA toolkit installation has not been established.\n\nIf future driver checks fail, inspect `/opt/google/cuda-installer/installer.log` and package/kernel status **before retrying again**.

## Pending milestones
- [x] NVIDIA driver installed and `nvidia-smi` verified
- [ ] Confirm CUDA runtime/driver compatibility
- [ ] Install Docker and NVIDIA Container Toolkit; validate GPU access from container
- [ ] Run pinned small-model vLLM container and test OpenAI-compatible endpoint
- [ ] Measure GPU utilization, VRAM, inference throughput, latency, and KV-cache behavior
- [ ] Decide whether to return to GKE after standalone VM lab (requires explicit approval and cost/capacity check)
- [ ] Stop or delete VM after session; verify cleanup and actual charges

## Cost and safety
- Previous indicative estimate for this VM: approximately USD 0.87/hour, **not an actual billing receipt**; disk/network/tax extra. Verify current official pricing and actual Cloud Billing usage.
- VM compute/GPU accrues charges while RUNNING, including during troubleshooting.
- Stopping avoids running compute/GPU charges but boot disk remains billable; restarting may encounter GPU capacity shortage.
- Do not commit credentials, secrets, billing IDs, or ephemeral external IPs.

## Evidence limitations
This record is based on terminal output supplied during the session, not independent access to the live VM or Cloud Billing. Driver installation and `nvidia-smi` are verified from user-provided terminal output. Docker, CUDA Toolkit, vLLM and end-to-end inference **are not yet verified**.
