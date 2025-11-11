# Presidio Local Setup for PII Redaction Testing

This guide shows how to run Microsoft Presidio locally using Docker Compose for testing the V1 redaction features.

## Quick Start

1. **Start Presidio services**:
   ```bash
   cd docs/redaction
   docker-compose up -d
   ```

2. **Verify services are running**:
   ```bash
   curl http://localhost:5001/health
   curl http://localhost:5002/health
   ```

3. **Set environment variables** in your Supabase Edge Functions:
   ```bash
   PRESIDIO_ANALYZER_URL=http://localhost:5001/analyze
   PRESIDIO_ANONYMIZER_URL=http://localhost:5002/anonymize
   ```

## Docker Compose Configuration

```yaml
version: '3.8'

services:
  presidio-analyzer:
    image: mcr.microsoft.com/presidio-analyzer:latest
    ports:
      - "5001:3000"
    environment:
      - GRPC_CONNECTION_ADDRESS=presidio-analyzer-grpc:3001
    networks:
      - presidio-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  presidio-anonymizer:
    image: mcr.microsoft.com/presidio-anonymizer:latest
    ports:
      - "5002:3000"
    environment:
      - GRPC_CONNECTION_ADDRESS=presidio-anonymizer-grpc:3001
    networks:
      - presidio-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  presidio-analyzer-grpc:
    image: mcr.microsoft.com/presidio-analyzer-grpc:latest
    ports:
      - "5003:3001"
    networks:
      - presidio-network

  presidio-anonymizer-grpc:
    image: mcr.microsoft.com/presidio-anonymizer-grpc:latest
    ports:
      - "5004:3001"
    networks:
      - presidio-network

networks:
  presidio-network:
    driver: bridge
```

## Testing the Setup

### 1. Test Analyzer

```bash
curl -X POST http://localhost:5001/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "text": "John Smith called from 555-123-4567 about his appointment on 2024-01-15",
    "language": "en"
  }'
```

**Expected Response**:
```json
[
  {
    "entity_type": "PERSON",
    "start": 0,
    "end": 10,
    "score": 0.95
  },
  {
    "entity_type": "PHONE_NUMBER",
    "start": 32,
    "end": 44,
    "score": 0.98
  },
  {
    "entity_type": "DATE_TIME",
    "start": 75,
    "end": 85,
    "score": 0.99
  }
]
```

### 2. Test Anonymizer

```bash
curl -X POST http://localhost:5002/anonymize \
  -H "Content-Type: application/json" \
  -d '{
    "text": "John Smith called from 555-123-4567 about his appointment on 2024-01-15",
    "analyzer_results": [
      {
        "entity_type": "PERSON",
        "start": 0,
        "end": 10,
        "score": 0.95
      },
      {
        "entity_type": "PHONE_NUMBER", 
        "start": 32,
        "end": 44,
        "score": 0.98
      },
      {
        "entity_type": "DATE_TIME",
        "start": 75,
        "end": 85,
        "score": 0.99
      }
    ],
    "anonymizers": {
      "DEFAULT": {"type": "replace", "new_value": "[REDACTED]"},
      "PERSON": {"type": "replace", "new_value": "[NAME]"},
      "PHONE_NUMBER": {"type": "replace", "new_value": "[PHONE]"},
      "DATE_TIME": {"type": "replace", "new_value": "[DATE]"}
    }
  }'
```

**Expected Response**:
```json
{
  "text": "[NAME] called from [PHONE] about his appointment on [DATE]",
  "items": [
    {
      "entity_type": "PERSON",
      "start": 0,
      "end": 6,
      "score": 0.95
    },
    {
      "entity_type": "PHONE_NUMBER",
      "start": 22,
      "end": 28,
      "score": 0.98
    },
    {
      "entity_type": "DATE_TIME",
      "start": 55,
      "end": 60,
      "score": 0.99
    }
  ]
}
```

## Integration with Edge Functions

### Update Supabase Environment

1. **Local Development**:
   ```bash
   supabase functions serve --env-file .env.local
   ```

2. **Production Deployment**:
   ```bash
   supabase functions deploy sv_redact --env-file .env.production
   supabase functions deploy sv_publish_sample --env-file .env.production
   ```

### Environment Variables

Create `.env.local`:
```bash
# Presidio URLs (local)
PRESIDIO_ANALYZER_URL=http://localhost:5001/analyze
PRESIDIO_ANONYMIZER_URL=http://localhost:5002/anonymize

# Feature flags
SVN_REDACTION_FEATURE_FLAG=true
SVN_SERVER_SIDE_PDF=false
```

## Performance Testing

### Load Testing

```bash
# Test analyzer performance
for i in {1..10}; do
  curl -X POST http://localhost:5001/analyze \
    -H "Content-Type: application/json" \
    -d '{"text": "Patient John Doe (MRN: 12345) called from 555-123-4567 about appointment on 2024-01-15", "language": "en"}' \
    -w "Time: %{time_total}s\n" &
done
wait
```

### Timeout Testing

```bash
# Test with large text (should complete within 1s timeout)
curl -X POST http://localhost:5001/analyze \
  -H "Content-Type: application/json" \
  -d '{"text": "'$(python3 -c "print('Patient John Doe called. ' * 1000)")'", "language": "en"}' \
  -w "Time: %{time_total}s\n"
```

## Troubleshooting

### Common Issues

1. **Services not starting**:
   ```bash
   docker-compose logs presidio-analyzer
   docker-compose logs presidio-anonymizer
   ```

2. **Connection refused**:
   - Check if ports 5001-5004 are available
   - Verify Docker is running
   - Check firewall settings

3. **GRPC connection errors**:
   - Ensure all services are running
   - Check network connectivity between containers
   - Restart services: `docker-compose restart`

### Health Checks

```bash
# Check all services
curl http://localhost:5001/health  # Analyzer
curl http://localhost:5002/health  # Anonymizer
curl http://localhost:5003/health  # Analyzer GRPC
curl http://localhost:5004/health  # Anonymizer GRPC
```

### Resource Usage

```bash
# Monitor resource usage
docker stats

# Check logs
docker-compose logs -f
```

## Production Considerations

### Scaling

For production use, consider:

1. **Load Balancer**: Use nginx or similar to distribute load
2. **Multiple Instances**: Scale analyzer/anonymizer services
3. **Caching**: Cache analyzer results for repeated text
4. **Monitoring**: Add Prometheus metrics and Grafana dashboards

### Security

1. **Network Isolation**: Use private networks
2. **Authentication**: Add API keys or JWT tokens
3. **Rate Limiting**: Implement request throttling
4. **Input Validation**: Validate input size and format

### Example Production Setup

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - presidio-analyzer
      - presidio-anonymizer

  presidio-analyzer:
    image: mcr.microsoft.com/presidio-analyzer:latest
    deploy:
      replicas: 3
    environment:
      - GRPC_CONNECTION_ADDRESS=presidio-analyzer-grpc:3001
    networks:
      - presidio-network

  # ... other services
```

## Cleanup

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (if needed)
docker-compose down -v

# Remove images (if needed)
docker rmi mcr.microsoft.com/presidio-analyzer:latest
docker rmi mcr.microsoft.com/presidio-anonymizer:latest
```
