from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def service():
    return {"service": "platform-demo", "version": "1.0"}

@app.get("/health")
def health():
    return {"status": "ok"}
