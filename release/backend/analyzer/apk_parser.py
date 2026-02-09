"""
APK Parser Module
Extracts metadata, manifest, and components from APK files using Androguard.
"""
import hashlib
import tempfile
import os
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field

try:
    from androguard.core.apk import APK
    from androguard.core.dex import DEX
    ANDROGUARD_AVAILABLE = True
except ImportError:
    ANDROGUARD_AVAILABLE = False


@dataclass
class APKMetadata:
    """Extracted APK metadata"""
    package_name: str = ""
    version_name: str = ""
    version_code: int = 0
    min_sdk: int = 0
    target_sdk: int = 0
    app_name: str = ""
    file_hash_sha256: str = ""
    file_size: int = 0
    
    # Components
    permissions: List[str] = field(default_factory=list)
    activities: List[str] = field(default_factory=list)
    services: List[str] = field(default_factory=list)
    receivers: List[str] = field(default_factory=list)
    providers: List[str] = field(default_factory=list)
    
    # Certificate info
    certificate_info: Dict[str, Any] = field(default_factory=dict)
    
    # Additional metadata
    uses_features: List[str] = field(default_factory=list)
    intent_filters: List[Dict[str, Any]] = field(default_factory=list)


class APKParser:
    """
    Parses APK files and extracts security-relevant information.
    Uses Androguard for static analysis.
    """
    
    def __init__(self):
        if not ANDROGUARD_AVAILABLE:
            raise ImportError(
                "Androguard is required for APK parsing. "
                "Install with: pip install androguard"
            )
        self.apk: Optional[APK] = None
        self.temp_file: Optional[str] = None
    
    def parse_from_bytes(self, apk_bytes: bytes) -> APKMetadata:
        """
        Parse APK from raw bytes.
        
        Args:
            apk_bytes: Raw APK file content
            
        Returns:
            APKMetadata with extracted information
        """
        # Calculate file hash first
        file_hash = hashlib.sha256(apk_bytes).hexdigest()
        
        # Write to temp file for Androguard
        with tempfile.NamedTemporaryFile(delete=False, suffix='.apk') as f:
            f.write(apk_bytes)
            self.temp_file = f.name
        
        try:
            return self.parse_from_path(self.temp_file, file_hash, len(apk_bytes))
        finally:
            # Cleanup temp file
            if self.temp_file and os.path.exists(self.temp_file):
                os.remove(self.temp_file)
                self.temp_file = None
    
    def parse_from_path(
        self, 
        apk_path: str, 
        file_hash: Optional[str] = None,
        file_size: Optional[int] = None
    ) -> APKMetadata:
        """
        Parse APK from file path.
        
        Args:
            apk_path: Path to APK file
            file_hash: Pre-calculated SHA256 hash (optional)
            file_size: File size in bytes (optional)
            
        Returns:
            APKMetadata with extracted information
        """
        # Calculate hash if not provided
        if file_hash is None:
            with open(apk_path, 'rb') as f:
                file_hash = hashlib.sha256(f.read()).hexdigest()
        
        if file_size is None:
            file_size = os.path.getsize(apk_path)
        
        # Parse with Androguard
        self.apk = APK(apk_path)
        
        metadata = APKMetadata(
            package_name=self.apk.get_package() or "",
            version_name=self.apk.get_androidversion_name() or "",
            version_code=int(self.apk.get_androidversion_code() or 0),
            min_sdk=int(self.apk.get_min_sdk_version() or 0),
            target_sdk=int(self.apk.get_target_sdk_version() or 0),
            app_name=self.apk.get_app_name() or "",
            file_hash_sha256=file_hash,
            file_size=file_size,
            
            # Extract components
            permissions=list(self.apk.get_permissions()),
            activities=list(self.apk.get_activities()),
            services=list(self.apk.get_services()),
            receivers=list(self.apk.get_receivers()),
            providers=list(self.apk.get_providers()),
            
            # Certificate
            certificate_info=self._extract_certificate_info(),
            
            # Features
            uses_features=list(self.apk.get_features()),
            intent_filters=self._extract_intent_filters()
        )
        
        return metadata
    
    def _extract_certificate_info(self) -> Dict[str, Any]:
        """Extract certificate/signature information"""
        cert_info = {
            "is_signed": False,
            "certificates": [],
            "signature_version": None
        }
        
        if self.apk is None:
            return cert_info
        
        try:
            # Check if signed
            cert_info["is_signed"] = self.apk.is_signed()
            
            # Get certificates
            certs = self.apk.get_certificates()
            for cert in certs:
                cert_data = {
                    "issuer": str(cert.issuer) if hasattr(cert, 'issuer') else "Unknown",
                    "subject": str(cert.subject) if hasattr(cert, 'subject') else "Unknown",
                    "serial_number": str(cert.serial_number) if hasattr(cert, 'serial_number') else None,
                    "not_valid_before": str(cert.not_valid_before) if hasattr(cert, 'not_valid_before') else None,
                    "not_valid_after": str(cert.not_valid_after) if hasattr(cert, 'not_valid_after') else None,
                }
                cert_info["certificates"].append(cert_data)
            
            # Check signature version
            if self.apk.is_signed_v1():
                cert_info["signature_version"] = "v1"
            if self.apk.is_signed_v2():
                cert_info["signature_version"] = "v2"
            if self.apk.is_signed_v3():
                cert_info["signature_version"] = "v3"
                
        except Exception as e:
            cert_info["error"] = str(e)
        
        return cert_info
    
    def _extract_intent_filters(self) -> List[Dict[str, Any]]:
        """Extract intent filters from manifest"""
        filters = []
        
        if self.apk is None:
            return filters
        
        try:
            # Get main activity intent filters
            main_activity = self.apk.get_main_activity()
            if main_activity:
                filters.append({
                    "component": main_activity,
                    "type": "activity",
                    "actions": ["android.intent.action.MAIN"],
                    "categories": ["android.intent.category.LAUNCHER"]
                })
            
            # Extract receiver intent filters (common for malware)
            for receiver in self.apk.get_receivers():
                receiver_filters = {
                    "component": receiver,
                    "type": "receiver",
                    "actions": [],
                    "categories": []
                }
                filters.append(receiver_filters)
                
        except Exception:
            pass
        
        return filters
    
    def get_dex_info(self) -> Dict[str, Any]:
        """Extract DEX file information for obfuscation detection"""
        dex_info = {
            "dex_count": 0,
            "classes": [],
            "methods_count": 0
        }
        
        if self.apk is None:
            return dex_info
        
        try:
            dex_names = self.apk.get_dex_names()
            dex_info["dex_count"] = len(dex_names)
            
            # Get class names for obfuscation analysis
            for dex_name in dex_names[:1]:  # Only analyze first DEX
                dex_bytes = self.apk.get_file(dex_name)
                if dex_bytes:
                    dex = DEX(dex_bytes)
                    for cls in dex.get_classes():
                        class_name = cls.get_name()
                        dex_info["classes"].append(class_name)
                        dex_info["methods_count"] += len(list(cls.get_methods()))
                        
                        # Limit for performance
                        if len(dex_info["classes"]) > 1000:
                            break
                            
        except Exception as e:
            dex_info["error"] = str(e)
        
        return dex_info
