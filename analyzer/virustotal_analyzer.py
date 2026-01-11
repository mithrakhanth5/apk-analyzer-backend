"""
VirusTotal Sandbox Analyzer
Integrates with VirusTotal API for sandbox-based APK inspection.
"""
import os
import hashlib
import asyncio
import aiohttp
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
from enum import Enum


class SandboxThreatLevel(Enum):
    """Threat levels from sandbox analysis"""
    CLEAN = "clean"
    UNDETECTED = "undetected"
    SUSPICIOUS = "suspicious"
    MALICIOUS = "malicious"


@dataclass
class SandboxBehavior:
    """Sandbox behavior indicators"""
    files_written: List[str] = field(default_factory=list)
    files_deleted: List[str] = field(default_factory=list)
    processes_created: List[str] = field(default_factory=list)
    network_connections: List[str] = field(default_factory=list)
    registry_keys_set: List[str] = field(default_factory=list)
    permissions_requested: List[str] = field(default_factory=list)
    suspicious_actions: List[str] = field(default_factory=list)


@dataclass
class VirusTotalResult:
    """Result from VirusTotal analysis"""
    file_hash: str
    detection_ratio: str  # e.g., "5/72"
    positives: int
    total_scanners: int
    threat_level: SandboxThreatLevel
    malware_names: List[str] = field(default_factory=list)
    sandbox_behavior: Optional[SandboxBehavior] = None
    scan_date: str = ""
    permalink: str = ""
    is_cached: bool = False
    error_message: str = ""
    risk_score: int = 0  # 0-100 based on detections
    warnings: List[str] = field(default_factory=list)


