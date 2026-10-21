"""Minimal CPU-side chat API. No GPU is needed to run this application."""
import os

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="GKE vLLM Inference Lab", version="0.1.0")
VLLM_BASE_URL = os.getenv("VLLM_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
MODEL_ID = os.getenv("VLLM_MODEL", "Qwen/Qwen2.5-0.5B-Instruct")


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=8000)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.post("/chat")
async def chat(request: ChatRequest):
    payload = {
        "model": MODEL_ID,
        "messages": [{"role": "user", "content": request.message}],
        "max_tokens": 128,
        "temperature": 0.2,
    }
    try:
        async with httpx.AsyncClient(timeout=90.0) as client:
            response = await client.post(
                f"{VLLM_BASE_URL}/v1/chat/completions",
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
        answer = data["choices"][0]["message"]["content"]
        return {"answer": answer, "usage": data.get("usage"), "model": data.get("model")}
    except (httpx.HTTPError, KeyError, IndexError, ValueError) as exc:
        # Don't expose upstream credentials, hostnames, or raw error bodies.
        raise HTTPException(status_code=502, detail="Inference backend unavailable or invalid response") from exc
