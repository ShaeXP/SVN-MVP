import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lashae_s_application/env.dart';
import 'upload_models.dart';

class UploadController extends GetxController {
  final supa = Supabase.instance.client;
  
  // Upload state
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;
  final uploadStatus = ''.obs;
  final errorMessage = ''.obs;
  
  // Upload cancellation
  http.Client? _httpClient;
  
  @override
  void onClose() {
    _httpClient?.close();
    super.onClose();
  }
  
  
  /// Pick and upload audio file
  Future<void> pickAndUploadAudio() async {
    try {
      debugPrint('[UPLOAD] Starting file picker...');
      
      // Check authentication
      final session = supa.auth.currentSession;
      final user = supa.auth.currentUser;
      if (session == null || user == null) {
        errorMessage.value = 'Session expired—please sign in again.';
        return;
      }
      
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m4a', 'mp3', 'wav', 'mp4', 'aac'],
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) {
        debugPrint('[UPLOAD] No file selected');
        return;
      }
      
      // Parse file with strong types and null safety
      final pickedFile = await PickedFile.fromFilePicker(result.files.first);
      if (pickedFile == null) {
        throw UploadError('Could not read selected file');
      }
      
      debugPrint('[UPLOAD] picked file name=${pickedFile.filename} size=${pickedFile.bytes.length} contentType=${pickedFile.contentType}');
      
      // Start upload process
      isUploading.value = true;
      uploadProgress.value = 0.0;
      uploadStatus.value = 'Preparing upload...';
      errorMessage.value = '';
      
      // 1) Get signed upload URL with defensive parsing
      uploadStatus.value = 'Getting upload URL...';
      final signedUpload = await _getSignedUploadUrl(pickedFile.filename, pickedFile.contentType, pickedFile.bytes.length, session.accessToken);
      
      debugPrint('[UPLOAD] signed method=${signedUpload.method} path=${signedUpload.storagePath} recordingId=${signedUpload.recordingId} contentType=${signedUpload.contentType}');
      
      // 2) Upload file with progress using signer's content type
      uploadStatus.value = 'Uploading file...';
      await _uploadWithProgress(signedUpload, pickedFile.bytes);
      
      debugPrint('[UPLOAD] complete status=200');
      
      // 3) Trigger pipeline
      uploadStatus.value = 'Starting processing...';
      final pipelineResult = await _triggerPipeline(signedUpload.recordingId, signedUpload.storagePath, user.email!, session.accessToken);
      
      if (pipelineResult['success']) {
        uploadStatus.value = 'Upload complete! Processing started.';
        Get.snackbar(
          'Upload Complete',
          'Your audio is being processed. Check the Library tab for updates.',
          duration: const Duration(seconds: 4),
        );
        
        // Show trace ID if available
        final traceId = pipelineResult['traceId'];
        if (traceId != null) {
          debugPrint('[PIPELINE] kicked recordingId=${signedUpload.recordingId} traceId=$traceId');
          Get.snackbar(
            'Processing Started',
            'Trace ID: $traceId',
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        throw Exception(pipelineResult['error'] ?? 'Pipeline failed');
      }
      
    } on UploadError catch (e) {
      debugPrint('[UPLOAD] UploadError: $e');
      errorMessage.value = e.message;
      uploadStatus.value = 'Upload failed';
    } catch (e) {
      debugPrint('[UPLOAD] Unexpected error: $e');
      errorMessage.value = 'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}';
      uploadStatus.value = 'Upload failed';
    } finally {
      isUploading.value = false;
      _httpClient?.close();
      _httpClient = null;
    }
  }
  
  /// Get signed upload URL from edge function with strong types
  Future<SignedUpload> _getSignedUploadUrl(String filename, String contentType, int size, String accessToken) async {
    try {
      debugPrint('[UPLOAD] Calling sv_sign_audio_upload for filename=$filename contentType=$contentType size=$size');
      
      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/sv_sign_audio_upload'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'filename': filename,
          'contentType': contentType,
          'size': size,
        }),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[UPLOAD] Signer response: ${data.keys.toList()}');
        
        // Parse with defensive checks
        if (data['success'] != true) {
          throw UploadError('Signer returned success=false: ${data['error'] ?? 'Unknown error'}');
        }
        
        return SignedUpload.fromJson(data);
      } else {
        final errorBody = response.body;
        debugPrint('[UPLOAD] Signer error: ${response.statusCode} - $errorBody');
        throw UploadError('Signer failed (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      debugPrint('[UPLOAD] Signer exception: $e');
      if (e is UploadError) rethrow;
      throw UploadError('Failed to get signed upload URL: $e');
    }
  }
  
  /// Upload file with progress tracking using signer's exact content type
  Future<void> _uploadWithProgress(SignedUpload signed, Uint8List bytes) async {
    debugPrint('[UPLOAD] Starting upload to ${signed.url} with ${signed.contentType}');
    
    _httpClient = http.Client();
    final request = http.Request(signed.method, Uri.parse(signed.url));
    
    // Use signer's exact content type - no guessing
    request.headers['Content-Type'] = signed.contentType;
    
    // Add any additional headers from signer
    if (signed.fields != null) {
      signed.fields!.forEach((key, value) {
        request.headers[key] = value;
      });
    }
    
    request.bodyBytes = bytes;
    
    debugPrint('[UPLOAD] Upload headers: ${request.headers}');
    
    // Simulate progress during upload
    uploadProgress.value = 0.0;
    for (int i = 0; i <= 90; i += 10) {
      uploadProgress.value = i / 100.0;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    final streamedResponse = await _httpClient!.send(request);
    
    if (streamedResponse.statusCode >= 400) {
      final responseBody = await streamedResponse.stream.bytesToString();
      debugPrint('[UPLOAD] Upload failed: ${streamedResponse.statusCode} - $responseBody');
      
      // Provide user-friendly error messages
      if (streamedResponse.statusCode == 400 && responseBody.contains('InvalidRequest')) {
        throw UploadError('Upload was rejected. Try a different file type or smaller file.');
      } else {
        throw UploadError('Upload failed with status ${streamedResponse.statusCode}: $responseBody');
      }
    }
    
    uploadProgress.value = 1.0;
    debugPrint('[UPLOAD] Upload complete: ${streamedResponse.statusCode}');
  }
  
  
  /// Trigger pipeline processing
  Future<Map<String, dynamic>> _triggerPipeline(String recordingId, String storagePath, String email, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/sv_run_pipeline'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recording_id': recordingId,
          'storage_path': storagePath,
          'notify_email': email,
        }),
      );
      
      if (response.statusCode >= 400) {
        return {
          'success': false,
          'error': 'Pipeline failed with status ${response.statusCode}',
        };
      }
      
      final result = jsonDecode(response.body);
      return {
        'success': true,
        'traceId': result['traceId'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Pipeline error: $e',
      };
    }
  }
  
  /// Cancel upload
  void cancelUpload() {
    _httpClient?.close();
    _httpClient = null;
    isUploading.value = false;
    uploadStatus.value = 'Upload cancelled';
  }
}
