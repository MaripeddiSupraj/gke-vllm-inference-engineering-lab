# NVIDIA L4 + vLLM — Hands-on GPU Inference Lab

> **Learning journal · 22 October 2026**  
> **Status:** 🟡 Infrastructure ready; vLLM image download initiated, completion **not yet confirmed**  
> **Platform:** Google Cloud Compute Engine · Debian 12 · NVIDIA L4 · Docker

## 1. At a glance

We are learning how an AI inference platform is built from the infrastructure upward: allocate a GPU, install its driver, expose it securely to containers, install an inference engine, load a model, and measure serving performance. This phase runs on **one Compute Engine VM**; it is **not yet a successful GKE deployment**.

| Layer | Selected technology | Evidence / status |
| --- | --- | --- |
| Cloud | GCP project `gke-vllm-learning-lab` | VM provisioned |
| Compute | `g2-standard-4` in `asia-southeast1-a` | VM accessible |
| GPU | NVIDIA L4, ~24 GB marketed VRAM; `nvidia-smi` reports **23,034 MiB** | **Verified** |
| OS | Debian 12, x86_64 / linux/amd64 | **Verified** |
| Boot storage | 80 GB `pd-balanced` | Cloud resize, partition growth, and ext4 resize **confirmed**; final `df -h /` check pending |
| Host driver | NVIDIA **615.71.10** | **Verified** |
| Container runtime | Debian Docker **20.10.24+dfsg1**, `overlay2` | **Verified** |
| GPU container integration | NVIDIA Container Toolkit **1.20.1** | **Verified** |
| Inference engine | `vllm/vllm-openai:v0.11.0` | Manifest checked; pull **in progress / unconfirmed** |
| Model | `Qwen/Qwen2.5-0.5B-Instruct` | Selected; **not downloaded or served yet** |
| API | OpenAI-compatible `/v1/chat/completions` | **Not yet tested** |

### Architecture we are building

```text
Client (curl / Python / OpenAI SDK)
                |
                | HTTP POST /v1/chat/completions
                v
       vLLM API server in Docker
                |
                v
       Qwen2.5-0.5B-Instruct
         (separate model files)
                |
                v
       CUDA/PyTorch model execution
                |
                v
       NVIDIA Container Toolkit
                |
                v
       Host NVIDIA kernel driver
                |
                v
          NVIDIA L4 GPU
```

**Key distinction:** The **GPU driver** is installed on the VM host. The **vLLM engine** is packaged in the Docker image. The **Qwen model** is a separate set of learned weights, downloaded/cached when the server starts. Image storage and model cache use **disk**; loaded weights and inference/KV cache use **GPU VRAM**.

## 2. Why this VM instead of GKE?

### Capacity experiments

| Attempt | Result | Lesson |
| --- | --- | --- |
| GKE T4 GPU node pool, `us-central1-a` | `ZONE_RESOURCE_POOL_EXHAUSTED` | Quota and actual zonal GPU stock are different |
| GKE T4 GPU node pool, `us-central1-b` | `ZONE_RESOURCE_POOL_EXHAUSTED` | Changing zones may not resolve capacity |
| Standalone T4 VM, `asia-south1-a` / `asia-south1-b` | Capacity exhausted | Validate available accelerator supply |
| Standalone T4 VM, `asia-southeast1-a` | Capacity exhausted | Same region does not imply same SKU availability |
| Standalone L4 VM, `asia-southeast1-a` | **Succeeded** | Use available GPU to validate the serving stack before Kubernetes |

Failed GKE resources were cleaned up; a cluster listing was observed empty at that point. **Current resources and billing must be rechecked independently.** We did not silently recreate GKE.

### GPU allocation is not the same as a working GPU stack

Provisioning a VM with an L4 only allocates hardware. The OS still needs the compatible NVIDIA driver, and Docker needs GPU device/runtime integration. `nvidia-smi` inside the VM verifies host driver visibility; `nvidia-smi` inside a GPU-enabled container verifies container passthrough. Neither alone proves successful LLM inference.

## 3. NVIDIA driver installation and troubleshooting

Google's GPU installer was downloaded to `~/cuda_installer.pyz` from:

```text
https://storage.googleapis.com/compute-gpu-installation-us/installer/latest/cuda_installer.pyz
```

