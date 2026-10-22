# NVIDIA L4 + vLLM observed benchmark — 2026-10-22

**Evidence:** operator-supplied terminal outputs, not independently replayed by GitHub integration. Workload ran against VM-local vLLM on existing NVIDIA L4, not a Kubernetes GPU Pod.

## Hardware and server
- NVIDIA L4: 23,034 MiB total VRAM; 16,662 MiB allocated while model resident (~72.3%).
- Model: `Qwen/Qwen2.5-0.5B-Instruct`; vLLM v0.11.0 as previously recorded.
- Idle snapshot: SM 0%, memory-controller 0%, power ~40–41 W, GPU temperature ~76–77°C.
- 30-second `nvidia-smi dmon` during 10-request burst: SM peaks 82–83%, memory-controller peaks 80–81%, power peak 71 W, temperature peak 79°C. Only two one-second samples showed compute activity. Memory allocation remained 16,662 MiB.

## 10-concurrent-request test
- 10 successful requests, per-request wall times 1.84–1.91 s, mean 1.875 s.
- Prompt tokens: 450; completion tokens: **2,753** (corrected from an earlier summary).
- These wall times are not client-side TTFT measurements.

## vLLM cumulative metrics observed after tests
- `num_requests_running=0`, `num_requests_waiting=0`, `kv_cache_usage_perc=0` at idle.
- `prompt_tokens_total=1669`, `generation_tokens_total=15086`, `request_prompt_tokens_count=40`: cumulative metrics across multiple experiments, **not** exclusive to the ten-request test.
- TTFT histogram across 40 recorded requests: 23 <=20 ms; 39 <=40 ms; 40 <=60 ms. Engine-side metric, not end-to-end network latency.

## 32-concurrent-request test
- 32 requests completed; batch wall duration **4.42 s**; mean individual latency **4.00 s**.
- Total completion tokens **14,814**.
- Aggregate completion throughput = `14814 / 4.42` = **~3,351 tokens/s** based on rounded batch duration (script reported **3,348.0 tokens/s** using full-precision duration; use the script result as authoritative).
- Scheduler samples (roughly every 0.5 s): running 0,32,32,32,32,32,32,24,16; waiting **0 throughout observed samples**.
- KV-cache usage gauge peak sampled **0.009602428079906855 = 0.9602%** of configured KV-cache capacity. This is **not** percent of GPU VRAM allocated.
- These observations show concurrent active requests and no observed queueing at sample instants; they do not establish maximum sustainable throughput, zero queueing between samples, or actual maximum batch size.

## Interpretations and limitations
- The GPU was mostly idle outside the short generation burst despite high reserved VRAM. GPU utilization and memory allocation are distinct signals.
- Fast generation of a small model with short, similar prompts is not representative of longer-context production traffic; prefix caching may influence results.
- Request wall latency is not TTFT or inter-token latency; separate streaming benchmark required.
- No p95/p99 under sustained load, GPU memory fragmentation, long-context KV-cache pressure, error rate, or thermal throttling analysis yet.
- All infrastructure is billable while running. Never infer a hard spending cap from a billing budget.

## Next focused experiments
1. Capture vLLM scheduler configuration (`max_num_seqs`, `max_model_len`, `gpu_memory_utilization`, prefix caching) from startup logs and model configuration.
2. Run controlled **long-prompt** and sustained concurrency workloads with bounded request count and time, measuring running/waiting, KV occupancy, TTFT, ITL, latency percentiles, throughput and errors.
3. Verify Prometheus scrape targets and NVIDIA DCGM metrics; create a combined GPU/vLLM time-series dashboard.
4. Only after explicit cost approval: deploy GPU-serving vLLM on GKE L4 node pool and compare behavior.
