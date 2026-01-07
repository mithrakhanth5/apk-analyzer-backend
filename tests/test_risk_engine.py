"""
Unit tests for Risk Engine
"""
import pytest
from analyzer.permission_analyzer import PermissionAnalyzer, PermissionAnalysisResult
from analyzer.certificate_analyzer import CertificateAnalyzer, CertificateAnalysisResult
from analyzer.obfuscation_detector import ObfuscationDetector, ObfuscationAnalysisResult
from analyzer.network_extractor import NetworkExtractor, NetworkAnalysisResult
from analyzer.risk_engine import RiskEngine, RiskClassification


class TestRiskEngine:
    """Test cases for RiskEngine"""
    
    def setup_method(self):
        """Setup test fixtures"""
        self.engine = RiskEngine()
        self.perm_analyzer = PermissionAnalyzer()
        self.cert_analyzer = CertificateAnalyzer()
        self.obf_detector = ObfuscationDetector()
        self.net_extractor = NetworkExtractor()
    
    def _create_mock_results(
        self,
        perm_score=0,
        cert_score=0,
        obf_score=0,
        net_score=0,
    ):
        """Create mock analysis results"""
        perm_result = self.perm_analyzer.analyze([])
        perm_result.overall_score = perm_score
        
        cert_result = self.cert_analyzer.analyze({"is_signed": True, "certificates": []})
        cert_result.risk_score = cert_score
        
        obf_result = ObfuscationAnalysisResult(obfuscation_score=obf_score)
        
        net_result = NetworkAnalysisResult(risk_score=net_score)
        
        return perm_result, cert_result, obf_result, net_result
    
    def test_safe_classification(self):
        """Test SAFE classification for low-risk APK"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=10,
            cert_score=5,
            obf_score=0,
            net_score=0,
        )
        
        report = self.engine.calculate_risk(
            package_name="com.safe.app",
            version_name="1.0",
            app_name="Safe App",
            file_hash="abc123",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert report.classification == RiskClassification.SAFE
        assert report.overall_score <= 30
    
    def test_suspicious_classification(self):
        """Test SUSPICIOUS classification for medium-risk APK"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=60,
            cert_score=30,
            obf_score=40,
            net_score=20,
        )
        
        report = self.engine.calculate_risk(
            package_name="com.suspicious.app",
            version_name="1.0",
            app_name="Suspicious App",
            file_hash="def456",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert report.classification == RiskClassification.SUSPICIOUS
        assert 31 <= report.overall_score <= 60
    
    def test_high_risk_classification(self):
        """Test HIGH_RISK classification for dangerous APK"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=90,
            cert_score=80,
            obf_score=70,
            net_score=60,
        )
        
        report = self.engine.calculate_risk(
            package_name="com.malicious.app",
            version_name="1.0",
            app_name="Malicious App",
            file_hash="ghi789",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert report.classification == RiskClassification.HIGH_RISK
        assert report.overall_score > 60
    
    def test_weighted_score_calculation(self):
        """Test that scores are weighted correctly"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=100,
            cert_score=0,
            obf_score=0,
            net_score=0,
        )
        
        report = self.engine.calculate_risk(
            package_name="test",
            version_name="1.0",
            app_name="Test",
            file_hash="test",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        # Permission weight is 0.35, so 100 * 0.35 = 35
        assert report.overall_score >= 35
    
    def test_findings_generation(self):
        """Test that findings are generated from results"""
        # Use real analyzer with dangerous permissions
        perm_result = self.perm_analyzer.analyze([
            "android.permission.READ_SMS",
            "android.permission.INTERNET",
        ])
        
        cert_result = self.cert_analyzer.analyze({
            "is_signed": True,
            "certificates": [{
                "issuer": "CN=Android Debug",
                "subject": "CN=Android Debug",
            }]
        })
        
        obf_result = ObfuscationAnalysisResult()
        net_result = NetworkAnalysisResult()
        
        report = self.engine.calculate_risk(
            package_name="test.app",
            version_name="1.0",
            app_name="Test App",
            file_hash="hash",
            permission_result=perm_result,
            certificate_result=cert_result,
            obfuscation_result=obf_result,
            network_result=net_result,
        )
        
        # Should have findings from permissions and certificate
        assert len(report.findings) > 0
        
        # Should have critical findings (OTP theft + debug cert)
        perm_findings = [f for f in report.findings if f.category == "PERMISSION"]
        cert_findings = [f for f in report.findings if f.category == "CERTIFICATE"]
        
        assert len(perm_findings) > 0
        assert len(cert_findings) > 0
    
    def test_limitations_included(self):
        """Test that limitations are always included"""
        perm, cert, obf, net = self._create_mock_results()
        
        report = self.engine.calculate_risk(
            package_name="test",
            version_name="1.0",
            app_name="Test",
            file_hash="test",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert len(report.limitations) > 0
        assert any("static" in l.lower() for l in report.limitations)
    
    def test_recommendation_for_safe_app(self):
        """Test recommendation text for safe app"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=5,
            cert_score=5,
        )
        
        report = self.engine.calculate_risk(
            package_name="safe.app",
            version_name="1.0",
            app_name="Safe App",
            file_hash="hash",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert "safe" in report.recommendation.lower()
    
    def test_recommendation_for_high_risk_app(self):
        """Test recommendation contains warning for high risk"""
        perm, cert, obf, net = self._create_mock_results(
            perm_score=90,
            cert_score=80,
        )
        
        report = self.engine.calculate_risk(
            package_name="bad.app",
            version_name="1.0",
            app_name="Bad App",
            file_hash="hash",
            permission_result=perm,
            certificate_result=cert,
            obfuscation_result=obf,
            network_result=net,
        )
        
        assert "not" in report.recommendation.lower() or "risk" in report.recommendation.lower()
    
    def test_component_score_accessibility_service(self):
        """Test that accessibility service increases component score"""
        score = self.engine._calculate_component_score({
            "services": ["com.example.AccessibilityService"],
            "receivers": [],
        })
        
        assert score >= 30
    
    def test_component_score_sms_receiver(self):
        """Test that SMS receiver increases component score"""
        score = self.engine._calculate_component_score({
            "services": [],
            "receivers": ["com.example.SMS_RECEIVED_RECEIVER"],
        })
        
        assert score >= 10


class TestRiskClassificationThresholds:
    """Test classification threshold boundaries"""
    
    def setup_method(self):
        self.engine = RiskEngine()
    
    def test_boundary_safe_suspicious(self):
        """Test boundary between SAFE and SUSPICIOUS at 30"""
        assert self.engine._classify_risk(30) == RiskClassification.SAFE
        assert self.engine._classify_risk(31) == RiskClassification.SUSPICIOUS
    
    def test_boundary_suspicious_high(self):
        """Test boundary between SUSPICIOUS and HIGH_RISK at 60"""
        assert self.engine._classify_risk(60) == RiskClassification.SUSPICIOUS
        assert self.engine._classify_risk(61) == RiskClassification.HIGH_RISK


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
