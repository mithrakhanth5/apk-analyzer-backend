"""
Integration tests for the API endpoints
"""
import pytest
from fastapi.testclient import TestClient
import base64
import hashlib


class TestHealthEndpoints:
    """Test health check endpoints"""
    
    def test_root_endpoint(self, client):
        """Test root endpoint returns health status"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "operational"
        assert data["analyzer_ready"] is True
    
    def test_health_endpoint(self, client):
        """Test /api/v1/health endpoint"""
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert "status" in data
        assert "version" in data


class TestLimitationsEndpoint:
    """Test limitations transparency endpoint"""
    
    def test_get_limitations(self, client):
        """Test /api/v1/limitations returns limitation data"""
        response = client.get("/api/v1/limitations")
        assert response.status_code == 200
        data = response.json()
        assert "limitations" in data
        assert "disclaimer" in data
        assert len(data["limitations"]) > 0


class TestPermissionsEndpoint:
    """Test dangerous permissions list endpoint"""
    
    def test_get_permissions(self, client):
        """Test /api/v1/permissions returns permission database"""
        response = client.get("/api/v1/permissions")
        assert response.status_code == 200
        data = response.json()
        assert "count" in data
        assert "permissions" in data
        assert data["count"] > 0
        
        # Check structure of permission entries
        for perm, info in data["permissions"].items():
            assert "risk_score" in info
            assert "category" in info
            assert "description" in info


class TestAnalyzeEndpoint:
    """Test APK analysis endpoint"""
    
    def test_analyze_invalid_base64(self, client):
        """Test that invalid base64 returns error"""
        response = client.post("/api/v1/analyze", json={
            "apk_hash": "abc123",
            "apk_data": "not-valid-base64!!!"
        })
        assert response.status_code == 400
    
    def test_analyze_hash_mismatch(self, client):
        """Test that hash mismatch returns error"""
        # Create some test data
        test_data = b"this is not a real APK"
        wrong_hash = "0000000000000000000000000000000000000000000000000000000000000000"
        
        response = client.post("/api/v1/analyze", json={
            "apk_hash": wrong_hash,
            "apk_data": base64.b64encode(test_data).decode()
        })
        assert response.status_code == 400
        assert "mismatch" in response.json()["detail"].lower()
    
    def test_analyze_missing_fields(self, client):
        """Test that missing fields return validation error"""
        response = client.post("/api/v1/analyze", json={
            "apk_hash": "abc123"
            # Missing apk_data
        })
        assert response.status_code == 422  # Validation error


# Pytest fixtures
@pytest.fixture
def client():
    """Create test client"""
    # Import here to avoid issues if androguard not installed
    try:
        from main import app
        return TestClient(app)
    except ImportError as e:
        pytest.skip(f"Cannot import main app: {e}")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
