# Privacy Policy for PII Redaction Feature

## Overview

The PII redaction feature is designed with privacy-first principles. This document explains how personal information is handled when users export de-identified samples.

## Data Handling Principles

### 1. Originals Remain Private
- **Your original recordings stay completely private**
- Original audio files remain in private storage buckets
- Original transcripts and summaries are never made public
- Only you have access to your original data

### 2. Public Samples Are Redacted Artifacts
- Public samples are **completely de-identified versions** of your content
- All personally identifiable information is removed or generalized
- Redacted samples cannot be traced back to you or your original recordings
- Public samples are safe to share without privacy concerns

### 3. What Gets Redacted

The system automatically removes or generalizes:

| Type | Example | Replacement |
|------|---------|-------------|
| Email addresses | `john@example.com` | `[EMAIL]` |
| Phone numbers | `555-123-4567` | `[PHONE]` |
| Names | `John Smith` | `[NAME]` |
| Dates | `January 15, 2024` | `[DATE]` |
| URLs | `https://example.com` | `[LINK]` |
| IP addresses | `192.168.1.1` | `[IP]` |
| Medical record numbers | `MRN: 12345` | `[ID]` |
| Organizations | `General Hospital` | `[ORG]` |

### 4. Logging and Monitoring

**What we log (counts only)**:
- Number of entities redacted by type
- Processing duration
- Success/failure status
- File sizes (in bytes)

**What we NEVER log**:
- Raw text content
- Personal information
- User-identifiable data
- Redacted content

**Example log entry**:
```json
{
  "entities_total": 5,
  "entities_by_type": {"EMAIL": 2, "PHONE": 1, "NAME": 2},
  "processing_ms": 150,
  "success": true
}
```

## Storage and Access

### Public Storage
- **Location**: `public_redacted_samples` bucket
- **Path structure**: `samples/{userId}/{year}/{month}/{day}/{uuid}.pdf`
- **Access**: Anyone with the URL can view the PDF
- **Security**: Path-scoped read access (no bucket enumeration possible)

### Private Storage (Unchanged)
- **Your recordings**: Remain in private `recordings` bucket
- **Your transcripts**: Stay in your private database
- **Your summaries**: Remain private to you
- **Access**: Only you can access your original data

## Data Retention

### Public Samples
- **Retention**: Indefinite (until you delete them)
- **Deletion**: You can request deletion of specific public samples
- **Backup**: Public samples are not backed up (they're disposable)

### Your Original Data
- **Retention**: Follows your account settings
- **Backup**: Your original recordings are backed up
- **Deletion**: You control deletion of your original data

## Security Measures

### 1. Fail-Closed Design
- If redaction fails, **no public file is created**
- Errors are logged without exposing sensitive data
- Users see friendly error messages only

### 2. Input Validation
- Maximum input size: 50,000 characters
- Timeout protection: 10 seconds maximum processing
- Malformed input is rejected safely

### 3. Access Controls
- **Public samples**: Read-only access for anyone with URL
- **Original data**: Private to you only
- **Admin access**: Service role only for technical operations

## Your Rights

### 1. Control Over Public Samples
- **Create**: You choose which recordings to export
- **Delete**: You can request deletion of specific public samples
- **Monitor**: You can see which samples you've made public

### 2. Control Over Original Data
- **Access**: You can always access your original recordings
- **Delete**: You can delete your original recordings anytime
- **Export**: You can export your original data (separate from public samples)

### 3. Transparency
- **Logs**: You can request information about what was redacted (counts only)
- **Process**: The redaction process is documented and auditable
- **Code**: The redaction logic is open for review

## Synthetic Mode

When you enable "Use synthetic text (no real data)":

- **Zero risk**: No real data from your recordings is used
- **Template text**: Uses pre-written sample content
- **Same process**: Redaction is applied to template text
- **Marketing safe**: Perfect for demonstrations and marketing

## Compliance

### GDPR Compliance
- **Right to be forgotten**: You can delete public samples
- **Data minimization**: Only necessary data is processed
- **Purpose limitation**: Public samples are for sharing only
- **Transparency**: This document explains all processing

### HIPAA Considerations
- **De-identification**: All PHI is removed or generalized
- **Safe Harbor**: Redacted samples meet safe harbor requirements
- **No re-identification**: Redacted data cannot be linked back to individuals
- **Audit trail**: All redaction actions are logged (counts only)

## Contact and Support

### Questions About Privacy
- **Email**: privacy@smartvoicenotes.com
- **Response time**: Within 48 hours
- **Scope**: Privacy questions only

### Data Requests
- **Access**: Request logs about your redaction activity
- **Deletion**: Request deletion of specific public samples
- **Correction**: Report issues with redaction quality

### Security Issues
- **Report**: security@smartvoicenotes.com
- **Response**: Within 24 hours for security issues
- **Scope**: Security vulnerabilities and data breaches

## Changes to This Policy

### Notification
- **Email**: We'll email you about significant changes
- **In-app**: We'll show notifications for important updates
- **Version**: This document is versioned and dated

### Your Consent
- **Continued use**: Using the feature after changes indicates acceptance
- **Opt-out**: You can disable the feature anytime
- **Questions**: Contact us if you have concerns about changes

---

**Last Updated**: January 19, 2024  
**Version**: 1.0  
**Effective Date**: January 19, 2024

---

*This privacy policy applies specifically to the PII redaction feature. For our general privacy policy, please see our main privacy documentation.*
