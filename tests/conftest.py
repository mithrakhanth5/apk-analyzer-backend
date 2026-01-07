"""
Test configuration and fixtures for pytest
"""
import pytest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.fixture
def sample_permissions():
    """Sample permission list for testing"""
    return [
        "android.permission.INTERNET",
        "android.permission.ACCESS_NETWORK_STATE",
        "android.permission.CAMERA",
    ]


@pytest.fixture
def dangerous_permissions():
    """Dangerous permission list for testing"""
    return [
        "android.permission.READ_SMS",
        "android.permission.SEND_SMS",
        "android.permission.INTERNET",
        "android.permission.BIND_ACCESSIBILITY_SERVICE",
    ]


@pytest.fixture
def valid_cert_info():
    """Valid certificate info for testing"""
    return {
        "is_signed": True,
        "signature_version": "v3",
        "certificates": [{
            "issuer": "CN=MyCompany CA, O=MyCompany",
            "subject": "CN=MyApp, O=MyCompany",
            "serial_number": "123456",
            "not_valid_before": "2024-01-01 00:00:00",
            "not_valid_after": "2030-12-31 23:59:59",
        }]
    }


@pytest.fixture
def debug_cert_info():
    """Debug certificate info for testing"""
    return {
        "is_signed": True,
        "signature_version": "v1",
        "certificates": [{
            "issuer": "CN=Android Debug, O=Android, C=US",
            "subject": "CN=Android Debug, O=Android, C=US",
        }]
    }


@pytest.fixture
def obfuscated_dex_info():
    """Heavily obfuscated DEX info for testing"""
    return {
        "dex_count": 1,
        "classes": [
            "La/a/a;",
            "La/a/b;",
            "La/b/a;",
            "Lb/a;",
            "Lc;",
            "Ld;",
        ] * 100,  # Many short class names
        "methods_count": 5000,
    }


@pytest.fixture
def normal_dex_info():
    """Normal DEX info for testing"""
    return {
        "dex_count": 1,
        "classes": [
            "Lcom/example/app/MainActivity;",
            "Lcom/example/app/LoginActivity;",
            "Lcom/example/app/models/User;",
            "Lcom/example/app/services/ApiService;",
            "Lcom/example/app/utils/Helper;",
        ] * 20,
        "methods_count": 1000,
    }
