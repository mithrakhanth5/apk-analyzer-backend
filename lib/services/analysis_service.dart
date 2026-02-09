/// Analysis service - orchestrates the complete analysis flow

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'file_service.dart';
import 'api_service.dart';

/// State notifier for analysis workflow
class AnalysisService extends ChangeNotifier {
  final FileService _fileService = FileService();
  final ApiService _apiService = ApiService();
  
  // State
  AnalysisState _state = AnalysisState.idle;
  ApkInfo? _apkInfo;
  RiskReport? _riskReport;
  String? _error;
  double _progress = 0.0;
  String _progressMessage = '';
  bool _isDownloadingPdf = false;
  
  // Getters
  AnalysisState get state => _state;
  ApkInfo? get apkInfo => _apkInfo;
  RiskReport? get riskReport => _riskReport;
  String? get error => _error;
  double get progress => _progress;
  String get progressMessage => _progressMessage;
  bool get isDownloadingPdf => _isDownloadingPdf;
  
  bool get hasApk => _apkInfo != null;
  bool get hasReport => _riskReport != null;
  bool get isAnalyzing => _state == AnalysisState.analyzing;
  
  /// Reset to initial state
  void reset() {
    _state = AnalysisState.idle;
    _apkInfo = null;
    _riskReport = null;
    _error = null;
    _progress = 0.0;
    _progressMessage = '';
    _isDownloadingPdf = false;
    notifyListeners();
  }
  
  /// Check backend availability
  Future<bool> checkBackendHealth() async {
    return await _apiService.healthCheck();
  }
  
  /// Select an APK file
  Future<void> selectApk() async {
    try {
      _state = AnalysisState.selectingFile;
      _error = null;
      notifyListeners();
      
      ApkInfo? info = await _fileService.selectApkFile();
      
      if (info != null) {
        _apkInfo = info;
        _state = AnalysisState.fileSelected;
        _riskReport = null;
      } else {
        _state = AnalysisState.idle;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _state = AnalysisState.error;
      notifyListeners();
    }
  }
  
  /// Start analysis of the selected APK
  Future<void> analyzeApk() async {
    if (_apkInfo == null) {
      _error = 'No APK selected';
      _state = AnalysisState.error;
      notifyListeners();
      return;
    }
    
    try {
      _state = AnalysisState.analyzing;
      _error = null;
      _progress = 0.0;
      notifyListeners();
      
      // Step 1: Read file
      _progressMessage = 'Reading APK file...';
      _progress = 0.1;
      notifyListeners();
      
      Uint8List? bytes;
      if (_apkInfo!.filePath.isNotEmpty) {
        bytes = await File(_apkInfo!.filePath).readAsBytes();
      }
      
      if (bytes == null) {
        throw Exception('Could not read APK file');
      }
      
      // Step 2: Verify integrity
      _progressMessage = 'Verifying file integrity...';
      _progress = 0.2;
      notifyListeners();
      
      bool isValid = _fileService.verifyIntegrity(bytes, _apkInfo!.sha256Hash);
      if (!isValid) {
        throw Exception('File integrity check failed');
      }
      
      // Step 3: Upload for analysis
      _progressMessage = 'Uploading to analyzer...';
      _progress = 0.4;
      notifyListeners();
      
      // Step 4: Wait for analysis
      _progressMessage = 'Analyzing APK (including sandbox)...';
      _progress = 0.6;
      notifyListeners();
      
      RiskReport report = await _apiService.analyzeApk(bytes, _apkInfo!.sha256Hash);
      
      // Step 5: Complete
      _progressMessage = 'Analysis complete';
      _progress = 1.0;
      _riskReport = report;
      _state = AnalysisState.completed;
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      _state = AnalysisState.error;
      notifyListeners();
    }
  }
  
  /// Download PDF report
  Future<String?> downloadPdfReport() async {
    if (_riskReport == null) {
      _error = 'No analysis report available';
      notifyListeners();
      return null;
    }
    
    try {
      _isDownloadingPdf = true;
      notifyListeners();
      
      // Get PDF bytes from API
      Uint8List pdfBytes = await _apiService.downloadPdfReport(_riskReport!);
      
      // Get downloads directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }
      
      if (downloadDir == null) {
        throw Exception('Could not access download directory');
      }
      
      // Create filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filename = 'APK_Risk_Report_${_riskReport!.packageName}_$timestamp.pdf';
      String filePath = '${downloadDir.path}/$filename';
      
      // Save file
      File pdfFile = File(filePath);
      await pdfFile.writeAsBytes(pdfBytes);
      
      _isDownloadingPdf = false;
      notifyListeners();
      
      return filePath;
      
    } catch (e) {
      _isDownloadingPdf = false;
      _error = 'PDF download failed: $e';
      notifyListeners();
      return null;
    }
  }
  
  /// Share PDF report
  Future<void> sharePdfReport() async {
    if (_riskReport == null) {
      _error = 'No analysis report available';
      notifyListeners();
      return;
    }
    
    try {
      _isDownloadingPdf = true;
      notifyListeners();
      
      // Get PDF bytes from API
      Uint8List pdfBytes = await _apiService.downloadPdfReport(_riskReport!);
      
      // Save to temp directory for sharing
      Directory tempDir = await getTemporaryDirectory();
      String filename = 'APK_Risk_Report_${_riskReport!.packageName}.pdf';
      String filePath = '${tempDir.path}/$filename';
      
      File pdfFile = File(filePath);
      await pdfFile.writeAsBytes(pdfBytes);
      
      _isDownloadingPdf = false;
      notifyListeners();
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'APK Risk Analysis Report for ${_riskReport!.appName}',
      );
      
    } catch (e) {
      _isDownloadingPdf = false;
      _error = 'Share failed: $e';
      notifyListeners();
    }
  }
  
  /// Clear error and reset to appropriate state
  void clearError() {
    _error = null;
    if (_apkInfo != null) {
      _state = AnalysisState.fileSelected;
    } else {
      _state = AnalysisState.idle;
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
