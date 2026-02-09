"""
Risk Engine Module
Combines all analysis results into a weighted risk score with explainability.
"""
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from enum import Enum

from .permission_analyzer import PermissionAnalysisResult
from .certificate_analyzer import CertificateAnalysisResult
from .obfuscation_detector import ObfuscationAnalysisResult
from .network_extractor import NetworkAnalysisResult


class RiskClassification(str, Enum):
    SAFE = "SAFE"
    SUSPICIOUS = "SUSPICIOUS"
    HIGH_RISK = "HIGH_RISK"


@dataclass
class RiskFinding:
    """Individual risk finding with explanation"""
    category: str  # PERMISSION, CERTIFICATE, OBFUSCATION, NETWORK, COMPONENT
    severity: str  # LOW, MEDIUM, HIGH, CRITICAL
    title: str
    description: str
    evidence: List[str] = field(default_factory=list)
    score_impact: int = 0
    recommendation: str = ""


@dataclass
class RiskReport:
    """Complete risk assessment report"""
    # APK Info
    package_name: str = ""
    version_name: str = ""
    app_name: str = ""
    file_hash: str = ""
    
    # Scores
    overall_score: int = 0  # 0-100
    classification: RiskClassification = RiskClassification.SAFE
    
    # Component scores
    permission_score: int = 0
    certificate_score: int = 0
    obfuscation_score: int = 0
    network_score: int = 0
    component_score: int = 0
    
    # Findings
    findings: List[RiskFinding] = field(default_factory=list)
    critical_findings: List[RiskFinding] = field(default_factory=list)
    
    # Summary
    summary: str = ""
    recommendation: str = ""
    
    # Limitations
    limitations: List[str] = field(default_factory=list)


# Weight configuration for risk calculation
RISK_WEIGHTS = {
    "permission": 0.35,
    "certificate": 0.25,
    "obfuscation": 0.20,
    "network": 0.10,
    "component": 0.10,
}

# Classification thresholds
CLASSIFICATION_THRESHOLDS = {
    "safe": 30,
    "suspicious": 60,
    # Above 60 = HIGH_RISK
}


