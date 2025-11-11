# SmartVoiceNotes Pipeline Documentation

## Overview

The SmartVoiceNotes pipeline provides universal ingestion of audio and video files with AI-powered transcription and summarization. The system is designed to be robust, scalable, and user-friendly with proper error handling and retry mechanisms.

## Architecture

```
Client (Flutter) → Supabase Storage → Edge Functions → Deepgram → OpenAI → Database
```

### Components

1. **Client (Flutter)**: File picker, upload UI, real-time status updates
2. **Supabase Storage**: File storage with signed URLs
3. **Edge Functions**: Pipeline orchestration and processing
4. **Deepgram**: Audio/video transcription
5. **OpenAI**: Text summarization and analysis
6. **Database**: Recording metadata, transcripts, and summaries

## Pipeline Flow

### 1. Upload Phase
- User selects audio/video file via file picker
- Client validates file type and size (max 100MB)
- File uploaded to Supabase Storage with MIME type detection
- Recording row created in database with status `uploading`

### 2. Processing Phase
- `sv_run_pipeline` edge function invoked with storage path
- Status updated to `transcribing`
- Signed URL generated for Deepgram access
- Deepgram Pre-Recorded API called with smart formatting

### 3. Transcription Phase
- Deepgram processes the audio/video file
- Transcript saved to `transcripts` table
- Status remains `transcribing` during summarization

### 4. Summarization Phase
- OpenAI GPT-4o-mini called with structured prompt
- Summary saved to `summaries` table
- Status updated to `ready`

### 5. Completion
- User can view transcript and summary in Library
- Real-time updates via Supabase Realtime

## Status Flow

```
local → uploading → transcribing → ready
  ↓         ↓           ↓
error ←──── error ←──── error
```

### Status Definitions

- **local**: File selected but not uploaded
- **uploading**: File being uploaded to storage
- **transcribing**: Audio being transcribed by Deepgram
- **ready**: Transcription and summarization complete
- **error**: Processing failed at any stage

## Error Handling & Retry Logic

### Idempotency
- All external API calls use idempotency keys
- Webhook processing is idempotent based on job IDs
- Safe to retry failed operations

### Retry Strategy
- Exponential backoff for external API calls
- Short timeouts to prevent hanging
- Automatic retry for transient failures

### Fallback Transcoding
- Unsupported formats trigger `sv_transcode_fallback`
- Logs transcode requirement for manual processing
- Status set to `error` with descriptive message

## File Format Support

### Audio Formats
- MP3 (audio/mpeg)
- M4A (audio/m4a)
- WAV (audio/wav)
- AAC (audio/aac)
- FLAC (audio/flac)
- OGG (audio/ogg)
- WMA (audio/x-ms-wma)
- CAF (application/x-caf)

### Video Formats
- MP4 (video/mp4)
- WebM (video/webm)
- MOV (video/quicktime)
- AVI (video/x-msvideo)
- MKV (video/x-matroska)

### MIME Detection
- Server-side MIME sniffing from file headers
- Validates against file extension
- Logs mismatches for debugging

## Security

### Authentication
- Supabase JWT authentication required
- Service role key used for admin operations
- User-scoped RLS policies enforced

### Data Privacy
- API keys stored in edge function secrets only
- No client-side exposure of service credentials
- User data isolated via RLS

### File Validation
- File size limits (100MB for mobile)
- MIME type validation
- Extension whitelist enforcement

## Monitoring & Debugging

### Traceability
- Unique trace ID generated for each pipeline run
- Logged at every step for correlation
- Stored in database for debugging

### Logging
- Structured logging with trace IDs
- Error details in server logs only
- Generic error messages returned to client

### Real-time Updates
- Supabase Realtime subscriptions
- Live status updates in Library
- No polling required

## API Endpoints

### sv_run_pipeline
- **Method**: POST
- **Body**: `{ recording_id, storage_path, trace_id? }`
- **Response**: `{ ok: true, trace, recording_id }`

### sv_transcription_webhook
- **Method**: POST
- **Body**: Deepgram webhook payload
- **Response**: `{ ok: true, trace }`

### sv_transcode_fallback
- **Method**: POST
- **Body**: `{ recording_id, storage_path, original_format }`
- **Response**: `{ ok: true, message, trace }`

## Database Schema

### recordings
- `id` (uuid, primary key)
- `user_id` (uuid, foreign key)
- `created_at` (timestamp)
- `status` (enum: local, uploading, transcribing, ready, error)
- `storage_path` (text)
- `duration_sec` (integer)
- `trace_id` (text)
- `last_error` (text)

### transcripts
- `id` (uuid, primary key)
- `recording_id` (uuid, foreign key)
- `text` (text)
- `confidence` (numeric)
- `language` (text)

### summaries
- `id` (uuid, primary key)
- `recording_id` (uuid, foreign key)
- `title` (text)
- `summary` (text)
- `bullets` (json array)
- `action_items` (json array)
- `tags` (json array)
- `confidence` (numeric)

## Performance Considerations

### Optimization
- Chunked uploads for large files
- Signed URLs for direct Deepgram access
- Minimal database queries
- Efficient realtime subscriptions

### Scaling
- Stateless edge functions
- Database connection pooling
- CDN for file delivery
- Horizontal scaling ready

## Troubleshooting

### Common Issues

1. **Upload Fails**: Check file size and format
2. **Transcription Fails**: Verify Deepgram API key
3. **Summary Fails**: Check OpenAI API key and quota
4. **Status Stuck**: Check edge function logs

### Debug Steps

1. Check trace ID in logs
2. Verify database status
3. Check edge function execution
4. Validate API credentials

## Future Enhancements

### Planned Features
- Batch processing for multiple files
- Speaker diarization support
- Custom transcription models
- Advanced summarization options

### Scalability Improvements
- Queue-based processing
- Distributed transcoding
- Caching layer
- Performance monitoring
