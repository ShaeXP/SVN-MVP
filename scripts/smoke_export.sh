#!/bin/bash
# One-click local smoke test for PII Redaction Export
# Usage: ./scripts/smoke_export.sh <SUPABASE_URL> <ANON_KEY>

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SUPABASE_URL> <ANON_KEY>"
    echo "Example: $0 https://xxx.supabase.co eyJhb..."
    exit 1
fi

SUPABASE_URL=$1
ANON_KEY=$2
REDACT_URL="${SUPABASE_URL}/functions/v1/sv_redact"
PUBLISH_URL="${SUPABASE_URL}/functions/v1/sv_publish_sample"

echo "=== PII Redaction Export Smoke Test ==="
echo ""

# Test 1: Health checks
echo "Test 1: Health checks"
echo "Checking sv_redact health..."
REDACT_HEALTH=$(curl -s -X GET "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}")
echo "$REDACT_HEALTH" | jq .

echo ""
echo "Checking sv_publish_sample health..."
PUBLISH_HEALTH=$(curl -s -X GET "${PUBLISH_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}")
echo "$PUBLISH_HEALTH" | jq .

echo ""
echo "---"
echo ""

# Test 2: Redaction (regex-only)
echo "Test 2: Redaction (regex-only)"
REDACT_RESULT=$(curl -s -X POST "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Contact John Smith at john@example.com or 555-123-4567",
    "featureFlag": true,
    "synthetic": false
  }')

echo "Redaction result:"
echo "$REDACT_RESULT" | jq .

# Verify entities were found
ENTITIES_COUNT=$(echo "$REDACT_RESULT" | jq '.entities | length')
echo "Entities found: $ENTITIES_COUNT"
if [ "$ENTITIES_COUNT" -gt 0 ]; then
    echo "✓ Redaction working"
else
    echo "✗ No entities found"
    exit 1
fi

# Extract redacted text
REDACTED_TEXT=$(echo "$REDACT_RESULT" | jq -r '.redactedText')
ENTITIES_COUNT_BY_TYPE=$(echo "$REDACT_RESULT" | jq '.entitiesCountByType')
USED_PRESIDIO=$(echo "$REDACT_RESULT" | jq -r '.usedPresidio')

echo ""
echo "---"
echo ""

# Test 3: Publish sample
echo "Test 3: Publish sample"
IDEMPOTENCY_KEY=$(uuidgen)
echo "Using Idempotency-Key: $IDEMPOTENCY_KEY"

PUBLISH_RESULT=$(curl -s -X POST "${PUBLISH_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d "{
    \"recording_id\": \"test-$(date +%s)\",
    \"redacted_text\": \"${REDACTED_TEXT}\",
    \"user_id\": \"test-user-123\",
    \"vertical\": \"health\",
    \"entities_count_by_type\": ${ENTITIES_COUNT_BY_TYPE},
    \"used_presidio\": ${USED_PRESIDIO}
  }")

echo "Publish result:"
echo "$PUBLISH_RESULT" | jq .

# Verify success
PUBLIC_URL=$(echo "$PUBLISH_RESULT" | jq -r '.publicUrl')
if [ "$PUBLIC_URL" != "null" ] && [ "$PUBLIC_URL" != "" ]; then
    echo "✓ Publish successful"
    echo "Public URL: $PUBLIC_URL"
else
    echo "✗ Publish failed"
    exit 1
fi

echo ""
echo "---"
echo ""

# Test 4: Idempotency (same key should return same URL)
echo "Test 4: Idempotency test"
IDEMPOTENCY_RESULT=$(curl -s -X POST "${PUBLISH_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: ${IDEMPOTENCY_KEY}" \
  -d "{
    \"recording_id\": \"test-$(date +%s)\",
    \"redacted_text\": \"${REDACTED_TEXT}\",
    \"user_id\": \"test-user-123\",
    \"vertical\": \"health\",
    \"entities_count_by_type\": ${ENTITIES_COUNT_BY_TYPE},
    \"used_presidio\": ${USED_PRESIDIO}
  }")

echo "Idempotency result:"
echo "$IDEMPOTENCY_RESULT" | jq .

IDEMPOTENCY_URL=$(echo "$IDEMPOTENCY_RESULT" | jq -r '.publicUrl')
IDEMPOTENCY_HIT=$(echo "$IDEMPOTENCY_RESULT" | jq -r '.idempotencyHit')

if [ "$IDEMPOTENCY_URL" = "$PUBLIC_URL" ] && [ "$IDEMPOTENCY_HIT" = "true" ]; then
    echo "✓ Idempotency working"
else
    echo "✗ Idempotency failed"
    exit 1
fi

echo ""
echo "---"
echo ""

# Test 5: Synthetic mode
echo "Test 5: Synthetic mode"
SYNTHETIC_RESULT=$(curl -s -X POST "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "ignored",
    "featureFlag": true,
    "synthetic": true
  }')

echo "Synthetic result:"
echo "$SYNTHETIC_RESULT" | jq '.synthetic'
IS_SYNTHETIC=$(echo "$SYNTHETIC_RESULT" | jq -r '.synthetic')
if [ "$IS_SYNTHETIC" = "true" ]; then
    echo "✓ Synthetic mode working"
else
    echo "✗ Synthetic mode failed"
    exit 1
fi

echo ""
echo "=== All smoke tests passed! ==="
echo ""
echo "Summary:"
echo "  - Health checks: ✓"
echo "  - Redaction (regex-only): ✓"
echo "  - Publish sample: ✓"
echo "  - Idempotency: ✓"
echo "  - Synthetic mode: ✓"
echo ""
echo "Public URL created: $PUBLIC_URL"
echo "Manifest URL: $(echo "$PUBLISH_RESULT" | jq -r '.manifestUrl')"
