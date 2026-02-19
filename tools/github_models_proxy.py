#!/usr/bin/env python3
"""Proxy local mínimo para usar GitHub Models (incl. OpenAI GPT-5-Codex) vía token de GitHub."""

from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os
import urllib.request
import urllib.error

HOST = os.getenv("HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", "8787"))
ENDPOINT = "https://models.github.ai/inference/chat/completions"
DEFAULT_MODEL = os.getenv("MODEL", "openai/gpt-5.3-codex")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")


class Handler(BaseHTTPRequestHandler):
    def _send(self, status: int, payload: dict):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        if self.path != "/chat":
            return self._send(404, {"error": "Ruta no encontrada. Usa POST /chat"})

        if not GITHUB_TOKEN:
            return self._send(500, {"error": "Falta GITHUB_TOKEN en variables de entorno"})

        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length)
            data = json.loads(raw.decode("utf-8") or "{}")
        except Exception as e:
            return self._send(400, {"error": f"JSON inválido: {e}"})

        model = data.get("model", DEFAULT_MODEL)
        messages = data.get("messages")
        if not messages:
            prompt = data.get("prompt")
            if not prompt:
                return self._send(400, {"error": "Envía 'prompt' o 'messages'"})
            messages = [{"role": "user", "content": prompt}]

        payload = {
            "model": model,
            "messages": messages,
            "temperature": data.get("temperature", 0.2),
            "max_tokens": data.get("max_tokens", 1200),
        }

        req = urllib.request.Request(
            ENDPOINT,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Authorization": f"Bearer {GITHUB_TOKEN}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                out = resp.read().decode("utf-8")
                self._send(200, json.loads(out))
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", errors="ignore")
            self._send(e.code, {"error": "Error de GitHub Models", "detail": detail})
        except Exception as e:
            self._send(502, {"error": f"Fallo de conexión con GitHub Models: {e}"})


def main():
    print(f"[github-models-proxy] http://{HOST}:{PORT}/chat")
    print(f"[github-models-proxy] model por defecto: {DEFAULT_MODEL}")
    HTTPServer((HOST, PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
