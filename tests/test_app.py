from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_service_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"service": "platform-demo", "version": "1.0"}


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
