"""
Permission Analyzer Module
Classifies and scores Android permissions for security risk assessment.
"""
from typing import Dict, List, Tuple, Any
from dataclasses import dataclass, field
from enum import Enum


class RiskLevel(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"


class PermissionCategory(str, Enum):
    PRIVACY = "privacy"
    FINANCIAL = "financial"
    DEVICE_CONTROL = "device_control"
    NETWORK = "network"
    STORAGE = "storage"
    LOCATION = "location"
    CONTACTS = "contacts"
    PHONE = "phone"
    SMS = "sms"
    CAMERA = "camera"
    MICROPHONE = "microphone"
    ACCESSIBILITY = "accessibility"
    SYSTEM = "system"
    OTHER = "other"


@dataclass
class PermissionRisk:
    """Individual permission risk assessment"""
    permission: str
    risk_score: int  # 0-10
    risk_level: RiskLevel
    category: PermissionCategory
    description: str
    is_dangerous: bool = False
    is_signature: bool = False


@dataclass
class CombinationRisk:
    """Risk from permission combinations"""
    permissions: List[str]
    threat_type: str
    risk_score: int
    description: str


@dataclass
class PermissionAnalysisResult:
    """Complete permission analysis result"""
    total_permissions: int = 0
    dangerous_count: int = 0
    permission_risks: List[PermissionRisk] = field(default_factory=list)
    combination_risks: List[CombinationRisk] = field(default_factory=list)
    overall_score: int = 0  # 0-100
    summary: str = ""


# Comprehensive dangerous permissions database
DANGEROUS_PERMISSIONS: Dict[str, Dict[str, Any]] = {
    # SMS - High risk for OTP theft
    "android.permission.READ_SMS": {
        "risk": 9, "category": PermissionCategory.SMS,
        "description": "Can read all SMS messages including OTPs and verification codes"
    },
    "android.permission.SEND_SMS": {
        "risk": 10, "category": PermissionCategory.FINANCIAL,
        "description": "Can send SMS messages, potentially to premium services"
    },
    "android.permission.RECEIVE_SMS": {
        "risk": 9, "category": PermissionCategory.SMS,
        "description": "Can intercept incoming SMS messages"
    },
    
    # Phone
    "android.permission.READ_PHONE_STATE": {
        "risk": 6, "category": PermissionCategory.PHONE,
        "description": "Can read device identifiers and phone state"
    },
    "android.permission.CALL_PHONE": {
        "risk": 7, "category": PermissionCategory.FINANCIAL,
        "description": "Can make phone calls without user interaction"
    },
    "android.permission.READ_CALL_LOG": {
        "risk": 8, "category": PermissionCategory.PRIVACY,
        "description": "Can read call history"
    },
    "android.permission.PROCESS_OUTGOING_CALLS": {
        "risk": 8, "category": PermissionCategory.PHONE,
        "description": "Can intercept and redirect outgoing calls"
    },
    
    # Contacts
    "android.permission.READ_CONTACTS": {
        "risk": 7, "category": PermissionCategory.CONTACTS,
        "description": "Can read all contacts and personal information"
    },
    "android.permission.WRITE_CONTACTS": {
        "risk": 6, "category": PermissionCategory.CONTACTS,
        "description": "Can modify or delete contacts"
    },
    
    # Location
    "android.permission.ACCESS_FINE_LOCATION": {
        "risk": 7, "category": PermissionCategory.LOCATION,
        "description": "Can track precise GPS location"
    },
    "android.permission.ACCESS_COARSE_LOCATION": {
        "risk": 5, "category": PermissionCategory.LOCATION,
        "description": "Can track approximate location"
    },
    "android.permission.ACCESS_BACKGROUND_LOCATION": {
        "risk": 9, "category": PermissionCategory.LOCATION,
        "description": "Can track location even when app is not in use"
    },
    
    # Camera & Microphone
    "android.permission.CAMERA": {
        "risk": 7, "category": PermissionCategory.CAMERA,
        "description": "Can access camera to take photos/videos"
    },
    "android.permission.RECORD_AUDIO": {
        "risk": 8, "category": PermissionCategory.MICROPHONE,
        "description": "Can record audio through microphone"
    },
    
    # Storage
    "android.permission.READ_EXTERNAL_STORAGE": {
        "risk": 6, "category": PermissionCategory.STORAGE,
        "description": "Can read files from external storage"
    },
    "android.permission.WRITE_EXTERNAL_STORAGE": {
        "risk": 6, "category": PermissionCategory.STORAGE,
        "description": "Can write/modify files on external storage"
    },
    "android.permission.MANAGE_EXTERNAL_STORAGE": {
        "risk": 9, "category": PermissionCategory.STORAGE,
        "description": "Has broad file access to all files"
    },
    
    # Network
    "android.permission.INTERNET": {
        "risk": 3, "category": PermissionCategory.NETWORK,
        "description": "Can access the internet"
    },
    "android.permission.ACCESS_NETWORK_STATE": {
        "risk": 2, "category": PermissionCategory.NETWORK,
        "description": "Can view network connectivity"
    },
    
    # Accessibility - Very high risk
    "android.permission.BIND_ACCESSIBILITY_SERVICE": {
        "risk": 10, "category": PermissionCategory.ACCESSIBILITY,
        "description": "Can monitor and interact with all app content - HIGH ABUSE POTENTIAL"
    },
    
    # Device Admin
    "android.permission.BIND_DEVICE_ADMIN": {
        "risk": 10, "category": PermissionCategory.DEVICE_CONTROL,
        "description": "Can become device administrator with extensive control"
    },
    
    # System
    "android.permission.SYSTEM_ALERT_WINDOW": {
        "risk": 8, "category": PermissionCategory.SYSTEM,
        "description": "Can draw overlays on top of other apps"
    },
    "android.permission.REQUEST_INSTALL_PACKAGES": {
        "risk": 9, "category": PermissionCategory.SYSTEM,
        "description": "Can request to install other applications"
    },
    "android.permission.RECEIVE_BOOT_COMPLETED": {
        "risk": 4, "category": PermissionCategory.SYSTEM,
        "description": "Starts automatically when device boots"
    },
    "android.permission.FOREGROUND_SERVICE": {
        "risk": 3, "category": PermissionCategory.SYSTEM,
        "description": "Can run persistent background services"
    },
    "android.permission.WAKE_LOCK": {
        "risk": 3, "category": PermissionCategory.SYSTEM,
        "description": "Can prevent device from sleeping"
    },
    "android.permission.DISABLE_KEYGUARD": {
        "risk": 7, "category": PermissionCategory.DEVICE_CONTROL,
        "description": "Can disable lock screen"
    },
    
    # Accounts
    "android.permission.GET_ACCOUNTS": {
        "risk": 6, "category": PermissionCategory.PRIVACY,
        "description": "Can see accounts on the device"
    },
    "android.permission.MANAGE_ACCOUNTS": {
        "risk": 8, "category": PermissionCategory.PRIVACY,
        "description": "Can manage user accounts"
    },
}

# Risky permission combinations that indicate specific threats
RISKY_COMBINATIONS: List[Tuple[List[str], str, int, str]] = [
    # OTP/SMS Theft
    (
        ["android.permission.READ_SMS", "android.permission.INTERNET"],
        "OTP_THEFT",
        10,
        "Can intercept SMS messages and send them to remote server - common OTP theft pattern"
    ),
    (
        ["android.permission.RECEIVE_SMS", "android.permission.INTERNET"],
        "SMS_INTERCEPTION",
        10,
        "Can intercept incoming SMS and exfiltrate data"
    ),
    
    # Keylogger/Spyware
    (
        ["android.permission.BIND_ACCESSIBILITY_SERVICE", "android.permission.INTERNET"],
        "KEYLOGGER",
        10,
        "Can monitor all user input and send to remote server - spyware pattern"
    ),
    
    # Data Exfiltration
    (
        ["android.permission.READ_CONTACTS", "android.permission.INTERNET"],
        "CONTACT_EXFILTRATION",
        8,
        "Can steal contact list and upload to server"
    ),
    (
        ["android.permission.READ_CALL_LOG", "android.permission.INTERNET"],
        "CALL_LOG_EXFILTRATION",
        8,
        "Can steal call history"
    ),
    
    # Location Tracking
    (
        ["android.permission.ACCESS_FINE_LOCATION", "android.permission.INTERNET", "android.permission.ACCESS_BACKGROUND_LOCATION"],
        "STALKERWARE",
        10,
        "Can track location continuously in background - stalkerware pattern"
    ),
    
    # Surveillance
    (
        ["android.permission.CAMERA", "android.permission.RECORD_AUDIO", "android.permission.INTERNET"],
        "SURVEILLANCE",
        10,
        "Can capture audio/video and transmit remotely"
    ),
    
    # Financial Fraud
    (
        ["android.permission.SEND_SMS", "android.permission.INTERNET"],
        "SMS_FRAUD",
        10,
        "Can send premium SMS and communicate with C&C server"
    ),
    (
        ["android.permission.SYSTEM_ALERT_WINDOW", "android.permission.BIND_ACCESSIBILITY_SERVICE"],
        "OVERLAY_ATTACK",
        10,
        "Can perform overlay attacks to steal credentials"
    ),
    
    # Persistence
    (
        ["android.permission.RECEIVE_BOOT_COMPLETED", "android.permission.FOREGROUND_SERVICE", "android.permission.INTERNET"],
        "PERSISTENT_MALWARE",
        7,
        "Can maintain persistence and communicate even after reboot"
    ),
]


class PermissionAnalyzer:
    """
    Analyzes Android permissions to assess security risks.
    Provides explainable risk scoring and threat detection.
    """
    
    def __init__(self):
        self.dangerous_permissions = DANGEROUS_PERMISSIONS
        self.risky_combinations = RISKY_COMBINATIONS
    
    def analyze(self, permissions: List[str]) -> PermissionAnalysisResult:
        """
        Analyze a list of permissions and return risk assessment.
        
        Args:
            permissions: List of Android permission strings
            
        Returns:
            PermissionAnalysisResult with detailed analysis
        """
        result = PermissionAnalysisResult(total_permissions=len(permissions))
        
        # Normalize permission names
        normalized = [self._normalize_permission(p) for p in permissions]
        
        # Analyze individual permissions
        for perm in normalized:
            risk = self._assess_permission(perm)
            result.permission_risks.append(risk)
            if risk.is_dangerous:
                result.dangerous_count += 1
        
        # Analyze combinations
        result.combination_risks = self._analyze_combinations(normalized)
        
        # Calculate overall score
        result.overall_score = self._calculate_overall_score(result)
        result.summary = self._generate_summary(result)
        
        return result
    
    def _normalize_permission(self, permission: str) -> str:
        """Normalize permission string"""
        if not permission.startswith("android.permission."):
            # Check if it's a short form
            full_perm = f"android.permission.{permission}"
            if full_perm in self.dangerous_permissions:
                return full_perm
        return permission
    
    def _assess_permission(self, permission: str) -> PermissionRisk:
        """Assess risk of individual permission"""
        if permission in self.dangerous_permissions:
            info = self.dangerous_permissions[permission]
            risk_score = info["risk"]
            
            # Determine risk level
            if risk_score >= 9:
                level = RiskLevel.CRITICAL
            elif risk_score >= 7:
                level = RiskLevel.HIGH
            elif risk_score >= 4:
                level = RiskLevel.MEDIUM
            else:
                level = RiskLevel.LOW
            
            return PermissionRisk(
                permission=permission,
                risk_score=risk_score,
                risk_level=level,
                category=info["category"],
                description=info["description"],
                is_dangerous=risk_score >= 6
            )
        
        # Unknown permission - default assessment
        return PermissionRisk(
            permission=permission,
            risk_score=1,
            risk_level=RiskLevel.LOW,
            category=PermissionCategory.OTHER,
            description="Standard permission",
            is_dangerous=False
        )
    
    def _analyze_combinations(self, permissions: List[str]) -> List[CombinationRisk]:
        """Analyze risky permission combinations"""
        risks = []
        permission_set = set(permissions)
        
        for combo, threat_type, score, description in self.risky_combinations:
            combo_set = set(combo)
            if combo_set.issubset(permission_set):
                risks.append(CombinationRisk(
                    permissions=combo,
                    threat_type=threat_type,
                    risk_score=score,
                    description=description
                ))
        
        return risks
    
    def _calculate_overall_score(self, result: PermissionAnalysisResult) -> int:
        """Calculate overall permission risk score (0-100)"""
        if not result.permission_risks:
            return 0
        
        # Base score from individual permissions
        individual_scores = [r.risk_score for r in result.permission_risks]
        max_individual = max(individual_scores) if individual_scores else 0
        avg_individual = sum(individual_scores) / len(individual_scores) if individual_scores else 0
        
        # Combination bonus
        combo_max = max([c.risk_score for c in result.combination_risks], default=0)
        combo_count_bonus = min(len(result.combination_risks) * 5, 20)
        
        # Calculate weighted score
        score = (
            max_individual * 4 +  # Most dangerous permission weight
            avg_individual * 3 +   # Average danger
            combo_max * 2 +        # Most dangerous combination
            combo_count_bonus      # Multiple risky patterns
        )
        
        # Normalize to 0-100
        return min(int(score), 100)
    
    def _generate_summary(self, result: PermissionAnalysisResult) -> str:
        """Generate human-readable summary"""
        if result.overall_score >= 70:
            return f"HIGH RISK: {result.dangerous_count} dangerous permissions with {len(result.combination_risks)} risky patterns detected"
        elif result.overall_score >= 40:
            return f"SUSPICIOUS: {result.dangerous_count} dangerous permissions found, review carefully"
        elif result.overall_score >= 20:
            return f"MODERATE: Some sensitive permissions requested"
        else:
            return f"LOW RISK: Standard permissions only"
