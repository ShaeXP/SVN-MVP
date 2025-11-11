#!/bin/bash
# Smoke tests for PII Redaction Edge Functions
# Usage: ./smoke_test.sh <SUPABASE_URL> <ANON_KEY>

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

echo "=== PII Redaction Smoke Tests ==="
echo ""

# Test 1: Health checks
echo "Test 1: Health checks"
echo "Checking sv_redact health..."
curl -s -X GET "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" | jq .

echo ""
echo "Checking sv_publish_sample health..."
curl -s -X GET "${PUBLISH_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" | jq .

echo ""
echo "---"
echo ""

# Test 2: Happy path (regex-only redaction)
echo "Test 2: Happy path - regex redaction"
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

echo ""
echo "---"
echo ""

# Test 3: Synthetic mode
echo "Test 3: Synthetic mode"
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
echo "---"
echo ""

# Test 4: Oversized input (should return 413)
echo "Test 4: Oversized input (should return 413)"
OVERSIZE_TEXT=$(python3 -c "print('a' * 60000)")
OVERSIZE_RESULT=$(curl -s -w "\n%{http_code}" -X POST "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"${OVERSIZE_TEXT}\", \"featureFlag\": true}")

HTTP_CODE=$(echo "$OVERSIZE_RESULT" | tail -n1)
echo "HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "413" ]; then
    echo "✓ Oversized input rejected correctly"
else
    echo "✗ Oversized input not handled correctly (expected 413, got $HTTP_CODE)"
    exit 1
fi

echo ""
echo "---"
echo ""

# Test 5: Feature flag OFF (should passthrough)
echo "Test 5: Feature flag OFF (should passthrough)"
PASSTHROUGH_RESULT=$(curl -s -X POST "${REDACT_URL}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "john@example.com",
    "featureFlag": false
  }')

PASSTHROUGH_TEXT=$(echo "$PASSTHROUGH_RESULT" | jq -r '.redactedText')
if [ "$PASSTHROUGH_TEXT" = "john@example.com" ]; then
    echo "✓ Feature flag OFF - passthrough working"
else
    echo "✗ Feature flag OFF - passthrough failed"
    exit 1
fi

echo ""
echo "---"
echo ""

echo "=== All smoke tests passed! ==="
echo ""
echo "Required environment variables for Edge Functions:"
echo "  - SUPABASE_URL"
echo "  - SUPABASE_SERVICE_ROLE_KEY (for sv_publish_sample)"
echo "  - PRESIDIO_ANALYZER_URL (optional)"
echo "  - PRESIDIO_ANONYMIZER_URL (optional)"
echo "  - SVN_REDACTION_FEATURE_FLAG (default: false)"
echo ""
echo "Test idempotency with:"
echo "  IDEMPOTENCY_KEY=\$(uuidgen)"
echo "  curl -X POST \"${PUBLISH_URL}\" \\"
echo "    -H \"Authorization: Bearer \${ANON_KEY}\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -H \"Idempotency-Key: \${IDEMPOTENCY_KEY}\" \\"
echo "    -d '{\"recording_id\":\"test\",\"redacted_text\":\"Sample\",\"user_id\":\"test\"}'"
