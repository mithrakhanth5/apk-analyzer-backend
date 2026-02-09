"""
Obfuscation Detector Module
Detects code obfuscation patterns that may indicate malicious intent.
"""
import re
import math
from typing import Dict, List, Any
from dataclasses import dataclass, field
from collections import Counter


@dataclass
class ObfuscationAnalysisResult:
    """Obfuscation analysis result"""
    obfuscation_score: int = 0  # 0-100
    is_obfuscated: bool = False
    obfuscation_type: str = "none"
    
    class_name_entropy: float = 0.0
    method_name_entropy: float = 0.0
    short_name_ratio: float = 0.0
    
    indicators: List[str] = field(default_factory=list)
    sample_obfuscated_names: List[str] = field(default_factory=list)


# Common obfuscator patterns
OBFUSCATOR_PATTERNS = {
    "proguard": [
        r"^[a-z]$",  # Single letter class names
        r"^[a-z]{1,2}$",  # Very short names
    ],
    "dexguard": [
        r"^[a-zA-Z0-9]{1,3}$",  # Mixed case short names
    ],
    "allatori": [
        r"^[Il1]{3,}$",  # Confusing character combinations
    ],
    "zelix": [
        r"^_[a-zA-Z0-9]+$",  # Underscore prefix
    ],
}

# Legitimate short names (not indicators of obfuscation)
LEGITIMATE_SHORT_NAMES = {
    "R", "BR", "a", "b", "c",  # Common Android resource classes
    "Log", "Uri", "View", "App",
}


