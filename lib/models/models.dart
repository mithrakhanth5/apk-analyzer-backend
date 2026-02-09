/// Data models for APK analysis

/// APK file information model
class ApkInfo {
  final String fileName;
  final String filePath;
  final int fileSize;
  final String sha256Hash;
  
  ApkInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.sha256Hash,
  });
  
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Permission risk model
class PermissionRisk {
  final String permission;
  final int riskScore;
  final String riskLevel;
  final String category;
  final String description;
  
  PermissionRisk({
    required this.permission,
    required this.riskScore,
    required this.riskLevel,
    required this.category,
    required this.description,
  });
  
  factory PermissionRisk.fromJson(Map<String, dynamic> json) {
    return PermissionRisk(
      permission: json['permission'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? 'LOW',
      category: json['category'] ?? 'other',
      description: json['description'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'permission': permission,
    'risk_score': riskScore,
    'risk_level': riskLevel,
    'category': category,
    'description': description,
  };
  
  String get shortName => permission.split('.').last;
}

/// Risk finding model
class RiskFinding {
  final String category;
  final String severity;
  final String title;
  final String description;
  final List<String> evidence;
  final int scoreImpact;
  final String recommendation;
  
  RiskFinding({
    required this.category,
    required this.severity,
    required this.title,
    required this.description,
    required this.evidence,
    required this.scoreImpact,
    this.recommendation = '',
  });
  
  factory RiskFinding.fromJson(Map<String, dynamic> json) {
    return RiskFinding(
      category: json['category'] ?? '',
      severity: json['severity'] ?? 'LOW',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      evidence: List<String>.from(json['evidence'] ?? []),
      scoreImpact: json['score_impact'] ?? 0,
      recommendation: json['recommendation'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'category': category,
    'severity': severity,
    'title': title,
    'description': description,
    'evidence': evidence,
    'score_impact': scoreImpact,
    'recommendation': recommendation,
  };
}

/// Certificate information model
class CertificateInfo {
  final String issuer;
  final String subject;
  final bool isDebug;
  final bool isSelfSigned;
  final bool isExpired;
  final String? signatureVersion;
  final List<String> warnings;
  
  CertificateInfo({
    required this.issuer,
    required this.subject,
    required this.isDebug,
    required this.isSelfSigned,
    required this.isExpired,
    this.signatureVersion,
    required this.warnings,
  });
  
  factory CertificateInfo.fromJson(Map<String, dynamic> json) {
    return CertificateInfo(
      issuer: json['issuer'] ?? '',
      subject: json['subject'] ?? '',
      isDebug: json['is_debug'] ?? false,
      isSelfSigned: json['is_self_signed'] ?? false,
      isExpired: json['is_expired'] ?? false,
      signatureVersion: json['signature_version'],
      warnings: List<String>.from(json['warnings'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'issuer': issuer,
    'subject': subject,
    'is_debug': isDebug,
    'is_self_signed': isSelfSigned,
    'is_expired': isExpired,
    'signature_version': signatureVersion,
    'warnings': warnings,
  };
}

/// Sandbox analysis result
class SandboxResult {
  final String detectionRatio;
  final int positives;
  final int totalScanners;
  final String threatLevel;
  final List<String> malwareNames;
  final int riskScore;
  final List<String> warnings;
  final String errorMessage;
  
  SandboxResult({
    required this.detectionRatio,
    required this.positives,
    required this.totalScanners,
    required this.threatLevel,
    required this.malwareNames,
    required this.riskScore,
    required this.warnings,
    this.errorMessage = '',
  });
  
  factory SandboxResult.fromJson(Map<String, dynamic> json) {
    return SandboxResult(
      detectionRatio: json['detection_ratio'] ?? '0/0',
      positives: json['positives'] ?? 0,
      totalScanners: json['total_scanners'] ?? 0,
      threatLevel: json['threat_level'] ?? 'undetected',
      malwareNames: List<String>.from(json['malware_names'] ?? []),
      riskScore: json['risk_score'] ?? 0,
      warnings: List<String>.from(json['warnings'] ?? []),
      errorMessage: json['error_message'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'detection_ratio': detectionRatio,
    'positives': positives,
    'total_scanners': totalScanners,
    'threat_level': threatLevel,
    'malware_names': malwareNames,
    'risk_score': riskScore,
    'warnings': warnings,
    'error_message': errorMessage,
  };
}

/// Complete risk report model
class RiskReport {
  final String analysisId;
  final String packageName;
  final String versionName;
  final String appName;
  final String fileHash;
  
  final int riskScore;
  final String classification;
  
  final int permissionScore;
  final int certificateScore;
  final int obfuscationScore;
  final int networkScore;
  final int sandboxScore;
  
  final List<RiskFinding> findings;
  final List<PermissionRisk> permissions;
  final CertificateInfo certificate;
  final SandboxResult? sandbox;
  
  final String summary;
  final String recommendation;
  final List<String> limitations;
  
  RiskReport({
    required this.analysisId,
    required this.packageName,
    required this.versionName,
    required this.appName,
    required this.fileHash,
    required this.riskScore,
    required this.classification,
    required this.permissionScore,
    required this.certificateScore,
    required this.obfuscationScore,
    required this.networkScore,
    this.sandboxScore = 0,
    required this.findings,
    required this.permissions,
    required this.certificate,
    this.sandbox,
    required this.summary,
    required this.recommendation,
    required this.limitations,
  });
  
  factory RiskReport.fromJson(Map<String, dynamic> json) {
    return RiskReport(
      analysisId: json['analysis_id'] ?? '',
      packageName: json['package_name'] ?? '',
      versionName: json['version_name'] ?? '',
      appName: json['app_name'] ?? 'Unknown App',
      fileHash: json['file_hash'] ?? '',
      riskScore: json['risk_score'] ?? 0,
      classification: json['classification'] ?? 'SAFE',
      permissionScore: json['permission_score'] ?? 0,
      certificateScore: json['certificate_score'] ?? 0,
      obfuscationScore: json['obfuscation_score'] ?? 0,
      networkScore: json['network_score'] ?? 0,
      sandboxScore: json['sandbox_score'] ?? 0,
      findings: (json['findings'] as List<dynamic>?)
          ?.map((f) => RiskFinding.fromJson(f))
          .toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((p) => PermissionRisk.fromJson(p))
          .toList() ?? [],
      certificate: CertificateInfo.fromJson(json['certificate'] ?? {}),
      sandbox: json['sandbox'] != null ? SandboxResult.fromJson(json['sandbox']) : null,
      summary: json['summary'] ?? '',
      recommendation: json['recommendation'] ?? '',
      limitations: List<String>.from(json['limitations'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'analysis_id': analysisId,
    'package_name': packageName,
    'version_name': versionName,
    'app_name': appName,
    'file_hash': fileHash,
    'risk_score': riskScore,
    'classification': classification,
    'permission_score': permissionScore,
    'certificate_score': certificateScore,
    'obfuscation_score': obfuscationScore,
    'network_score': networkScore,
    'sandbox_score': sandboxScore,
    'findings': findings.map((f) => f.toJson()).toList(),
    'permissions': permissions.map((p) => p.toJson()).toList(),
    'certificate': certificate.toJson(),
    'sandbox': sandbox?.toJson(),
    'summary': summary,
    'recommendation': recommendation,
    'limitations': limitations,
  };
  
  List<RiskFinding> get criticalFindings =>
      findings.where((f) => f.severity == 'CRITICAL').toList();
  
  List<RiskFinding> get highRiskFindings =>
      findings.where((f) => f.severity == 'HIGH').toList();
      
  List<PermissionRisk> get dangerousPermissions =>
      permissions.where((p) => p.riskScore >= 7).toList();
}

/// Analysis state for UI
enum AnalysisState {
  idle,
  selectingFile,
  fileSelected,
  analyzing,
  completed,
  error,
}
