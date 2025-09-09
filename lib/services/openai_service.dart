import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/utils/preview_mode_detector.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  late final Dio _dio;
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  bool _isInitialized = false;

  factory OpenAIService() {
    return _instance;
  }

  OpenAIService._internal() {
    _initializeService();
  }

  void _initializeService() {
    try {
      if (PreviewModeDetector.isPreviewMode) {
        if (_apiKey.isEmpty) {
          debugPrint(
              '🎭 Preview mode: OpenAI API key not configured, using mock service');
          _createMockDio();
          _isInitialized = true;
          return;
        }
      } else {
        if (_apiKey.isEmpty) {
          throw Exception('OPENAI_API_KEY must be provided via --dart-define');
        }
      }

      _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.openai.com/v1',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      _isInitialized = true;
    } catch (e) {
      if (PreviewModeDetector.isPreviewMode) {
        debugPrint('🎭 Preview mode: OpenAI init failed, using mock service');
        _createMockDio();
        _isInitialized = true;
      } else {
        debugPrint('❌ OpenAI service initialization failed: $e');
        rethrow;
      }
    }
  }

  void _createMockDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://mock-api.openai.com/v1',
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Dio get dio => _dio;

  /// Transcribe audio file using OpenAI Whisper with preview mode support
  Future<String> transcribeAudio({
    required File audioFile,
    String model = 'whisper-1',
    String? prompt,
    String responseFormat = 'json',
    String? language,
    double? temperature,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock audio transcription');
      await Future.delayed(Duration(milliseconds: 500)); // Simulate processing
      return 'This is a mock transcription for preview mode. The audio file would normally be transcribed using OpenAI Whisper. This is sample text to demonstrate the transcription functionality.';
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        'model': model,
        if (prompt != null) 'prompt': prompt,
        'response_format': responseFormat,
        if (language != null) 'language': language,
        if (temperature != null) 'temperature': temperature,
      });

      final response = await _dio.post('/audio/transcriptions', data: formData);

      if (responseFormat == 'json') {
        return response.data['text'] ?? '';
      } else {
        return response.data.toString();
      }
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Transcription failed',
      );
    }
  }

  /// Generate AI summary using OpenAI GPT-4 with preview mode support
  Future<AISummaryResponse> generateSummary({
    required String transcriptText,
    String model = 'gpt-4o-mini',
    String? reasoningEffort,
    String? verbosity,
  }) async {
    if (PreviewModeDetector.isPreviewMode) {
      debugPrint('🎭 Preview mode: Mock AI summary generation');
      await Future.delayed(Duration(milliseconds: 800)); // Simulate processing
      return AISummaryResponse(
        summaryText:
            'This is a mock AI-generated summary for preview mode. It demonstrates how the summary feature would work with actual OpenAI integration.',
        actions: [
          'Review the mock transcription',
          'Test the summary functionality',
          'Configure OpenAI API key for production',
          'Verify all preview mode features',
          'Deploy with real AI integration'
        ],
        keypoints: [
          'Preview mode is active',
          'Mock data is being used',
          'OpenAI integration is ready',
          'Timeout handling is implemented',
          'Fallback systems are working'
        ],
      );
    }

    try {
      final prompt = '''
You are an AI assistant that generates structured summaries of audio transcripts. 
Please analyze the following transcript and return a JSON response with exactly this structure:

{
  "summaryText": "A 2-3 sentence summary of the key content",
  "actions": ["action item 1", "action item 2", "action item 3", "action item 4", "action item 5"],
  "keypoints": ["key point 1", "key point 2", "key point 3", "key point 4", "key point 5"]
}

Guidelines:
- summaryText: Provide a concise 2-3 sentence summary of the main topics discussed
- actions: Extract 3-5 actionable items or next steps from the content
- keypoints: Identify 5 key points or important information from the transcript

Transcript to analyze:
$transcriptText
''';

      final requestData = <String, dynamic>{
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_completion_tokens': 1000,
        'response_format': {'type': 'json_object'},
      };

      // Add GPT-5 specific parameters if applicable
      if (model.startsWith('gpt-5') ||
          model.startsWith('o3') ||
          model.startsWith('o4')) {
        if (reasoningEffort != null)
          requestData['reasoning_effort'] = reasoningEffort;
        if (verbosity != null) requestData['verbosity'] = verbosity;
      } else {
        // Add temperature for non-GPT-5 models
        requestData['temperature'] = 0.3;
      }

      final response = await _dio.post('/chat/completions', data: requestData);

      final content = response.data['choices'][0]['message']['content'];
      final parsedJson = jsonDecode(content) as Map<String, dynamic>;

      return AISummaryResponse(
        summaryText: parsedJson['summaryText'] ?? '',
        actions: List<String>.from(parsedJson['actions'] ?? []),
        keypoints: List<String>.from(parsedJson['keypoints'] ?? []),
      );
    } on DioException catch (e) {
      throw OpenAIException(
        statusCode: e.response?.statusCode ?? 500,
        message: e.response?.data?['error']?['message'] ??
            e.message ??
            'Summary generation failed',
      );
    } catch (e) {
      throw OpenAIException(
        statusCode: 500,
        message: 'Failed to parse AI response: $e',
      );
    }
  }
}

class AISummaryResponse {
  final String summaryText;
  final List<String> actions;
  final List<String> keypoints;

  AISummaryResponse({
    required this.summaryText,
    required this.actions,
    required this.keypoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'summaryText': summaryText,
      'actions': actions,
      'keypoints': keypoints,
    };
  }

  factory AISummaryResponse.fromJson(Map<String, dynamic> json) {
    return AISummaryResponse(
      summaryText: json['summaryText'] ?? '',
      actions: List<String>.from(json['actions'] ?? []),
      keypoints: List<String>.from(json['keypoints'] ?? []),
    );
  }
}

class OpenAIException implements Exception {
  final int statusCode;
  final String message;

  OpenAIException({required this.statusCode, required this.message});

  @override
  String toString() => 'OpenAIException: $statusCode - $message';
}