class RiskEngine:
    """
    Combines analysis results into a comprehensive risk assessment.
    Provides explainable, deterministic scoring.
    """
    
    def __init__(self, weights: Dict[str, float] = None):
        self.weights = weights or RISK_WEIGHTS
        self.thresholds = CLASSIFICATION_THRESHOLDS
    
    def calculate_risk(
        self,
        package_name: str,
        version_name: str,
        app_name: str,
        file_hash: str,
        permission_result: PermissionAnalysisResult,
        certificate_result: CertificateAnalysisResult,
        obfuscation_result: ObfuscationAnalysisResult,
        network_result: NetworkAnalysisResult,
        components: Dict[str, List[str]] = None
    ) -> RiskReport:
        """
        Calculate comprehensive risk score from all analysis components.
        
        Returns:
            RiskReport with complete assessment and explanations
        """
        report = RiskReport(
            package_name=package_name,
            version_name=version_name,
            app_name=app_name,
            file_hash=file_hash
        )
        
        # Store component scores
        report.permission_score = permission_result.overall_score
        report.certificate_score = certificate_result.risk_score
        report.obfuscation_score = obfuscation_result.obfuscation_score
        report.network_score = network_result.risk_score
        report.component_score = self._calculate_component_score(components or {})
        
        # Generate findings from each component
        report.findings.extend(self._generate_permission_findings(permission_result))
        report.findings.extend(self._generate_certificate_findings(certificate_result))
        report.findings.extend(self._generate_obfuscation_findings(obfuscation_result))
        report.findings.extend(self._generate_network_findings(network_result))
        report.findings.extend(self._generate_component_findings(components or {}))
        
        # Identify critical findings
        report.critical_findings = [
            f for f in report.findings if f.severity == "CRITICAL"
        ]
        
        # Calculate weighted overall score
        report.overall_score = self._calculate_weighted_score(report)
        
        # Determine classification
        report.classification = self._classify_risk(report.overall_score)
        
        # Generate summary and recommendation
        report.summary = self._generate_summary(report)
        report.recommendation = self._generate_recommendation(report)
        
        # Add limitations disclaimer
        report.limitations = self._get_limitations()
        
        return report
    
    def _calculate_component_score(self, components: Dict[str, List[str]]) -> int:
        """Calculate risk score from manifest components"""
        score = 0
        
        # Check for suspicious services
        services = components.get("services", [])
        for service in services:
            if "accessibility" in service.lower():
                score += 30
            if "device" in service.lower() and "admin" in service.lower():
                score += 30
        
        # Check for suspicious receivers
        receivers = components.get("receivers", [])
        suspicious_receivers = [
            "SMS_RECEIVED", "BOOT_COMPLETED", "PACKAGE_ADDED",
            "NEW_OUTGOING_CALL"
        ]
        for receiver in receivers:
            for sus in suspicious_receivers:
                if sus in receiver.upper():
                    score += 10
                    break
        
        return min(score, 100)
    
    def _calculate_weighted_score(self, report: RiskReport) -> int:
        """Calculate weighted overall score"""
        weighted_sum = (
            report.permission_score * self.weights["permission"] +
            report.certificate_score * self.weights["certificate"] +
            report.obfuscation_score * self.weights["obfuscation"] +
            report.network_score * self.weights["network"] +
            report.component_score * self.weights["component"]
        )
        
        # Boost for critical findings
        critical_boost = len(report.critical_findings) * 10
        
        return min(int(weighted_sum + critical_boost), 100)
    
    def _classify_risk(self, score: int) -> RiskClassification:
        """Classify risk level based on score"""
        if score <= self.thresholds["safe"]:
            return RiskClassification.SAFE
        elif score <= self.thresholds["suspicious"]:
            return RiskClassification.SUSPICIOUS
        else:
            return RiskClassification.HIGH_RISK
    
    def _generate_permission_findings(
        self, 
        result: PermissionAnalysisResult
    ) -> List[RiskFinding]:
        """Generate findings from permission analysis"""
        findings = []
        
        # Critical permission combinations
        for combo in result.combination_risks:
            findings.append(RiskFinding(
                category="PERMISSION",
                severity="CRITICAL" if combo.risk_score >= 9 else "HIGH",
                title=f"Risky Permission Combination: {combo.threat_type}",
                description=combo.description,
                evidence=combo.permissions,
                score_impact=combo.risk_score * 3,
                recommendation="Review if this app legitimately needs these permissions together"
            ))
        
        # Individual dangerous permissions
        for perm in result.permission_risks:
            if perm.risk_score >= 8:
                findings.append(RiskFinding(
                    category="PERMISSION",
                    severity="HIGH",
                    title=f"High-Risk Permission: {perm.permission.split('.')[-1]}",
                    description=perm.description,
                    evidence=[perm.permission],
                    score_impact=perm.risk_score,
                    recommendation="Verify this permission is necessary for app functionality"
                ))
        
        return findings
    
    def _generate_certificate_findings(
        self,
        result: CertificateAnalysisResult
    ) -> List[RiskFinding]:
        """Generate findings from certificate analysis"""
        findings = []
        
        if not result.is_signed:
            findings.append(RiskFinding(
                category="CERTIFICATE",
                severity="CRITICAL",
                title="APK Not Signed",
                description="This APK is not digitally signed, meaning its authenticity cannot be verified",
                evidence=[],
                score_impact=40,
                recommendation="DO NOT install unsigned APKs"
            ))
            return findings
        
        if result.is_debug_signed:
            findings.append(RiskFinding(
                category="CERTIFICATE",
                severity="CRITICAL",
                title="Debug Certificate Detected",
                description="This APK is signed with a debug certificate, not intended for distribution",
                evidence=["Issuer: " + result.issuer],
                score_impact=30,
                recommendation="Only install APKs signed with release certificates from trusted sources"
            ))
        
        if result.is_expired:
            findings.append(RiskFinding(
                category="CERTIFICATE",
                severity="HIGH",
                title="Expired Certificate",
                description="The signing certificate has expired",
                evidence=[f"Valid until: {result.valid_until}"],
                score_impact=20,
                recommendation="The app may not receive updates and could have security issues"
            ))
        
        for warning in result.warnings:
            if warning not in [f.description for f in findings]:
                findings.append(RiskFinding(
                    category="CERTIFICATE",
                    severity="MEDIUM",
                    title="Certificate Warning",
                    description=warning,
                    evidence=[],
                    score_impact=5
                ))
        
        return findings
    
    def _generate_obfuscation_findings(
        self,
        result: ObfuscationAnalysisResult
    ) -> List[RiskFinding]:
        """Generate findings from obfuscation analysis"""
        findings = []
        
        if result.obfuscation_score >= 70:
            findings.append(RiskFinding(
                category="OBFUSCATION",
                severity="MEDIUM",
                title="Heavy Code Obfuscation",
                description=(
                    "The app code is heavily obfuscated. While not inherently malicious "
                    "(many legitimate apps use obfuscation), combined with other risk "
                    "factors this could indicate an attempt to hide malicious behavior."
                ),
                evidence=result.sample_obfuscated_names[:5],
                score_impact=15,
                recommendation="Consider the source of this APK carefully"
            ))
        elif result.obfuscation_score >= 40:
            findings.append(RiskFinding(
                category="OBFUSCATION",
                severity="LOW",
                title="Moderate Obfuscation Detected",
                description=(
                    "Standard code obfuscation detected (likely ProGuard). "
                    "This is common and normal for production Android apps."
                ),
                evidence=[f"Obfuscation type: {result.obfuscation_type}"],
                score_impact=0,
                recommendation="No action needed - this is normal"
            ))
        
        return findings
    
    def _generate_network_findings(
        self,
        result: NetworkAnalysisResult
    ) -> List[RiskFinding]:
        """Generate findings from network analysis"""
        findings = []
        
        for endpoint in result.suspicious_endpoints:
            findings.append(RiskFinding(
                category="NETWORK",
                severity="HIGH",
                title="Suspicious Network Endpoint",
                description=f"Found suspicious endpoint that may be used for malicious communication",
                evidence=[endpoint.url],
                score_impact=15,
                recommendation="Verify this is a legitimate server for the app"
            ))
        
        if result.https_ratio < 0.5 and result.total_endpoints > 3:
            findings.append(RiskFinding(
                category="NETWORK",
                severity="MEDIUM",
                title="Insecure Network Communication",
                description=f"Only {result.https_ratio:.0%} of endpoints use HTTPS encryption",
                evidence=[f"{result.total_endpoints} endpoints found"],
                score_impact=10,
                recommendation="Your data may be transmitted insecurely"
            ))
        
        return findings
    
    def _generate_component_findings(
        self,
        components: Dict[str, List[str]]
    ) -> List[RiskFinding]:
        """Generate findings from component analysis"""
        findings = []
        
        services = components.get("services", [])
        for service in services:
            if "accessibility" in service.lower():
                findings.append(RiskFinding(
                    category="COMPONENT",
                    severity="CRITICAL",
                    title="Accessibility Service Detected",
                    description=(
                        "This app registers an accessibility service, giving it the ability "
                        "to monitor all content on screen and user interactions. This is "
                        "often abused by malware for keylogging and credential theft."
                    ),
                    evidence=[service],
                    score_impact=25,
                    recommendation="Only grant accessibility permissions to apps you fully trust"
                ))
        
        receivers = components.get("receivers", [])
        sms_receivers = [r for r in receivers if "SMS" in r.upper()]
        if sms_receivers:
            findings.append(RiskFinding(
                category="COMPONENT",
                severity="HIGH",
                title="SMS Receiver Detected",
                description="This app can intercept incoming SMS messages including OTPs and verification codes",
                evidence=sms_receivers,
                score_impact=15,
                recommendation="Verify this is a legitimate messaging or security app"
            ))
        
        return findings
    
    def _generate_summary(self, report: RiskReport) -> str:
        """Generate human-readable summary"""
        if report.classification == RiskClassification.SAFE:
            return (
                f"'{report.app_name}' appears to have LOW RISK based on static analysis. "
                f"No critical security concerns were identified."
            )
        elif report.classification == RiskClassification.SUSPICIOUS:
            return (
                f"'{report.app_name}' has MODERATE RISK indicators. "
                f"Found {len(report.findings)} potential concerns that warrant review. "
                f"Proceed with caution."
            )
        else:
            critical_count = len(report.critical_findings)
            return (
                f"⚠️ '{report.app_name}' has HIGH RISK indicators. "
                f"Found {critical_count} critical issue(s) and {len(report.findings)} total concerns. "
                f"Installing this app could compromise your device security."
            )
    
    def _generate_recommendation(self, report: RiskReport) -> str:
        """Generate actionable recommendation"""
        if report.classification == RiskClassification.SAFE:
            return (
                "Based on static analysis, this app appears safe to install. "
                "However, always prefer downloading apps from official sources like Google Play Store."
            )
        elif report.classification == RiskClassification.SUSPICIOUS:
            return (
                "Review the findings carefully before installing. If you don't recognize "
                "the publisher or downloaded from an unofficial source, consider finding "
                "an alternative from a trusted source."
            )
        else:
            return (
                "⛔ RECOMMENDATION: Do NOT install this app unless you fully trust the source "
                "and understand the risks. The security indicators suggest this app could be "
                "malicious or significantly compromise your privacy and security."
            )
    
    def _get_limitations(self) -> List[str]:
        """Return explicit limitations of the analysis"""
        return [
            "Static analysis only - runtime behavior is not observed",
            "Cannot detect dynamically loaded or encrypted malicious code",
            "Cannot identify zero-day exploits or unknown malware families",
            "Risk scores are heuristic estimates, not definitive verdicts",
            "False positives are possible for legitimate apps with unusual requirements",
            "This tool provides advisory information only, not security guarantees"
        ]
