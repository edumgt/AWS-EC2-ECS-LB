from fastapi import FastAPI

app = FastAPI(title="BE FastAPI Hello", version="1.0.0")


@app.get("/")
def hello_world() -> dict[str, str]:
    return {"message": "hello world"}


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}
