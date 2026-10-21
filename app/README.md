# FastAPI application (CPU)

This FastAPI app is **not vLLM**. It receives user HTTP requests and calls vLLM's OpenAI-compatible API as an HTTP client.

## Run without a GPU

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements.txt
uvicorn app.main:app --reload --port 8080
curl http://127.0.0.1:8080/health
```

The `/chat` endpoint requires a real vLLM API or mock server; `/health` does not.

## When a GPU deployment is authorized and running

```bash
kubectl -n inference-lab port-forward service/vllm-service 8000:8000
# In another terminal:
curl -sS http://127.0.0.1:8080/chat -H 'content-type: application/json' \
  -d '{"message":"What is Kubernetes?"}'
```

The vLLM service is internal; port-forward is only for development. Later we can run FastAPI on a CPU pod and call `http://vllm-service.inference-lab.svc.cluster.local:8000`.

This is a learning API without user authentication; do **not** expose it to the public internet.
