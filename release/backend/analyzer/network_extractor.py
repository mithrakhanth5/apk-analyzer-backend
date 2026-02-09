"""
Network Extractor Module
Extracts network endpoints and URLs from APK resources and code.
"""
import re
from typing import Dict, List, Set, Any
from dataclasses import dataclass, field
from urllib.parse import urlparse


@dataclass
class NetworkEndpoint:
    """Represents an extracted network endpoint"""
    url: str
    domain: str
    is_https: bool
    endpoint_type: str  # "api", "tracking", "cdn", "suspicious", "unknown"
    risk_level: str  # "low", "medium", "high"
    context: str = ""  # Where it was found


@dataclass
class NetworkAnalysisResult:
    """Network analysis result"""
    total_endpoints: int = 0
    unique_domains: int = 0
    https_ratio: float = 0.0
    risk_score: int = 0  # 0-100
    
    endpoints: List[NetworkEndpoint] = field(default_factory=list)
    suspicious_endpoints: List[NetworkEndpoint] = field(default_factory=list)
    domains: List[str] = field(default_factory=list)
    
    warnings: List[str] = field(default_factory=list)


# Known suspicious TLDs often used for malware C&C
SUSPICIOUS_TLDS = {
    ".tk", ".ml", ".ga", ".cf", ".gq",  # Free domains often abused
    ".xyz", ".top", ".work", ".click",
    ".onion",  # Tor hidden services
}

# Known tracking/analytics domains
TRACKING_DOMAINS = {
    "google-analytics.com", "googleadservices.com",
    "facebook.com", "facebook.net",
    "amplitude.com", "mixpanel.com",
    "appsflyer.com", "adjust.com",
    "crashlytics.com", "firebase.google.com",
}

# Known CDN domains (generally safe)
CDN_DOMAINS = {
    "cloudflare.com", "akamaized.net",
    "cloudfront.net", "googleapis.com",
    "gstatic.com", "githubusercontent.com",
}

# Suspicious URL patterns
SUSPICIOUS_PATTERNS = [
    r"http://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}",  # Raw IP addresses over HTTP
    r"http://.*:(?!80|443)\d+",  # Non-standard ports
    r".*\.php\?.*=",  # PHP with query params (common C&C pattern)
    r".*/gate\.php",  # Common malware gate
    r".*/panel/",  # Admin panels
    r".*\.(ru|cn|su)/",  # Certain country TLDs
]


