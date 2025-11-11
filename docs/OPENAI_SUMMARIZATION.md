# OpenAI Summarization Function

## Overview

The `sv_summarize_openai` Edge Function provides AI-powered summarization using OpenAI's GPT models. It complements the existing `summarize-lite` function with full LLM capabilities.

## Features

- **JWT Authentication**: Verifies user identity before processing
- **Ownership Validation**: Ensures users can only summarize their own recordings
- **Transcript Retrieval**: Fetches transcript text from the database
- **OpenAI Integration**: Uses GPT models for intelligent summarization
- **Structured Output**: Returns consistent JSON format
- **Database Integration**: Upserts summaries and updates recording status

## Environment Variables

Set these secrets in Supabase:

```bash
supabase secrets set OPENAI_API_KEY=your_openai_api_key
supabase secrets set SUMMARY_MODEL=gpt-4o-mini
```

### Available Models

- `gpt-4o-mini` (recommended for cost/performance balance)
- `gpt-4o`
- `gpt-4-turbo`
- `gpt-3.5-turbo`

## API Usage

### Request

```typescript
POST /functions/v1/sv_summarize_openai
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "recordingId": "uuid-string"
}
```

### Response

```typescript
{
  "ok": true,
  "summaryId": "uuid-string"
}
```

### Error Responses

- `400`: Missing recordingId
- `401`: Unauthorized (invalid/missing JWT)
- `404`: Recording not found
- `422`: No transcript available
- `500`: LLM processing failed or database error

## Data Flow

1. **Authentication**: Verify JWT and extract user ID
2. **Validation**: Check recordingId format and ownership
3. **Transcript Retrieval**: Fetch transcript text from database
4. **OpenAI Processing**: Generate structured summary using GPT
5. **Database Update**: Upsert summary and mark recording as ready

## Database Schema

### Input Tables

- `recordings`: Contains recording metadata and transcript_id
- `transcripts`: Contains transcript text by ID

### Output Tables

- `summaries`: Upserted with generated content
- `recordings`: Status updated to 'ready'

## Summary Output Format

The function generates summaries with this structure:

```json
{
  "title": "Meeting Title",
  "summary": "Brief overview of the content",
  "bullets": ["Key point 1", "Key point 2"],
  "actionItems": ["Action 1", "Action 2"],
  "tags": ["tag1", "tag2"],
  "confidence": 0.85
}
```

## Deployment

```bash
# Deploy the function
supabase functions deploy sv_summarize_openai

# Set environment variables
supabase secrets set OPENAI_API_KEY=your_key
supabase secrets set SUMMARY_MODEL=gpt-4o-mini
```

## Testing

```bash
# Test with a recording ID
supabase functions invoke sv_summarize_openai \
  --data '{"recordingId":"your-recording-id"}'
```

## Integration with Frontend

Use this function when `SUMMARY_ENGINE=openai` is set in your environment:

```typescript
// In your frontend code
const engine = process.env.SUMMARY_ENGINE || 'lite';
const functionUrl = engine === 'openai' 
  ? 'sv_summarize_openai' 
  : 'summarize-lite';

// Call the appropriate function
const response = await supabase.functions.invoke(functionUrl, {
  body: { recordingId }
});
```

## Error Handling

The function includes comprehensive error handling:

- **Input validation**: Checks for required parameters
- **Authentication**: Validates JWT tokens
- **Authorization**: Ensures user owns the recording
- **Data availability**: Verifies transcript exists
- **LLM errors**: Handles OpenAI API failures gracefully
- **Database errors**: Manages upsert and update failures

## Performance Considerations

- **Model selection**: Choose appropriate model based on cost/quality needs
- **Temperature**: Set to 0.2 for consistent, deterministic output
- **Response format**: Uses JSON mode for structured output
- **Error recovery**: Includes fallback mechanisms for common failures

## Security

- **JWT verification**: Required for all requests
- **User isolation**: Users can only access their own data
- **Input sanitization**: Validates all input parameters
- **Error information**: Limits sensitive data in error responses
