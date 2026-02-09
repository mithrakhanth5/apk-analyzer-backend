/// File service for APK selection and hashing
/// Supports large files (up to 200MB) using streaming hash calculation

import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import '../models/models.dart';
import '../config/constants.dart';

class FileService {
  /// Select an APK file using Storage Access Framework
  /// Returns ApkInfo with file path and metadata (hash calculated separately for large files)
  Future<ApkInfo?> selectApkFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
        allowMultiple: false,
        withData: false, // Don't load into memory - use path for large files
      );
      
      if (result == null || result.files.isEmpty) {
        return null;
      }
      
      PlatformFile file = result.files.first;
      
      // Validate file path exists
      if (file.path == null || file.path!.isEmpty) {
        throw Exception('Could not get file path');
      }
      
      // Validate file size
      if (file.size > AppConstants.maxApkSize) {
        throw Exception('APK file too large (max ${AppConstants.maxApkSize ~/ (1024 * 1024)} MB)');
      }
      
      // Calculate SHA-256 hash using streaming for large files
      String hash = await _calculateSha256FromFile(file.path!);
      
      return ApkInfo(
        fileName: file.name,
        filePath: file.path!,
        fileSize: file.size,
        sha256Hash: hash,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  /// Read APK file bytes - for sending to API
  /// Warning: For large files, this loads entire file into memory
  Future<Uint8List?> readApkBytes(String filePath) async {
    try {
      if (filePath.isEmpty) return null;
      return await File(filePath).readAsBytes();
    } catch (e) {
      return null;
    }
  }
  
  /// Calculate SHA-256 hash from file using streaming (memory efficient)
  Future<String> _calculateSha256FromFile(String filePath) async {
    final file = File(filePath);
    final sink = AccumulatorSink<Digest>();
    final digestSink = sha256.startChunkedConversion(sink);
    
    // Read file in chunks to avoid memory issues
    final stream = file.openRead();
    await for (final chunk in stream) {
      digestSink.add(chunk);
    }
    digestSink.close();
    
    return sink.events.first.toString();
  }
  
  /// Calculate SHA-256 hash of bytes (for smaller data)
  String _calculateSha256(Uint8List bytes) {
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify file integrity by comparing hashes
  bool verifyIntegrity(Uint8List bytes, String expectedHash) {
    String actualHash = _calculateSha256(bytes);
    return actualHash == expectedHash;
  }
}

/// Helper class for streaming hash calculation
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = [];
  
  @override
  void add(T event) => events.add(event);
  
  @override
  void close() {}
}
