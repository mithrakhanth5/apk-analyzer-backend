/// Application constants and configuration

import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'APK Risk Analyzer';
  static const String appVersion = '1.0.0';
  static const String appDescription = 
      'Secure, consent-based pre-installation APK risk assessment';
  
  // API Configuration
  // For Android emulator: 10.0.2.2 points to host machine's localhost
  static const String localApiUrl = 'http://10.0.2.2:8000';
  
  // Cloud URL (Koyeb deployment - fast ~200ms cold starts)
  static const String cloudApiUrl = 'https://absolute-luci-apkrisk-4f558069.koyeb.app';

  static bool useCloud = true; // Using Koyeb cloud backend

  static String get defaultApiUrl {
    if (useCloud) return cloudApiUrl;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return localApiUrl;
    return 'http://localhost:8000';
  }
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 300);
  
  // Risk Thresholds
  static const int safeThreshold = 30;
  static const int suspiciousThreshold = 60;
  
  // File size limits (in bytes)
  static const int maxApkSize = 200 * 1024 * 1024; // 200 MB
}

class RiskClassification {
  static const String safe = 'SAFE';
  static const String suspicious = 'SUSPICIOUS';
  static const String highRisk = 'HIGH_RISK';
}

class ApiEndpoints {
  ApiEndpoints._();
  
  static String get baseUrl => AppConstants.defaultApiUrl;
  static String get analyze => '/api/${AppConstants.apiVersion}/analyze';
  static String get analyzeUpload => '/api/${AppConstants.apiVersion}/analyze/upload';
  static String get health => '/api/${AppConstants.apiVersion}/health';
  static String get limitations => '/api/${AppConstants.apiVersion}/limitations';
  static String get permissions => '/api/${AppConstants.apiVersion}/permissions';
}

class SecurityMessages {
  SecurityMessages._();
  
  static const String disclaimer = '''
This tool provides ADVISORY information only and does NOT guarantee security.

Limitations:
• Static analysis only - cannot detect runtime behavior
• Cannot identify zero-day or unknown malware
• Risk scores are heuristic estimates
• False positives are possible

Always download apps from trusted sources.
''';
  
  static const String consentWarning = '''
You are about to proceed with installing an app that has been flagged as potentially risky.

By continuing, you acknowledge that:
• You understand the identified risks
• You trust the source of this APK
• You accept responsibility for any consequences

This tool cannot guarantee your safety.
''';
}