class ObfuscationDetector:
    """
    Detects code obfuscation in APK files.
    Obfuscation itself is not malicious, but heavy obfuscation
    combined with other risk factors may indicate malicious intent.
    """
    
    def __init__(self):
        self.patterns = OBFUSCATOR_PATTERNS
        self.legitimate_names = LEGITIMATE_SHORT_NAMES
    
    def analyze(self, dex_info: Dict[str, Any]) -> ObfuscationAnalysisResult:
        """
        Analyze DEX information for obfuscation patterns.
        
        Args:
            dex_info: DEX information from APK parser
            
        Returns:
            ObfuscationAnalysisResult with obfuscation assessment
        """
        result = ObfuscationAnalysisResult()
        
        classes = dex_info.get("classes", [])
        if not classes:
            return result
        
        # Extract class names (remove package prefix)
        class_names = []
        for cls in classes:
            # Get simple class name from fully qualified name
            # e.g., "Lcom/example/MyClass;" -> "MyClass"
            simple_name = self._extract_simple_name(cls)
            if simple_name:
                class_names.append(simple_name)
        
        if not class_names:
            return result
        
        # Analyze class name patterns
        result.class_name_entropy = self._calculate_name_entropy(class_names)
        result.short_name_ratio = self._calculate_short_name_ratio(class_names)
        
        # Detect obfuscation patterns
        obfuscated_names = self._find_obfuscated_names(class_names)
        result.sample_obfuscated_names = obfuscated_names[:10]
        
        # Detect obfuscator type
        result.obfuscation_type = self._detect_obfuscator_type(class_names)
        
        # Generate indicators
        result.indicators = self._generate_indicators(result, class_names)
        
        # Calculate overall score
        result.obfuscation_score = self._calculate_score(result)
        result.is_obfuscated = result.obfuscation_score >= 40
        
        return result
    
    def _extract_simple_name(self, class_path: str) -> str:
        """Extract simple class name from DEX class path"""
        # Remove L prefix and ; suffix if present
        name = class_path.strip()
        if name.startswith("L"):
            name = name[1:]
        if name.endswith(";"):
            name = name[:-1]
        
        # Get last component (actual class name)
        if "/" in name:
            name = name.split("/")[-1]
        if "$" in name:
            # Inner class - get the inner class name
            name = name.split("$")[-1]
        
        return name
    
    def _calculate_name_entropy(self, names: List[str]) -> float:
        """
        Calculate average Shannon entropy of names.
        Low entropy with short names often indicates obfuscation.
        """
        if not names:
            return 0.0
        
        entropies = []
        for name in names:
            if len(name) < 2:
                entropies.append(0)
                continue
            
            # Calculate character frequency entropy
            freq = Counter(name.lower())
            length = len(name)
            entropy = 0
            for count in freq.values():
                p = count / length
                entropy -= p * math.log2(p)
            
            # Normalize by length
            max_entropy = math.log2(length) if length > 1 else 1
            normalized = entropy / max_entropy if max_entropy > 0 else 0
            entropies.append(normalized)
        
        return sum(entropies) / len(entropies) if entropies else 0.0
    
    def _calculate_short_name_ratio(self, names: List[str]) -> float:
        """Calculate ratio of very short class names"""
        if not names:
            return 0.0
        
        short_count = sum(
            1 for name in names 
            if len(name) <= 2 and name not in self.legitimate_names
        )
        return short_count / len(names)
    
    def _find_obfuscated_names(self, names: List[str]) -> List[str]:
        """Find names that appear obfuscated"""
        obfuscated = []
        
        for name in names:
            if name in self.legitimate_names:
                continue
            
            # Check against obfuscator patterns
            for obfuscator, patterns in self.patterns.items():
                for pattern in patterns:
                    if re.match(pattern, name):
                        obfuscated.append(name)
                        break
        
        return list(set(obfuscated))
    
    def _detect_obfuscator_type(self, names: List[str]) -> str:
        """Attempt to detect which obfuscator was used"""
        pattern_matches = {obf: 0 for obf in self.patterns.keys()}
        
        for name in names:
            for obfuscator, patterns in self.patterns.items():
                for pattern in patterns:
                    if re.match(pattern, name):
                        pattern_matches[obfuscator] += 1
                        break
        
        # Find most likely obfuscator
        max_matches = max(pattern_matches.values())
        if max_matches > len(names) * 0.1:  # At least 10% match
            for obf, count in pattern_matches.items():
                if count == max_matches:
                    return obf
        
        return "unknown" if max_matches > 0 else "none"
    
    def _generate_indicators(
        self, 
        result: ObfuscationAnalysisResult,
        names: List[str]
    ) -> List[str]:
        """Generate human-readable obfuscation indicators"""
        indicators = []
        
        if result.short_name_ratio > 0.3:
            indicators.append(
                f"High ratio ({result.short_name_ratio:.0%}) of very short class names"
            )
        
        if result.class_name_entropy < 0.4 and len(names) > 50:
            indicators.append(
                "Low entropy in class names suggests systematic renaming"
            )
        
        if result.obfuscation_type != "none":
            indicators.append(
                f"Pattern consistent with {result.obfuscation_type.upper()} obfuscator"
            )
        
        if len(result.sample_obfuscated_names) > 10:
            indicators.append(
                f"Found {len(result.sample_obfuscated_names)}+ obfuscated class names"
            )
        
        return indicators
    
    def _calculate_score(self, result: ObfuscationAnalysisResult) -> int:
        """Calculate overall obfuscation score (0-100)"""
        score = 0
        
        # Short name ratio contribution
        if result.short_name_ratio > 0.5:
            score += 40
        elif result.short_name_ratio > 0.3:
            score += 25
        elif result.short_name_ratio > 0.1:
            score += 10
        
        # Low entropy contribution
        if result.class_name_entropy < 0.3:
            score += 30
        elif result.class_name_entropy < 0.5:
            score += 15
        
        # Known obfuscator pattern
        if result.obfuscation_type not in ["none", "unknown"]:
            score += 20
        elif result.obfuscation_type == "unknown":
            score += 10
        
        return min(score, 100)
    
    def get_obfuscation_context(self, score: int) -> str:
        """
        Provide context about obfuscation score.
        Important: Obfuscation is NOT inherently malicious.
        """
        if score < 20:
            return (
                "Minimal obfuscation detected. Code appears to use standard naming "
                "conventions. This is neutral - legitimate apps may or may not be obfuscated."
            )
        elif score < 50:
            return (
                "Moderate obfuscation detected, likely using ProGuard or similar tool. "
                "This is COMMON for production Android apps to protect intellectual property "
                "and reduce APK size. Not inherently suspicious."
            )
        elif score < 80:
            return (
                "Heavy obfuscation detected. While commercial apps sometimes use aggressive "
                "obfuscation, this level combined with other risk factors may warrant caution. "
                "Consider the app's source and reputation."
            )
        else:
            return (
                "Extreme obfuscation detected. While not proof of malicious intent, this level "
                "of obfuscation is unusual and, combined with other red flags, could indicate "
                "an attempt to hide malicious behavior."
            )
