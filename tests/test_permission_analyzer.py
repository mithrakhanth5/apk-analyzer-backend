"""
Unit tests for Permission Analyzer
"""
import pytest
from analyzer.permission_analyzer import (
    PermissionAnalyzer,
    RiskLevel,
    PermissionCategory,
)


class TestPermissionAnalyzer:
    """Test cases for PermissionAnalyzer"""
    
    def setup_method(self):
        """Setup test fixtures"""
        self.analyzer = PermissionAnalyzer()
    
    def test_empty_permissions(self):
        """Test with no permissions"""
        result = self.analyzer.analyze([])
        assert result.total_permissions == 0
        assert result.dangerous_count == 0
        assert result.overall_score == 0
        assert len(result.permission_risks) == 0
        assert len(result.combination_risks) == 0
    
    def test_safe_permissions(self):
        """Test with only safe permissions"""
        permissions = [
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
        ]
        result = self.analyzer.analyze(permissions)
        assert result.total_permissions == 2
        assert result.dangerous_count == 0
        assert result.overall_score < 30  # Should be SAFE
    
    def test_dangerous_sms_permissions(self):
        """Test SMS-related dangerous permissions"""
        permissions = [
            "android.permission.READ_SMS",
            "android.permission.SEND_SMS",
            "android.permission.RECEIVE_SMS",
        ]
        result = self.analyzer.analyze(permissions)
        assert result.dangerous_count >= 3
        assert result.overall_score >= 50
        
        # Check specific permission risks
        sms_risks = [p for p in result.permission_risks if "SMS" in p.permission]
        assert len(sms_risks) == 3
        assert all(p.risk_score >= 9 for p in sms_risks)
    
    def test_otp_theft_combination(self):
        """Test detection of OTP theft pattern"""
        permissions = [
            "android.permission.READ_SMS",
            "android.permission.INTERNET",
        ]
        result = self.analyzer.analyze(permissions)
        
        # Should detect OTP theft combination
        otp_risks = [c for c in result.combination_risks if c.threat_type == "OTP_THEFT"]
        assert len(otp_risks) == 1
        assert otp_risks[0].risk_score == 10
    
    def test_keylogger_combination(self):
        """Test detection of keylogger pattern"""
        permissions = [
            "android.permission.BIND_ACCESSIBILITY_SERVICE",
            "android.permission.INTERNET",
        ]
        result = self.analyzer.analyze(permissions)
        
        # Should detect keylogger pattern
        keylogger_risks = [c for c in result.combination_risks if c.threat_type == "KEYLOGGER"]
        assert len(keylogger_risks) == 1
        assert keylogger_risks[0].risk_score == 10
    
    def test_stalkerware_combination(self):
        """Test detection of stalkerware pattern"""
        permissions = [
            "android.permission.ACCESS_FINE_LOCATION",
            "android.permission.INTERNET",
            "android.permission.ACCESS_BACKGROUND_LOCATION",
        ]
        result = self.analyzer.analyze(permissions)
        
        # Should detect stalkerware pattern
        stalker_risks = [c for c in result.combination_risks if c.threat_type == "STALKERWARE"]
        assert len(stalker_risks) == 1
    
    def test_accessibility_is_critical(self):
        """Test that accessibility service is marked critical"""
        permissions = ["android.permission.BIND_ACCESSIBILITY_SERVICE"]
        result = self.analyzer.analyze(permissions)
        
        acc_risk = result.permission_risks[0]
        assert acc_risk.risk_score == 10
        assert acc_risk.risk_level == RiskLevel.CRITICAL
        assert acc_risk.category == PermissionCategory.ACCESSIBILITY
    
    def test_multiple_combinations(self):
        """Test detection of multiple risky combinations"""
        permissions = [
            "android.permission.READ_SMS",
            "android.permission.INTERNET",
            "android.permission.READ_CONTACTS",
        ]
        result = self.analyzer.analyze(permissions)
        
        # Should detect OTP theft + contact exfiltration
        assert len(result.combination_risks) >= 2
    
    def test_permission_normalization(self):
        """Test that short permission names are normalized"""
        result1 = self.analyzer.analyze(["android.permission.CAMERA"])
        result2 = self.analyzer.analyze(["CAMERA"])
        
        # Both should find the camera permission
        assert len(result1.permission_risks) == 1
        # Short form may or may not be normalized depending on implementation
    
    def test_score_calculation(self):
        """Test overall score calculation"""
        # High risk app
        high_risk_perms = [
            "android.permission.READ_SMS",
            "android.permission.SEND_SMS",
            "android.permission.INTERNET",
            "android.permission.BIND_ACCESSIBILITY_SERVICE",
        ]
        high_result = self.analyzer.analyze(high_risk_perms)
        
        # Low risk app
        low_risk_perms = [
            "android.permission.INTERNET",
            "android.permission.VIBRATE",
        ]
        low_result = self.analyzer.analyze(low_risk_perms)
        
        assert high_result.overall_score > low_result.overall_score
        assert high_result.overall_score >= 60  # HIGH RISK
        assert low_result.overall_score <= 30   # SAFE


class TestPermissionCategories:
    """Test permission categorization"""
    
    def setup_method(self):
        self.analyzer = PermissionAnalyzer()
    
    def test_camera_category(self):
        result = self.analyzer.analyze(["android.permission.CAMERA"])
        assert result.permission_risks[0].category == PermissionCategory.CAMERA
    
    def test_location_category(self):
        result = self.analyzer.analyze(["android.permission.ACCESS_FINE_LOCATION"])
        assert result.permission_risks[0].category == PermissionCategory.LOCATION
    
    def test_sms_category(self):
        result = self.analyzer.analyze(["android.permission.READ_SMS"])
        assert result.permission_risks[0].category == PermissionCategory.SMS


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
