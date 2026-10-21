# Simple terminology guide

| Term | Simple meaning | Where it fits |
| --- | --- | --- |
| GKE Standard | You manage cluster node pools, GKE manages control plane | Cloud infrastructure |
| GKE Autopilot | You declare workload requirements, GKE manages more node provisioning | Cloud infrastructure |
| GPU node | A Linux VM with NVIDIA GPU hardware accessible to containers | Infrastructure |
| GPU device plugin | Makes `nvidia.com/gpu` resources visible for Kubernetes scheduling | Infrastructure |
| CUDA | NVIDIA software platform for GPU compute | Model execution |
| vLLM | Software for serving pretrained LLMs efficiently | Inference |
| vLLM pod | A Kubernetes application pod running vLLM, normally requesting GPU resources | Workload |
| Kubernetes Service | Stable network address and routing to pod endpoints | Networking |
| FastAPI | Our chat application's HTTP API; it is a *client* of vLLM | Application |
| vLLM replica | Independently running instance of model-serving workload; not one user | Serving capacity |
| vLLM scheduler | Chooses inference/token work on GPU, not Kubernetes pod placement | Inference |
| Token | Model tokenizer's unit of text (may be subword/punctuation) | Input |
| Tokenization | Converts text to token IDs | Input |
| Embedding | Learned numerical vector looked up from a token ID | Model |
| Model weights | Trained numerical parameters, loaded for execution | GPU memory |
| Prefill | Processes prompt tokens and builds attention state for generation | GPU compute |
| Decode | Generates output token after output token | GPU compute |
| KV cache | Saved Transformer attention key/value state for active context | GPU memory |
| PagedAttention | Block-organized KV-cache memory/attention approach used by vLLM | Memory efficiency |
| Prefix caching | Reuses compatible KV state from a matching earlier prompt prefix | Compute reuse |
| TTFT | Time until the first output token becomes available | Latency |
| TPOT | Average time per generated output token after first token | Latency |
| Continuous batching | Admits/completes different requests while other requests generate | Throughput |
| Tensor parallelism | Splits execution of one model across multiple GPUs | Distributed inference |
| Replication | Multiple independently running copies of the serving model | Throughput/availability |

**Remember:** Kubernetes chooses **where vLLM runs**; vLLM chooses **which model execution work runs next**. One GPU can process many user requests, depending on model/latency/memory limits.