class VirusTotalAnalyzer:
    """
    Analyzer that integrates with VirusTotal for sandbox-based inspection.
    
    Features:
    - File hash lookup (instant results for known files)
    - Sandbox behavior analysis
    - Multi-engine antivirus scan results
    """
    
    # VirusTotal API configuration
    # Users should set their own API key via environment variable
    API_KEY = os.environ.get("VIRUSTOTAL_API_KEY", "")
    BASE_URL = "https://www.virustotal.com/api/v3"
    
    def __init__(self, api_key: Optional[str] = None):
        """Initialize with optional API key override"""
        if api_key:
            self.api_key = api_key
        else:
            self.api_key = self.API_KEY
    
    def _get_headers(self) -> Dict[str, str]:
        """Get API request headers"""
        return {
            "x-apikey": self.api_key,
            "Accept": "application/json"
        }
    
    async def analyze_hash(self, file_hash: str) -> VirusTotalResult:
        """
        Analyze a file by its hash (SHA256, SHA1, or MD5).
        This is the fastest method as it uses cached results.
        """
        if not self.api_key:
            return self._create_no_api_result(file_hash)
        
        try:
            async with aiohttp.ClientSession() as session:
                # Check file report by hash
                url = f"{self.BASE_URL}/files/{file_hash}"
                async with session.get(url, headers=self._get_headers()) as response:
                    if response.status == 404:
                        return self._create_not_found_result(file_hash)
                    elif response.status == 401:
                        return self._create_auth_error_result(file_hash)
                    elif response.status != 200:
                        return self._create_error_result(file_hash, f"API error: {response.status}")
                    
                    data = await response.json()
                    return self._parse_file_report(file_hash, data)
                    
        except asyncio.TimeoutError:
            return self._create_error_result(file_hash, "Request timed out")
        except Exception as e:
            return self._create_error_result(file_hash, str(e))
    
    async def analyze_bytes(self, file_bytes: bytes, file_hash: str) -> VirusTotalResult:
        """
        Analyze file bytes. First checks by hash, uploads if not found.
        Note: Uploading requires a premium API key for large files.
        """
        # First try hash lookup (faster, uses cached results)
        result = await self.analyze_hash(file_hash)
        
        # If file is not in VT database and we have API access, we could upload
        # But for free tier, we just return the not-found result
        if result.error_message == "File not found in VirusTotal database":
            result.warnings.append("File not previously scanned by VirusTotal")
            result.warnings.append("For new files, manual upload to virustotal.com recommended")
        
        return result
    
    async def get_behavior_report(self, file_hash: str) -> Optional[SandboxBehavior]:
        """
        Get sandbox behavior report for a file.
        """
        if not self.api_key:
            return None
        
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.BASE_URL}/files/{file_hash}/behaviours"
                async with session.get(url, headers=self._get_headers()) as response:
                    if response.status != 200:
                        return None
                    
                    data = await response.json()
                    return self._parse_behavior_report(data)
                    
        except Exception:
            return None
    
    def _parse_file_report(self, file_hash: str, data: Dict[str, Any]) -> VirusTotalResult:
        """Parse VirusTotal file report response"""
        attributes = data.get("data", {}).get("attributes", {})
        stats = attributes.get("last_analysis_stats", {})
        
        positives = stats.get("malicious", 0) + stats.get("suspicious", 0)
        total = sum(stats.values()) if stats else 0
        
        # Determine threat level
        if positives == 0:
            threat_level = SandboxThreatLevel.CLEAN
        elif positives <= 3:
            threat_level = SandboxThreatLevel.UNDETECTED
        elif positives <= 10:
            threat_level = SandboxThreatLevel.SUSPICIOUS
        else:
            threat_level = SandboxThreatLevel.MALICIOUS
        
        # Extract malware names from positive detections
        malware_names = []
        results = attributes.get("last_analysis_results", {})
        for engine, result in results.items():
            if result.get("category") in ["malicious", "suspicious"]:
                if result.get("result"):
                    malware_names.append(f"{engine}: {result['result']}")
        
        # Calculate risk score (0-100)
        if total > 0:
            risk_score = min(100, int((positives / total) * 100 * 3))  # Amplify for sensitivity
        else:
            risk_score = 0
        
        # Generate warnings
        warnings = []
        if positives > 0:
            warnings.append(f"Detected by {positives} security vendors")
        if threat_level == SandboxThreatLevel.MALICIOUS:
            warnings.append("HIGH RISK: Multiple antivirus engines flagged this file")
        
        return VirusTotalResult(
            file_hash=file_hash,
            detection_ratio=f"{positives}/{total}",
            positives=positives,
            total_scanners=total,
            threat_level=threat_level,
            malware_names=malware_names[:10],  # Limit to 10
            scan_date=attributes.get("last_analysis_date", ""),
            permalink=f"https://www.virustotal.com/gui/file/{file_hash}",
            is_cached=True,
            risk_score=risk_score,
            warnings=warnings
        )
    
    def _parse_behavior_report(self, data: Dict[str, Any]) -> SandboxBehavior:
        """Parse behavior/sandbox report"""
        behavior = SandboxBehavior()
        
        for item in data.get("data", []):
            attrs = item.get("attributes", {})
            
            # Extract various behavior indicators
            behavior.files_written.extend(attrs.get("files_written", [])[:10])
            behavior.files_deleted.extend(attrs.get("files_deleted", [])[:10])
            behavior.processes_created.extend(attrs.get("processes_created", [])[:10])
            
            # Network connections
            for conn in attrs.get("ip_traffic", [])[:10]:
                behavior.network_connections.append(
                    f"{conn.get('destination_ip', 'unknown')}:{conn.get('destination_port', '')}"
                )
            
            # Android-specific: permissions
            behavior.permissions_requested.extend(
                attrs.get("permissions_requested", [])[:20]
            )
            
            # Suspicious actions
            for tag in attrs.get("tags", []):
                if tag not in behavior.suspicious_actions:
                    behavior.suspicious_actions.append(tag)
        
        return behavior
    
    def _create_no_api_result(self, file_hash: str) -> VirusTotalResult:
        """Create result when no API key is configured"""
        return VirusTotalResult(
            file_hash=file_hash,
            detection_ratio="N/A",
            positives=0,
            total_scanners=0,
            threat_level=SandboxThreatLevel.UNDETECTED,
            error_message="VirusTotal API key not configured",
            warnings=["Sandbox analysis unavailable - API key required"],
            risk_score=0
        )
    
    def _create_not_found_result(self, file_hash: str) -> VirusTotalResult:
        """Create result when file is not in VT database"""
        return VirusTotalResult(
            file_hash=file_hash,
            detection_ratio="0/0",
            positives=0,
            total_scanners=0,
            threat_level=SandboxThreatLevel.UNDETECTED,
            error_message="File not found in VirusTotal database",
            warnings=["This APK has not been scanned before"],
            risk_score=0
        )
    
    def _create_auth_error_result(self, file_hash: str) -> VirusTotalResult:
        """Create result for authentication error"""
        return VirusTotalResult(
            file_hash=file_hash,
            detection_ratio="N/A",
            positives=0,
            total_scanners=0,
            threat_level=SandboxThreatLevel.UNDETECTED,
            error_message="Invalid VirusTotal API key",
            warnings=["Sandbox analysis failed - check API key"],
            risk_score=0
        )
    
    def _create_error_result(self, file_hash: str, error: str) -> VirusTotalResult:
        """Create result for general errors"""
        return VirusTotalResult(
            file_hash=file_hash,
            detection_ratio="N/A",
            positives=0,
            total_scanners=0,
            threat_level=SandboxThreatLevel.UNDETECTED,
            error_message=error,
            warnings=[f"Sandbox analysis error: {error}"],
            risk_score=0
        )


