# NVIDIA L4 + vLLM concurrency scaling — 2026-10-22

Operator-provided measurements from a VM-local OpenAI-compatible vLLM server running Qwen/Qwen2.5-0.5B-Instruct on one NVIDIA L4. Same short prompt, temperature=0, max_tokens=400, one burst per concurrency level. These are burst benchmarks, not sustained production load or GKE GPU node results.

| Concurrent requests | Batch wall duration (s) | Mean request latency (s) | Aggregate output throughput (tokens/s) |
|---:|---:|---:|---:|
| 8 | 2.63 | 2.62 | 1215.7 |
| 16 | 2.95 | 2.91 | 2170.4 |
| 32 | 3.64 | 3.52 | 3514.3 |
| 48 | 4.45 | 4.26 | 4315.4 |
| 64 | 5.23 | 4.96 | 4898.4 |

## Findings

- Highest measured throughput was **4,898.4 completion tokens/s** at concurrency 64. Throughput has not yet peaked in this tested range.
- Throughput at concurrency 64 is ~4.03x the throughput at concurrency 8, while mean latency is ~1.89x.
- Marginal throughput gains diminish at higher concurrency, but this alone does not establish GPU saturation.
- Identical prompts may benefit from prefix caching. Each concurrency level is a different burst with request count equal to concurrency; tests do not isolate steady-state concurrency, cache effects, or sustained throughput.
- No p95/p99 latency, queue metrics, GPU utilization, power, KV-cache occupancy or request error counts were captured in this particular run.

## Next experiment

Confirm scheduler configuration and prefix caching, then repeat bounded same-length but distinct-prompt concurrency tests, capture vLLM running/waiting/KV-cache and NVIDIA GPU telemetry during the runs, and compare throughput with p95 latency and errors. No new infrastructure required.
