import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

final supabase = Supabase.instance.client;

const EDGE_FUNCTION_URL =
    'https://gnskowrijoouemlptrvr.functions.supabase.co/deepgram-transcribe';
const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imduc2tvd3Jpam9vdWVtbHB0cnZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0Mjc1ODQsImV4cCI6MjA3MDAwMzU4NH0.V1RCUJ6Duf_5iHzkknF58gDS1Q6L8y5xAEnK29xfmsg';

class SupabaseTranscriptionTestScreen extends StatefulWidget {
  const SupabaseTranscriptionTestScreen({super.key});

  @override
  State<SupabaseTranscriptionTestScreen> createState() =>
      _SupabaseTranscriptionTestScreenState();
}

class _SupabaseTranscriptionTestScreenState
    extends State<SupabaseTranscriptionTestScreen> {
  String status = 'idle';
  String? audioUrl;
  Map<String, dynamic>? result;
  String? selectedFileName;
  bool isProcessing = false;

  Future<void> handlePickAndTranscribe() async {
    try {
      setState(() {
        status = 'picking';
        isProcessing = true;
        result = null;
        audioUrl = null;
        selectedFileName = null;
      });

      final res = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (res == null || res.files.isEmpty) {
        setState(() {
          status = 'cancelled';
          isProcessing = false;
        });
        return;
      }

      final file = res.files.first;
      setState(() {
        selectedFileName = file.name;
        status = 'uploading';
      });

      // Upload to public-audio bucket
      final path =
          'uploads/${DateTime.now().millisecondsSinceEpoch}-${file.name}';
      final storageRes =
          await supabase.storage.from('public-audio').uploadBinary(
                path,
                file.bytes!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

      if (storageRes.isEmpty) {
        throw Exception('Upload failed - no response from storage');
      }

      final publicUrl =
          supabase.storage.from('public-audio').getPublicUrl(path);
      setState(() {
        audioUrl = publicUrl;
        status = 'transcribing';
      });

      // Call Edge Function for transcription
      final resp = await http.post(
        Uri.parse(EDGE_FUNCTION_URL),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $SUPABASE_ANON_KEY',
          'apikey': SUPABASE_ANON_KEY,
        },
        body: jsonEncode({'audio_url': publicUrl}),
      );

      final dg = jsonDecode(resp.body);
      if (resp.statusCode != 200) {
        throw Exception(dg['error'] ?? 'Transcription failed');
      }

      setState(() => status = 'saving');

      // Insert into transcripts table using existing schema
      final insertRes = await supabase
          .from('transcripts')
          .insert({
            'audio_url': publicUrl,
            'transcript': dg,
            'status': 'completed',
          })
          .select()
          .single();

      setState(() {
        result = {'deepgram': dg, 'row': insertRes};
        status = 'done';
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        status = 'error: $e';
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appTheme.white_A700,
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(context),
              SizedBox(height: 24),
              _buildActionButton(context),
              SizedBox(height: 16),
              _buildStatusSection(context),
              if (selectedFileName != null) ...[
                SizedBox(height: 12),
                _buildFileInfo(context),
              ],
              if (audioUrl != null) ...[
                SizedBox(height: 12),
                _buildAudioUrlSection(context),
              ],
              if (result != null) ...[
                SizedBox(height: 20),
                _buildResultSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      backgroundColor: appTheme.white_A700,
      height: 108.h,
    );
  }

  /// Section Widget
  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: appTheme.cyan_50,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(
          color: appTheme.blue_200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Audio Transcription Test",
            style: theme.textTheme.titleMedium!.copyWith(
              color: appTheme.cyan_900,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Select an audio file to upload and transcribe using Supabase Edge Functions and Deepgram.",
            style: theme.textTheme.bodyMedium!.copyWith(
              color: appTheme.gray_700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        onPressed: isProcessing ? null : handlePickAndTranscribe,
        style: ElevatedButton.styleFrom(
          backgroundColor: isProcessing ? appTheme.gray_500 : appTheme.blue_A700,
          foregroundColor: appTheme.white_A700,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.h),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing) ...[
              SizedBox(
                width: 20.h,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(appTheme.white_A700),
                ),
              ),
              SizedBox(width: 12.h),
            ],
            Icon(
              isProcessing ? Icons.hourglass_empty : Icons.upload_file,
              size: 24,
            ),
            SizedBox(width: 8.h),
            Text(
              isProcessing ? 'Processing...' : 'Pick & Transcribe Audio',
              style: theme.textTheme.titleMedium!.copyWith(
                color: appTheme.white_A700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildStatusSection(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (status.startsWith('error')) {
      statusColor = appTheme.red_700;
      statusIcon = Icons.error;
    } else if (status == 'done') {
      statusColor = appTheme.green_600;
      statusIcon = Icons.check_circle;
    } else if (isProcessing) {
      statusColor = appTheme.orange_900;
      statusIcon = Icons.sync;
    } else {
      statusColor = appTheme.gray_700;
      statusIcon = Icons.info;
    }

    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: statusColor.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              'Status: $status',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildFileInfo(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.gray_50,
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: appTheme.gray_200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.audio_file,
            color: appTheme.blue_A700,
            size: 20,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              'Selected: $selectedFileName',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: appTheme.gray_900,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildAudioUrlSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.cyan_50,
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: appTheme.blue_200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link,
                color: appTheme.teal_600,
                size: 20,
              ),
              SizedBox(width: 8.h),
              Text(
                'Audio URL:',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: appTheme.cyan_900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            audioUrl!,
            style: theme.textTheme.bodySmall!.copyWith(
              color: appTheme.gray_700,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildResultSection(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: appTheme.gray_50,
          borderRadius: BorderRadius.circular(8.h),
          border: Border.all(
            color: appTheme.gray_300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.data_object,
                  color: appTheme.gray_700,
                  size: 20,
                ),
                SizedBox(width: 8.h),
                Text(
                  'Transcription Result:',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: appTheme.gray_900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.white_A700,
                  borderRadius: BorderRadius.circular(6.h),
                  border: Border.all(
                    color: appTheme.gray_200,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(result),
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: appTheme.gray_900_01,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}