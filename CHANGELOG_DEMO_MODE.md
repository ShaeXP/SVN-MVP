# Demo Mode + Redaction Disabled

## Overview
Added a safe, investor-ready demo mode that never exposes PII and cleanly disables redaction until it's ready.

## Changes

### Configuration
- Added `REDACTION_ENABLED=false` and `DEMO_MODE=true` feature flags to `env.json`
- Updated `Env` class to expose these flags via `Env.redactionEnabled` and `Env.demoMode`

### UI Updates
- **Settings Screen**: Added "What's live today" feature status section showing redaction as "Shipping next build"
- **Privacy Card**: Hide redaction toggle when in demo mode
- **Recording Summary**: Show "Demo sample — no PII" status chip in demo mode
- **Library Screen**: Replace status with "Demo sample" in demo mode
- **Upload Screen**: Add "Use Demo Sample (no PII)" checkbox option

### Pipeline Changes
- **Redaction Service**: Pass-through when `REDACTION_ENABLED=false` - returns original text unchanged
- **Edge Function**: `sv_redact` short-circuits with proper logging when disabled
- **Pipeline Logs**: Include `demo: true` flag in pipeline requests when in demo mode

### Demo Sample
- Added demo sample selection on Upload screen
- Fetches `public_redacted_samples/demo_meeting_2min.m4a` from Supabase Storage
- Bypasses file-picker permissions in demo mode

### Analytics & Logging
- Pipeline logs include `demo: true` flag when in demo mode
- Redaction bypass logs include traceId for end-to-end tracing
- Edge function logs `redaction_bypass` event when disabled

## Testing
- Added unit tests for configuration loading
- Added tests for redaction pass-through behavior
- Added tests for UI demo mode indicators

## Files Modified
- `lib/env.dart` - Added feature flag getters
- `assets/config/env.json` - Added new flags
- `lib/presentation/settings_screen/settings_screen.dart` - Added feature status card
- `lib/presentation/settings_screen/widgets/privacy_card.dart` - Hide redaction toggle
- `lib/presentation/recording_summary_screen/recording_summary_screen.dart` - Demo status chip
- `lib/presentation/library/library_screen.dart` - Demo sample indicator
- `lib/presentation/upload_recording_screen/upload_recording_screen.dart` - Demo sample option
- `lib/services/sample_export_service.dart` - Use new redaction flag
- `lib/services/pipeline_service.dart` - Add demo mode tracking
- `supabase/functions/sv_redact/index.ts` - Short-circuit when disabled
- `test/demo_mode_test.dart` - Unit tests

## Guardrails
- No new routes or navigator changes
- No controller renames
- All changes behind feature flags
- Normal mode remains untouched
- Demo mode is safe for investor demos