Installer command:

```bash
sudo python3 ~/cuda_installer.pyz install_driver \
  --installation-mode repo \
  --installation-branch prod
```

The first installation required a reboot; immediately afterward `nvidia-smi` was still missing and `verify_driver` did not pass. Reviewing `/opt/google/cuda-installer/installer.log` showed the reboot continuation message. After completing the prerequisite sequence and rerunning the installer, the NVIDIA Open DKMS driver installed successfully.

**Observed verification:**

```bash
nvidia-smi
sudo python3 ~/cuda_installer.pyz verify_driver
```

- Driver and kernel module: **615.71.10**
- GPU: **NVIDIA L4**
- Reported memory: **23,034 MiB**
- Reported CUDA driver capability: **13.4**

**Important:** The CUDA version displayed by `nvidia-smi` does **not** establish that the CUDA Toolkit or `nvcc` is installed. Avoid reinstalling the driver blindly when verification fails; check installer logs, kernel module and reboot requirements first.

## 4. Docker and NVIDIA GPU passthrough

Docker was installed from Debian packages, then NVIDIA Container Toolkit from NVIDIA's package repository. Docker's GPU runtime was configured and restarted:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Successful GPU-in-container test:**

```bash
sudo docker run --rm --gpus all ubuntu:22.04 nvidia-smi
```

The container reported the same L4 and driver as the host. This proves Docker can access the GPU via the NVIDIA integration; it does **not** prove CUDA kernels or inference workloads have executed.

**How it works:** Docker isolates container processes/filesystems, while the NVIDIA Container Toolkit makes selected GPU devices and driver interfaces accessible. We are not installing a separate physical GPU or a full independent host driver inside each container.

**Storage observed before resizing:** Docker root `/var/lib/docker`, `overlay2` storage driver, Ubuntu 22.04 image about 78.1 MB, no retained containers/volumes/build cache.

## 5. Disk sizing — real-world capacity issue and fix

The VM originally had a **30 GB** boot disk; `df -h /` showed **5.3 GB used and ~23 GB available**. The planned vLLM image was too large to pull safely without more headroom.

### Why the image-size inspection was misleading at first

```bash
sudo docker manifest inspect --verbose vllm/vllm-openai:v0.11.0
```

The image is multi-architecture. Summing layers across *all* platform variants yielded about **22.93 GiB**, which is **not** the download size for our VM.

| Platform | Compressed image layers |
| --- | ---: |
| linux/arm64 | **11.33 GiB** |
| **linux/amd64** (our VM) | **11.60 GiB** |

The small `size` values of ~7 KB in the top-level manifest list refer to **manifest documents**, not image layers. Compressed download size also differs from extracted on-disk usage, so 23 GB free was an unsafe margin.

### Expanded the existing boot disk, without recreating the GPU VM

1. From the **Mac**, using the user's gcloud identity, identified the disk:
   ```bash
   gcloud compute disks list \
     --project=gke-vllm-learning-lab \
     --filter="zone:(asia-southeast1-a)" \
     --format="table(name,sizeGb,type,status)"
   ```
   Result: `l4-capacity-test`, **30 GB**, `pd-balanced`, `READY`.
2. From the **Mac**, resized GCP persistent disk to **80 GB**:
   ```bash
   gcloud compute disks resize l4-capacity-test \
     --size=80GB \
     --zone=asia-southeast1-a \
     --project=gke-vllm-learning-lab
   ```
   API returned `sizeGb: '80'`, `status: READY`.
3. Inside the VM, `df -h /` still showed **30G**. `lsblk -f` identified the root filesystem as **ext4** on `/dev/nvme0n1p1`, and EFI on `/dev/nvme0n1p15`.
4. `growpart` was initially missing; installed `cloud-guest-utils`.
5. Grew partition 1:
   ```bash
   sudo growpart /dev/nvme0n1 1
   ```
   Result: `CHANGED`, from **62,650,369** to **167,509,983** sectors.
6. Expanded the mounted ext4 filesystem **online**:
   ```bash
   sudo resize2fs /dev/nvme0n1p1
   ```
   Result: `The filesystem on /dev/nvme0n1p1 is now 20938747 (4k) blocks long.`

