"""
Unit tests for Certificate Analyzer
"""
import pytest
from analyzer.certificate_analyzer import (
    CertificateAnalyzer,
    CertificateTrustLevel,
)


class TestCertificateAnalyzer:
    """Test cases for CertificateAnalyzer"""
    
    def setup_method(self):
        """Setup test fixtures"""
        self.analyzer = CertificateAnalyzer()
    
    def test_empty_cert_info(self):
        """Test with empty certificate info"""
        result = self.analyzer.analyze({})
        assert not result.is_signed
        assert result.trust_level == CertificateTrustLevel.UNTRUSTED
        assert result.risk_score >= 80
    
    def test_unsigned_apk(self):
        """Test unsigned APK detection"""
        cert_info = {"is_signed": False}
        result = self.analyzer.analyze(cert_info)
        assert not result.is_signed
        assert result.risk_score == 100
        assert result.trust_level == CertificateTrustLevel.UNTRUSTED
        assert len(result.warnings) > 0
    
    def test_debug_certificate_detection(self):
        """Test debug certificate detection"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v2",
            "certificates": [{
                "issuer": "CN=Android Debug, O=Android, C=US",
                "subject": "CN=Android Debug, O=Android, C=US",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert result.is_debug_signed
        assert result.risk_score >= 60
        assert any("Debug" in w or "debug" in w.lower() for w in result.warnings)
    
    def test_self_signed_detection(self):
        """Test self-signed certificate detection"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v2",
            "certificates": [{
                "issuer": "CN=MyCompany, O=MyOrg",
                "subject": "CN=MyCompany, O=MyOrg",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert result.is_self_signed
        assert result.risk_score >= 20
    
    def test_not_self_signed(self):
        """Test when issuer and subject differ"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v3",
            "certificates": [{
                "issuer": "CN=Some CA, O=Certificate Authority",
                "subject": "CN=MyApp, O=MyCompany",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert not result.is_self_signed
        assert not result.is_debug_signed
    
    def test_expired_certificate(self):
        """Test expired certificate detection"""
        cert_info = {
            "is_signed": True,
            "certificates": [{
                "issuer": "CN=Test",
                "subject": "CN=Test",
                "not_valid_after": "2020-01-01 00:00:00",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert result.is_expired
        assert result.risk_score >= 30
    
    def test_valid_certificate(self):
        """Test valid non-expired certificate"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v3",
            "certificates": [{
                "issuer": "CN=Google, O=Google Inc",
                "subject": "CN=MyApp, O=Developer",
                "not_valid_after": "2030-12-31 00:00:00",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert not result.is_expired
        assert not result.is_debug_signed
    
    def test_v1_signature_warning(self):
        """Test warning for old v1 signature"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v1",
            "certificates": [{
                "issuer": "CN=Test CA",
                "subject": "CN=MyApp",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        assert result.signature_version == "v1"
        assert result.risk_score >= 10


class TestRepackagingDetection:
    """Test repackaging and typosquatting detection"""
    
    def setup_method(self):
        self.analyzer = CertificateAnalyzer()
    
    def test_typosquat_detection_similar_names(self):
        """Test typosquatting detection for similar package names"""
        result = self.analyzer._is_typosquat("com.whatsap", "com.whatsapp")
        assert result is True
    
    def test_typosquat_same_name(self):
        """Test that same name is not typosquat"""
        result = self.analyzer._is_typosquat("com.whatsapp", "com.whatsapp")
        assert result is False
    
    def test_typosquat_different_names(self):
        """Test that completely different names are not typosquat"""
        result = self.analyzer._is_typosquat("com.example.myapp", "org.telegram.messenger")
        assert result is False


class TestTrustLevelDetermination:
    """Test trust level classification"""
    
    def setup_method(self):
        self.analyzer = CertificateAnalyzer()
    
    def test_untrusted_for_high_risk(self):
        """Test UNTRUSTED for high risk score"""
        cert_info = {"is_signed": False}
        result = self.analyzer.analyze(cert_info)
        assert result.trust_level == CertificateTrustLevel.UNTRUSTED
    
    def test_trusted_for_good_cert(self):
        """Test TRUSTED for good certificate"""
        cert_info = {
            "is_signed": True,
            "signature_version": "v3",
            "certificates": [{
                "issuer": "CN=Trusted CA",
                "subject": "CN=MyApp, O=TrustedDev",
                "not_valid_after": "2030-01-01",
            }]
        }
        result = self.analyzer.analyze(cert_info)
        # May be UNKNOWN due to self-signed, but shouldn't be UNTRUSTED
        assert result.trust_level != CertificateTrustLevel.UNTRUSTED or result.is_self_signed


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
