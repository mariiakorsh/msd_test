import time, json

from fastapi import FastAPI, Request

app = FastAPI()

@app.middleware("http")
async def log_request(request: Request, call_next):
    started = time.monotonic()
    response = await call_next(request)

    print(json.dumps({
        "event": "http_request",
        "method": request.method,
        "path": request.url.path,
        "status_code": response.status_code,
        "duration_ms": round((time.monotonic() - started) * 1000, 2),
    }), flush=True)

    return response

@app.get("/")
def service():
    return {"service": "platform-demo", "version": "1.0"}

@app.get("/health")
def health():
    return {"status": "ok"}
