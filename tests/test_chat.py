import asyncio

import httpx

from app import main


def test_health():
    assert asyncio.run(main.health()) == {"status": "ok"}


def test_chat_forwards_request(monkeypatch):
    calls = []

    def responder(request):
        calls.append(request)
        assert request.url.path == "/v1/chat/completions"
        assert b"What is Kubernetes?" in request.content
        return httpx.Response(200, json={
            "model": main.MODEL_ID,
            "choices": [{"message": {"content": "Kubernetes orchestrates containers."}}],
            "usage": {"prompt_tokens": 10, "completion_tokens": 5},
        })

    original_client = httpx.AsyncClient
    monkeypatch.setattr(main.httpx, "AsyncClient", lambda **kwargs: original_client(transport=httpx.MockTransport(responder), **kwargs))
    result = asyncio.run(main.chat(main.ChatRequest(message="What is Kubernetes?")))
    assert result["answer"] == "Kubernetes orchestrates containers."
    assert len(calls) == 1