**Three layers to remember:** cloud disk capacity → Linux partition boundaries → filesystem usable capacity. The final `df -h /` verification after `resize2fs` is **still pending**, though the resize command succeeded. Do **not** format the disk or modify the EFI partition.

### GCP authentication lesson

Running `gcloud compute disks describe` **inside the VM** failed with `ACCESS_TOKEN_SCOPE_INSUFFICIENT`: it used the VM's default Compute Engine service account, whose OAuth scopes did not permit that call. Running administrative `gcloud` operations from the **Mac** used a different authenticated identity and succeeded. Cloud IAM roles and VM OAuth scopes can both constrain API access; there was no need to broaden VM permissions for this task.

## 6. vLLM is the engine; Qwen is the model

Planned image:

```bash
sudo docker pull --platform linux/amd64 vllm/vllm-openai:v0.11.0
```

**At time of writing:** Image tag existence and architecture-specific layer sizes were verified. The user reported that the image was downloading, but **successful completion has not yet been shown**.

| Item | What it does | Where it lives |
| --- | --- | --- |
| `vllm/vllm-openai:v0.11.0` | Packages the vLLM inference server and dependencies | Docker image/layers on disk |
| `Qwen/Qwen2.5-0.5B-Instruct` | Supplies trained language-model weights | Download/cache on disk, then loaded into memory/VRAM |
| NVIDIA L4 | Performs accelerated computations | Physical GPU |
| NVIDIA driver/toolkit | Connects host/container processes to GPU | Host OS and container runtime integration |

**Why `openai` appears in the image name:** vLLM exposes an **OpenAI-compatible HTTP API**, not an OpenAI-hosted model. We can run Qwen locally and send requests to `/v1/chat/completions` with an OpenAI-compatible SDK, pointed at our server. API compatibility does not imply feature-by-feature equivalence, and a production endpoint needs authentication and network restrictions.

## 7. Next experiments and evidence checklist

- [x] Provision available L4 VM after T4 capacity failures
- [x] Install and verify host NVIDIA driver
- [x] Install Docker and NVIDIA Container Toolkit
- [x] Run `nvidia-smi` inside a GPU-enabled container
- [x] Analyze multi-architecture vLLM image size
- [x] Expand GCP boot disk, root partition and ext4 filesystem
- [ ] Confirm `df -h /` shows expanded usable space
- [ ] Confirm Docker image pull finished successfully
- [ ] Start vLLM with `Qwen/Qwen2.5-0.5B-Instruct` and a persistent model cache
- [ ] Verify model download and GPU VRAM allocation with `nvidia-smi`
- [ ] Send first successful OpenAI-compatible chat completion
- [ ] Explain and measure **prefill**, **decode**, **KV cache**, **latency**, **throughput**, and **concurrency**
- [ ] Keep inference API on localhost / SSH tunnel, not publicly exposed
- [ ] Reassess GKE only after standalone serving succeeds and user approves resources/cost
- [ ] Stop/delete VM when lab work is done; verify remaining disk/resources and charges

### Planned evidence to capture

For each experiment: command/configuration, relevant output, what it proves, what it **does not** prove, observed GPU memory/utilization, timings, failure/recovery notes, and cost implications. Avoid publishing tokens, secrets, ephemeral IPs or sensitive account identifiers.

## 8. Cost, reliability and security guardrails

- Earlier **rough estimate**: ~**USD 0.87/hour** for the running GPU VM, **not a verified billing receipt**; disk, egress and taxes may add costs.
- The 80 GB `pd-balanced` disk costs more than the original 30 GB, including while the VM is stopped.
- Stopping the VM avoids running compute/GPU charges but may make L4 capacity unavailable when restarting.
- Do not expose the unauthenticated vLLM HTTP endpoint to the public internet.
- Pin the container version; record model revision/digest for stronger reproducibility in a production deployment.
- GPU VRAM, system RAM, boot disk and model cache are different resources and should be monitored independently.

## 9. Scope and verification disclaimer

This journal is based on **terminal output supplied by the learner**. It is not a live independent audit of the VM, GitHub Actions, GCP Billing or Docker Hub. NVIDIA driver and Docker GPU passthrough were observed successful. Disk resize operations were observed successful, but the post-resize `df` output is not yet supplied. **vLLM download completion, model serving, API response, inference performance and GKE deployment remain unverified.**
