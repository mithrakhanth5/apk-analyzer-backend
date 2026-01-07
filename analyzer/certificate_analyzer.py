"""
Certificate Analyzer Module
Analyzes APK signing certificates for trust assessment.
"""
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from enum import Enum
from datetime import datetime
import hashlib


class CertificateTrustLevel(str, Enum):
    TRUSTED = "TRUSTED"
    UNKNOWN = "UNKNOWN"
    SUSPICIOUS = "SUSPICIOUS"
    UNTRUSTED = "UNTRUSTED"


@dataclass
class CertificateAnalysisResult:
    """Certificate analysis result"""
    is_signed: bool = False
    signature_version: Optional[str] = None
    is_debug_signed: bool = False
    is_self_signed: bool = False
    is_expired: bool = False
    trust_level: CertificateTrustLevel = CertificateTrustLevel.UNKNOWN
    risk_score: int = 0  # 0-100
    
    issuer: str = ""
    subject: str = ""
    serial_number: str = ""
    valid_from: Optional[str] = None
    valid_until: Optional[str] = None
    fingerprint_sha256: str = ""
    
    warnings: List[str] = None
    
    def __post_init__(self):
        if self.warnings is None:
            self.warnings = []


# Known debug certificate patterns
DEBUG_CERTIFICATE_PATTERNS = [
    "CN=Android Debug",
    "CN=Debug",
    "O=Android",
    "OU=Android",
    "CN=unknown",
]

# Known malicious certificate fingerprints (example - in production, use threat intel feeds)
KNOWN_MALICIOUS_CERTS: Dict[str, str] = {
    # SHA256 fingerprint -> description
    # These would be populated from threat intelligence feeds
}

# Known legitimate publisher certificates (example)
KNOWN_TRUSTED_PUBLISHERS: Dict[str, str] = {
    # SHA256 fingerprint -> publisher name
    # "abc123...": "Google LLC",
}