# Simulated sandbox for when VT API is not available
class LocalSandboxSimulator:
    """
    Simulates basic sandbox behavior analysis using static indicators.
    This provides sandbox-like results without requiring external API.
    """
    
    # Suspicious patterns that indicate potential malicious behavior
    SUSPICIOUS_PATTERNS = {
        "dynamic_loading": [
            "DexClassLoader", "PathClassLoader", "dalvik.system",
            "loadClass", "defineClass"
        ],
        "reflection": [
            "java.lang.reflect", "invoke", "getMethod", "getDeclaredMethod"
        ],
        "native_code": [
            "System.loadLibrary", "System.load", "native-lib", ".so"
        ],
        "crypto": [
            "javax.crypto", "Cipher", "AES", "DES", "RSA", "encrypt", "decrypt"
        ],
        "network": [
            "HttpURLConnection", "OkHttp", "Retrofit", "Socket", "URLConnection"
        ],
        "sms": [
            "SmsManager", "sendTextMessage", "RECEIVE_SMS", "READ_SMS"
        ],
        "device_admin": [
            "DeviceAdminReceiver", "DevicePolicyManager", "BIND_DEVICE_ADMIN"
        ],
        "overlay": [
            "SYSTEM_ALERT_WINDOW", "TYPE_APPLICATION_OVERLAY", "draw over"
        ],
        "accessibility": [
            "AccessibilityService", "BIND_ACCESSIBILITY_SERVICE"
        ],
        "root": [
            "su", "Superuser", "root", "/system/xbin", "busybox"
        ]
    }
    
    def analyze(self, dex_classes: List[str], permissions: List[str]) -> Dict[str, Any]:
        """
        Perform simulated sandbox analysis based on static indicators.
        """
        findings = {
            "category": "Sandbox Simulation",
            "behaviors_detected": [],
            "risk_indicators": [],
            "risk_score": 0
        }
        
        all_strings = " ".join(dex_classes).lower()
        
        for category, patterns in self.SUSPICIOUS_PATTERNS.items():
            for pattern in patterns:
                if pattern.lower() in all_strings:
                    findings["behaviors_detected"].append({
                        "type": category,
                        "indicator": pattern,
                        "severity": self._get_severity(category)
                    })
                    findings["risk_score"] += self._get_score(category)
        
        # Check permissions for sandbox-relevant behaviors
        dangerous_runtime = [
            "CAMERA", "RECORD_AUDIO", "ACCESS_FINE_LOCATION",
            "READ_CONTACTS", "READ_SMS", "CALL_PHONE"
        ]
        
        for perm in permissions:
            perm_upper = perm.upper()
            for dangerous in dangerous_runtime:
                if dangerous in perm_upper:
                    findings["risk_indicators"].append(f"Runtime permission: {dangerous}")
                    findings["risk_score"] += 5
        
        findings["risk_score"] = min(100, findings["risk_score"])
        
        return findings
    
    def _get_severity(self, category: str) -> str:
        """Get severity level for a behavior category"""
        high_risk = ["device_admin", "accessibility", "root", "sms"]
        medium_risk = ["dynamic_loading", "overlay", "native_code"]
        
        if category in high_risk:
            return "HIGH"
        elif category in medium_risk:
            return "MEDIUM"
        return "LOW"
    
    def _get_score(self, category: str) -> int:
        """Get risk score contribution for a category"""
        scores = {
            "device_admin": 25,
            "accessibility": 25,
            "root": 30,
            "sms": 20,
            "dynamic_loading": 15,
            "overlay": 15,
            "native_code": 10,
            "reflection": 5,
            "crypto": 5,
            "network": 3
        }
        return scores.get(category, 5)
