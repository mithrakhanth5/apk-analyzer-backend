/// API service for communicating with the analysis backend

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../config/constants.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;
  
  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? AppConstants.defaultApiUrl,
        _client = http.Client();
  
  /// Check if the API is available
  Future<bool> healthCheck() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${ApiEndpoints.health}'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Submit APK for analysis
  Future<RiskReport> analyzeApk(Uint8List apkBytes, String hash) async {
    try {
      // Encode APK as base64
      String base64Apk = base64Encode(apkBytes);
      
      final response = await _client
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.analyze}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'apk_hash': hash,
              'apk_data': base64Apk,
            }),
          )
          .timeout(AppConstants.apiTimeout);
      
      if (response.statusCode == 200) {
        Map<String, dynamic> json = jsonDecode(response.body);
        return RiskReport.fromJson(json);
      } else {
        Map<String, dynamic> error = jsonDecode(response.body);
        throw ApiException(
          error['detail'] ?? 'Analysis failed',
          response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Connection failed: $e', 0);
    }
  }
  
  /// Get list of dangerous permissions for reference
  Future<Map<String, dynamic>> getDangerousPermissions() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${ApiEndpoints.permissions}'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('Failed to fetch permissions', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Connection failed: $e', 0);
    }
  }
  
  /// Get limitations documentation
  Future<Map<String, dynamic>> getLimitations() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${ApiEndpoints.limitations}'))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException('Failed to fetch limitations', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Connection failed: $e', 0);
    }
  }
  
  /// Download PDF report from analysis results
  Future<Uint8List> downloadPdfReport(RiskReport report) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/api/v1/report/pdf'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(report.toJson()),
          )
          .timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        String errorMsg = 'PDF generation failed';
        try {
          Map<String, dynamic> error = jsonDecode(response.body);
          errorMsg = error['detail'] ?? errorMsg;
        } catch (_) {}
        throw ApiException(errorMsg, response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('PDF download failed: $e', 0);
    }
  }
  
  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