class CertificateAnalyzer:
    """
    Analyzes APK signing certificates to assess authenticity and trust.
    """
    
    def __init__(self):
        self.debug_patterns = DEBUG_CERTIFICATE_PATTERNS
        self.malicious_certs = KNOWN_MALICIOUS_CERTS
        self.trusted_publishers = KNOWN_TRUSTED_PUBLISHERS
    
    def analyze(self, cert_info: Dict[str, Any]) -> CertificateAnalysisResult:
        """
        Analyze certificate information from APK.
        
        Args:
            cert_info: Certificate data from APK parser
            
        Returns:
            CertificateAnalysisResult with trust assessment
        """
        result = CertificateAnalysisResult()
        
        if not cert_info:
            result.warnings.append("No certificate information available")
            result.risk_score = 80
            result.trust_level = CertificateTrustLevel.UNTRUSTED
            return result
        
        # Check if signed
        result.is_signed = cert_info.get("is_signed", False)
        result.signature_version = cert_info.get("signature_version")
        
        if not result.is_signed:
            result.warnings.append("APK is not signed - cannot verify authenticity")
            result.risk_score = 100
            result.trust_level = CertificateTrustLevel.UNTRUSTED
            return result
        
        # Analyze certificates
        certificates = cert_info.get("certificates", [])
        if certificates:
            cert = certificates[0]  # Primary certificate
            result.issuer = cert.get("issuer", "")
            result.subject = cert.get("subject", "")
            result.serial_number = cert.get("serial_number", "")
            result.valid_from = cert.get("not_valid_before")
            result.valid_until = cert.get("not_valid_after")
            
            # Check for debug certificate
            result.is_debug_signed = self._is_debug_certificate(result.issuer, result.subject)
            
            # Check if self-signed
            result.is_self_signed = self._is_self_signed(result.issuer, result.subject)
            
            # Check expiration
            result.is_expired = self._is_expired(result.valid_until)
        
        # Calculate fingerprint if raw cert data available
        # result.fingerprint_sha256 = self._calculate_fingerprint(cert_data)
        
        # Generate warnings
        result.warnings = self._generate_warnings(result)
        
        # Calculate risk score and trust level
        result.risk_score = self._calculate_risk_score(result)
        result.trust_level = self._determine_trust_level(result)
        
        return result
    
    def _is_debug_certificate(self, issuer: str, subject: str) -> bool:
        """Check if certificate matches debug patterns"""
        combined = f"{issuer} {subject}".lower()
        for pattern in self.debug_patterns:
            if pattern.lower() in combined:
                return True
        return False
    
    def _is_self_signed(self, issuer: str, subject: str) -> bool:
        """Check if certificate is self-signed"""
        # Basic check: issuer equals subject
        if issuer and subject:
            return issuer.strip() == subject.strip()
        return True  # Assume self-signed if can't determine
    
    def _is_expired(self, valid_until: Optional[str]) -> bool:
        """Check if certificate has expired"""
        if not valid_until:
            return False
        try:
            # Try common date formats
            for fmt in ["%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%d"]:
                try:
                    expiry = datetime.strptime(valid_until[:19], fmt)
                    return datetime.now() > expiry
                except ValueError:
                    continue
        except Exception:
            pass
        return False
    
    def _generate_warnings(self, result: CertificateAnalysisResult) -> List[str]:
        """Generate human-readable warnings"""
        warnings = []
        
        if result.is_debug_signed:
            warnings.append(
                "⚠️ SIGNED WITH DEBUG CERTIFICATE - This is NOT a production release. "
                "Debug certificates are used during development and should never be "
                "used for apps distributed to users."
            )
        
        if result.is_self_signed and not result.is_debug_signed:
            warnings.append(
                "⚠️ Self-signed certificate detected. This is common for independent "
                "developers but means the publisher's identity cannot be verified "
                "through a certificate authority."
            )
        
        if result.is_expired:
            warnings.append(
                "⚠️ Certificate has EXPIRED. The app may not function correctly "
                "and updates may not be installable."
            )
        
        if result.signature_version == "v1":
            warnings.append(
                "ℹ️ Using older v1 signature scheme. Newer v2/v3 schemes provide "
                "better tamper detection."
            )
        
        return warnings
    
    def _calculate_risk_score(self, result: CertificateAnalysisResult) -> int:
        """Calculate certificate risk score (0-100)"""
        score = 0
        
        if not result.is_signed:
            return 100
        
        if result.is_debug_signed:
            score += 60  # Very high risk
        
        if result.is_self_signed:
            score += 20  # Moderate risk
        
        if result.is_expired:
            score += 30  # High risk
        
        if result.signature_version == "v1":
            score += 10  # Minor risk
        
        return min(score, 100)
    
    def _determine_trust_level(self, result: CertificateAnalysisResult) -> CertificateTrustLevel:
        """Determine overall trust level"""
        if result.risk_score >= 70:
            return CertificateTrustLevel.UNTRUSTED
        elif result.risk_score >= 40:
            return CertificateTrustLevel.SUSPICIOUS
        elif result.risk_score >= 20:
            return CertificateTrustLevel.UNKNOWN
        else:
            return CertificateTrustLevel.TRUSTED
    
    def check_repackaging(
        self, 
        package_name: str, 
        cert_fingerprint: str,
        known_packages: Dict[str, str] = None
    ) -> Dict[str, Any]:
        """
        Check for potential repackaging of known apps.
        
        Args:
            package_name: App package name
            cert_fingerprint: Certificate SHA256 fingerprint
            known_packages: Dict of known package names to expected cert fingerprints
            
        Returns:
            Repackaging assessment
        """
        result = {
            "is_potential_repackage": False,
            "original_publisher": None,
            "warning": None
        }
        
        if known_packages is None:
            # Example known packages - in production, use maintained database
            known_packages = {
                "com.whatsapp": "expected_fingerprint_here",
                "com.google.android.apps.banking": "expected_fingerprint_here",
                # etc.
            }
        
        # Check if package name matches known app but cert differs
        if package_name in known_packages:
            expected_fp = known_packages[package_name]
            if cert_fingerprint != expected_fp:
                result["is_potential_repackage"] = True
                result["warning"] = (
                    f"⚠️ POTENTIAL REPACKAGED APP: Package name '{package_name}' "
                    f"matches a known app but the signing certificate is different. "
                    f"This could indicate a trojaned/modified version of the app."
                )
        
        # Check for similar package names (typosquatting)
        for known_pkg in known_packages.keys():
            if self._is_typosquat(package_name, known_pkg):
                result["is_potential_repackage"] = True
                result["warning"] = (
                    f"⚠️ POTENTIAL TYPOSQUAT: Package name '{package_name}' "
                    f"is suspiciously similar to '{known_pkg}'. "
                    f"This could be an attempt to impersonate a legitimate app."
                )
                break
        
        return result
    
    def _is_typosquat(self, package1: str, package2: str) -> bool:
        """Check if package names are suspiciously similar (potential typosquatting)"""
        if package1 == package2:
            return False
        
        # Simple Levenshtein-like check
        if len(package1) != len(package2):
            if abs(len(package1) - len(package2)) <= 2:
                # Check character overlap
                set1, set2 = set(package1), set(package2)
                overlap = len(set1 & set2) / max(len(set1), len(set2))
                if overlap > 0.85:
                    return True
        else:
            # Same length - check character differences
            diff_count = sum(1 for a, b in zip(package1, package2) if a != b)
            if diff_count <= 2:
                return True
        
        return False
