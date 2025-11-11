# Unified Status System Implementation

## Overview

This document describes the implementation of a unified pipeline status system that eliminates "unknown" states and provides a single source of truth for recording status throughout the application.

## Key Components

### 1. Database Schema (`supabase/migrations/20250120000000_create_recording_status_enum.sql`)

- **Postgres Enum**: Created `recording_status` enum with 6 canonical values:
  - `local`, `uploading`, `transcribing`, `summarizing`, `ready`, `error`
- **Schema Updates**: Updated `recordings` table to use the enum with constraints
- **Timestamps**: Added `status_changed_at` for UI staleness guards
- **Migration**: Safely migrates existing string status values to enum

### 2. Dart Domain Model (`lib/domain/recordings/recording_status.dart`)

- **Canonical Enum**: `RecordingStatus` enum with 6 values matching database
- **Strict Validation**: `fromString()` method that logs unsupported values and returns `error`
- **State Properties**: `isTerminal`, `isProcessing`, `isInitial` for state machine logic
- **No Defaults**: Eliminates "unknown" states by coercing invalid values to `error`

### 3. Status Theme Mapping (`lib/ui/status/status_theme.dart`)

- **Single Source of Truth**: Maps each status to UI appearance
- **Consistent Labels**: Standardized labels across all UI components
- **Progress Values**: 0.0-1.0 progress values for each status
- **Animation Keys**: Keys for choosing native Flutter animations
- **Theme Integration**: Adapts to light/dark mode automatically

### 4. State Coordinator (`lib/controllers/recording_state_coordinator.dart`)

- **State Machine**: Enforces valid status transitions
- **Transition Rules**: 
  - `local → uploading → transcribing → summarizing → ready|error`
  - Any invalid transition coerces to `error`
- **Logging**: Structured logging for debugging and monitoring
- **Reactive**: Uses GetX for reactive state management

### 5. Unified UI Components (`lib/ui/widgets/unified_status_chip.dart`)

- **UnifiedStatusChip**: Displays status with native animations
- **UnifiedProgressBar**: Shows linear progress for processing states
- **UnifiedPipelineBanner**: Complete pipeline progress display
- **Native Animations**: Uses `AnimatedSwitcher`, `AnimatedContainer`, `TweenAnimationBuilder`

### 6. Realtime Service (`lib/services/unified_realtime_service.dart`)

- **Supabase Integration**: Subscribes to `recordings` table changes
- **Fallback Polling**: 3-second polling as backup for realtime
- **State Dispatch**: Automatically dispatches status changes to coordinator
- **Navigation**: Handles auto-navigation when status reaches `ready`

## Status Flow

```
local → uploading → transcribing → summarizing → ready
  ↓         ↓            ↓             ↓
error ←─────┴────────────┴─────────────┘
```

## UI Mapping

| Status | Label | Progress | Animation | Icon |
|--------|-------|----------|-----------|------|
| local | "Local" | 0.0 | "idle" | file_upload_outlined |
| uploading | "Uploading…" | 0.15 | "upload" | cloud_upload_outlined |
| transcribing | "Transcribing…" | 0.45 | "transcribe" | mic_outlined |
| summarizing | "Summarizing…" | 0.75 | "summarize" | auto_awesome_outlined |
| ready | "Ready" | 1.0 | "done" | check_circle_outline |
| error | "Failed" | null | "error" | error_outline |

## Edge Function Updates

- **sv_run_pipeline**: Added `summarizing` status step
- **sv_summarize_openai**: Changed `uploaded` to `ready`
- **sv_process_upload**: Already uses correct enum values
- **Status Validation**: All functions now use only the 6 canonical values

## Backward Compatibility

- **Legacy Support**: `PipelineProgress` class delegates to new system
- **Existing UI**: `PipelineProgressBanner` uses new `UnifiedPipelineBanner`
- **Data Migration**: Existing string statuses safely migrated to enum
- **API Compatibility**: No breaking changes to existing APIs

## Testing

- **Unit Tests**: `test/unified_status_test.dart` validates all components
- **State Machine**: Tests valid/invalid transitions
- **Theme Mapping**: Verifies correct UI mappings
- **Error Handling**: Tests unsupported status values

## Benefits

1. **No Unknown States**: All invalid statuses are coerced to `error`
2. **Single Source of Truth**: One enum, one theme mapping, one state machine
3. **Consistent UI**: All status displays use the same labels and styling
4. **Native Animations**: Smooth Flutter animations without third-party packages
5. **Robust Error Handling**: Graceful degradation with retry options
6. **Real-time Updates**: Live status updates via Supabase realtime
7. **State Validation**: Prevents invalid state transitions
8. **Comprehensive Logging**: Detailed logs for debugging and monitoring

## Usage

### Basic Status Display
```dart
UnifiedStatusChip(
  status: RecordingStatus.transcribing,
  showProgress: true,
)
```

### Progress Tracking
```dart
UnifiedProgressBar(
  status: RecordingStatus.uploading,
)
```

### Complete Pipeline Banner
```dart
UnifiedPipelineBanner() // Automatically uses RecordingStateCoordinator
```

### State Management
```dart
final coordinator = Get.find<RecordingStateCoordinator>();
coordinator.dispatch(RecordingStatus.uploading);
```

## Migration Notes

- Database migration must be run before deploying
- Edge functions automatically use new enum values
- Existing UI components continue to work with backward compatibility
- New components should use the unified system for consistency