class NetworkExtractor:
    """
    Extracts and analyzes network endpoints from APK.
    """
    
    def __init__(self):
        self.suspicious_tlds = SUSPICIOUS_TLDS
        self.tracking_domains = TRACKING_DOMAINS
        self.cdn_domains = CDN_DOMAINS
        self.suspicious_patterns = [re.compile(p, re.IGNORECASE) for p in SUSPICIOUS_PATTERNS]
    
    def analyze(
        self, 
        strings: List[str] = None,
        manifest_data: Dict[str, Any] = None
    ) -> NetworkAnalysisResult:
        """
        Analyze APK for network endpoints.
        
        Args:
            strings: Extracted strings from APK
            manifest_data: Parsed manifest data
            
        Returns:
            NetworkAnalysisResult with endpoint analysis
        """
        result = NetworkAnalysisResult()
        
        if strings is None:
            strings = []
        
        # Extract URLs from strings
        urls = self._extract_urls(strings)
        
        # Analyze each URL
        domains_seen: Set[str] = set()
        https_count = 0
        
        for url in urls:
            endpoint = self._analyze_endpoint(url)
            if endpoint:
                result.endpoints.append(endpoint)
                domains_seen.add(endpoint.domain)
                
                if endpoint.is_https:
                    https_count += 1
                
                if endpoint.risk_level == "high":
                    result.suspicious_endpoints.append(endpoint)
        
        # Calculate stats
        result.total_endpoints = len(result.endpoints)
        result.unique_domains = len(domains_seen)
        result.domains = list(domains_seen)
        result.https_ratio = https_count / len(result.endpoints) if result.endpoints else 1.0
        
        # Generate warnings
        result.warnings = self._generate_warnings(result)
        
        # Calculate risk score
        result.risk_score = self._calculate_risk_score(result)
        
        return result
    
    def _extract_urls(self, strings: List[str]) -> List[str]:
        """Extract URLs from string list"""
        url_pattern = re.compile(
            r'https?://[^\s<>"{}|\\^`\[\]]+',
            re.IGNORECASE
        )
        
        urls = []
        for s in strings:
            matches = url_pattern.findall(str(s))
            urls.extend(matches)
        
        # Deduplicate while preserving order
        seen = set()
        unique_urls = []
        for url in urls:
            normalized = url.rstrip("/").lower()
            if normalized not in seen:
                seen.add(normalized)
                unique_urls.append(url)
        
        return unique_urls
    
    def _analyze_endpoint(self, url: str) -> NetworkEndpoint:
        """Analyze a single endpoint"""
        try:
            parsed = urlparse(url)
            domain = parsed.netloc.lower()
            
            # Remove port if present
            if ":" in domain:
                domain = domain.split(":")[0]
            
            is_https = parsed.scheme.lower() == "https"
            
            # Determine endpoint type
            endpoint_type = self._classify_endpoint(domain, url)
            
            # Determine risk level
            risk_level = self._assess_endpoint_risk(url, domain, is_https, endpoint_type)
            
            return NetworkEndpoint(
                url=url,
                domain=domain,
                is_https=is_https,
                endpoint_type=endpoint_type,
                risk_level=risk_level
            )
        except Exception:
            return None
    
    def _classify_endpoint(self, domain: str, url: str) -> str:
        """Classify endpoint type"""
        # Check CDN
        for cdn in self.cdn_domains:
            if cdn in domain:
                return "cdn"
        
        # Check tracking/analytics
        for tracker in self.tracking_domains:
            if tracker in domain:
                return "tracking"
        
        # Check for API patterns
        if "/api/" in url or "/v1/" in url or "/v2/" in url:
            return "api"
        
        # Check suspicious patterns
        for pattern in self.suspicious_patterns:
            if pattern.search(url):
                return "suspicious"
        
        return "unknown"
    
    def _assess_endpoint_risk(
        self, 
        url: str, 
        domain: str, 
        is_https: bool,
        endpoint_type: str
    ) -> str:
        """Assess risk level of endpoint"""
        # High risk indicators
        high_risk = False
        
        # Check suspicious TLDs
        for tld in self.suspicious_tlds:
            if domain.endswith(tld):
                high_risk = True
                break
        
        # Check suspicious patterns
        for pattern in self.suspicious_patterns:
            if pattern.search(url):
                high_risk = True
                break
        
        # Raw IP over HTTP
        if re.match(r"http://\d+\.\d+\.\d+\.\d+", url):
            high_risk = True
        
        if high_risk:
            return "high"
        
        # Medium risk: HTTP (not HTTPS) for non-CDN
        if not is_https and endpoint_type not in ["cdn"]:
            return "medium"
        
        # Unknown domains
        if endpoint_type == "unknown":
            return "medium"
        
        return "low"
    
    def _generate_warnings(self, result: NetworkAnalysisResult) -> List[str]:
        """Generate warnings about network endpoints"""
        warnings = []
        
        if result.suspicious_endpoints:
            warnings.append(
                f"⚠️ Found {len(result.suspicious_endpoints)} suspicious network endpoints "
                f"that may indicate command & control communication"
            )
        
        if result.https_ratio < 0.5 and result.total_endpoints > 5:
            warnings.append(
                f"⚠️ Only {result.https_ratio:.0%} of endpoints use HTTPS. "
                f"Data may be transmitted insecurely."
            )
        
        # Check for IP-based endpoints
        ip_endpoints = [e for e in result.endpoints if re.match(r"\d+\.\d+\.\d+\.\d+", e.domain)]
        if ip_endpoints:
            warnings.append(
                f"⚠️ Found {len(ip_endpoints)} endpoints using raw IP addresses "
                f"instead of domain names - common in malware"
            )
        
        return warnings
    
    def _calculate_risk_score(self, result: NetworkAnalysisResult) -> int:
        """Calculate network risk score (0-100)"""
        score = 0
        
        # Suspicious endpoints
        score += len(result.suspicious_endpoints) * 15
        
        # HTTP ratio penalty
        if result.total_endpoints > 0:
            http_ratio = 1 - result.https_ratio
            score += int(http_ratio * 20)
        
        # Many unknown domains
        unknown_count = sum(1 for e in result.endpoints if e.endpoint_type == "unknown")
        if unknown_count > 5:
            score += 10
        
        return min(score, 100)
    
    def extract_from_dex(self, dex_strings: List[str]) -> List[str]:
        """
        Extract network-related strings from DEX.
        Override this for more sophisticated extraction.
        """
        network_strings = []
        
        patterns = [
            r'https?://[^\s"\'<>]+',  # URLs
            r'\b(?:\d{1,3}\.){3}\d{1,3}\b',  # IP addresses
            r'[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}',  # Domain names
        ]
        
        for s in dex_strings:
            for pattern in patterns:
                matches = re.findall(pattern, str(s))
                network_strings.extend(matches)
        
        return network_strings
