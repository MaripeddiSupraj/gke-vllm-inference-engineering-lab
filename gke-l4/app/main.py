import os
import secrets
import httpx
from fastapi import FastAPI, Depends, Header, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="GPU Inference API", docs_url=None, redoc_url=None)
MODEL = os.getenv("MODEL_ID", "Qwen/Qwen2.5-0.5B-Instruct")
VLLM_URL = os.getenv("VLLM_URL", "http://vllm:8000/v1/chat/completions")
API_KEY = os.environ["INFERENCE_API_KEY"]

class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)

def authenticate(x_api_key: str | None = Header(default=None)):
    if not x_api_key or not secrets.compare_digest(x_api_key, API_KEY):
        raise HTTPException(status_code=401, detail="Unauthorized")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/api/v1/chat", dependencies=[Depends(authenticate)])
async def chat(request: ChatRequest):
    try:
        async with httpx.AsyncClient(timeout=90.0) as client:
            result = await client.post(VLLM_URL, json={
                "model": MODEL,
                "messages": [{"role": "user", "content": request.message}],
                "temperature": 0,
                "max_tokens": 150,
            })
            result.raise_for_status()
            data = result.json()
            return {"model": MODEL, "answer": data["choices"][0]["message"]["content"], "usage": data.get("usage")}
    except (httpx.HTTPError, KeyError, IndexError, ValueError, TypeError):
        raise HTTPException(status_code=502, detail="Inference backend unavailable or invalid response")
