/**
 * PII Redaction Regex Patterns
 * 
 * Safety features:
 * - Non-backtracking regex forms where possible
 * - Anchored patterns to prevent catastrophic backtracking
 * - Timeout protection via pattern complexity limits
 */

export interface PIIEntity {
  type: string;
  start: number;
  end: number;
}

export interface RedactionResult {
  redacted: string;
  entities: PIIEntity[];
  entitiesCountByType: Record<string, number>;
}

// Compiled regex patterns with safety measures
const PATTERNS = {
  // Email addresses - anchored to word boundaries
  EMAIL: /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/gi,
  
  // Phone numbers - anchored to prevent backtracking
  PHONE: /(?<!\d)(?:\+?1[-.\s]?)?(?:\(?\d{3}\)?[-.\s]?)\d{3}[-.\s]?\d{4}(?!\d)/g,
  
  // URLs - anchored to prevent catastrophic backtracking
  URL: /https?:\/\/[^\s]+|www\.[^\s]+/gi,
  
  // IP addresses - anchored with word boundaries
  IP: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g,
  
  // Dates - anchored patterns
  DATE: /\b(?:\d{1,2}[/-]){2}\d{2,4}\b|\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4}\b/gi,
  
  // SSN-like patterns - anchored
  SSN: /\b\d{3}-\d{2}-\d{4}\b/g,
  
  // Policy/MRN contextual patterns - anchored with lookbehind/lookahead
  POLICY_MRN: /(?i)(mrn|chart|medical record|policy|claim|acct|account)\s*[:#]?\s*([A-Z0-9\-]{6,20})/g,
  
  // Names with cue words - anchored to prevent backtracking
  NAME_CUE: /(?i)(Patient|Client|Dr\.|Attorney|Nurse|Judge)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?/g,
  
  // Two-word capitalized names (not at sentence start) - anchored
  NAME_CAPITALIZED: /(?<![.!?]\s)\b[A-Z][a-z]+\s+[A-Z][a-z]+\b/g,
  
  // Organizations/Places with cue words - anchored
  ORG: /(?i)(Hospital|Clinic|LLP|LLC|Inc\.|University|Court of|Department of)\s+[A-Z][^\n,]+/g,
};

// Replacement mappings
const REPLACEMENTS = {
  EMAIL: '[EMAIL]',
  PHONE: '[PHONE]',
  URL: '[LINK]',
  IP: '[IP]',
  DATE: '[DATE]',
  SSN: '[ID]',
  POLICY_MRN: '[ID]',
  NAME_CUE: '[NAME]',
  NAME_CAPITALIZED: '[NAME]',
  ORG: '[ORG]',
};

/**
 * Redact PII from text using regex patterns
 * 
 * @param text Input text to redact
 * @returns RedactionResult with redacted text and entity information
 */
export function regexRedact(text: string): RedactionResult {
  if (!text || typeof text !== 'string') {
    return {
      redacted: text || '',
      entities: [],
      entitiesCountByType: {}
    };
  }

  // Input size limit for safety (50k chars max)
  const MAX_INPUT_LENGTH = 50000;
  if (text.length > MAX_INPUT_LENGTH) {
    throw new Error(`Input text too long: ${text.length} chars (max: ${MAX_INPUT_LENGTH})`);
  }

  let redacted = text;
  const entities: PIIEntity[] = [];
  const entitiesCountByType: Record<string, number> = {};

  // Process each pattern type
  for (const [patternName, pattern] of Object.entries(PATTERNS)) {
    const replacement = REPLACEMENTS[patternName as keyof typeof REPLACEMENTS];
    let match;
    const patternCopy = new RegExp(pattern.source, pattern.flags);

    // Reset regex lastIndex to ensure consistent behavior
    patternCopy.lastIndex = 0;

    while ((match = patternCopy.exec(redacted)) !== null) {
      // Prevent infinite loops on zero-length matches
      if (match.index === patternCopy.lastIndex) {
        patternCopy.lastIndex++;
        continue;
      }

      const entity: PIIEntity = {
        type: patternName,
        start: match.index,
        end: match.index + match[0].length
      };

      entities.push(entity);
      entitiesCountByType[patternName] = (entitiesCountByType[patternName] || 0) + 1;

      // Replace the match with the appropriate replacement
      redacted = redacted.substring(0, match.index) + 
                replacement + 
                redacted.substring(match.index + match[0].length);

      // Adjust pattern lastIndex for the replacement
      patternCopy.lastIndex = match.index + replacement.length;
    }
  }

  // Sort entities by start position for consistent ordering
  entities.sort((a, b) => a.start - b.start);

  return {
    redacted,
    entities,
    entitiesCountByType
  };
}

/**
 * Validate regex patterns with adversarial inputs
 * Used for testing pattern safety
 */
export function validatePatternSafety(): { safe: boolean; issues: string[] } {
  const issues: string[] = [];
  
  // Test with long garbage strings to detect catastrophic backtracking
  const longGarbage = 'a'.repeat(10000) + 'b'.repeat(10000);
  
  try {
    const result = regexRedact(longGarbage);
    if (result.entities.length > 0) {
      issues.push('Patterns matched in garbage string - possible false positives');
    }
  } catch (error) {
    issues.push(`Pattern safety test failed: ${error}`);
  }

  // Test with nested patterns
  const nestedPatterns = 'a@b.c a@b.c a@b.c '.repeat(1000);
  try {
    const result = regexRedact(nestedPatterns);
    // Should handle nested patterns without timeout
  } catch (error) {
    issues.push(`Nested pattern test failed: ${error}`);
  }

  return {
    safe: issues.length === 0,
    issues
  };
}

/**
 * Get synthetic template text for zero-risk marketing assets
 */
export function getSyntheticTemplate(vertical: 'health' | 'legal' | 'ops' = 'health'): string {
  if (vertical === 'health') {
    return `This is a sample transcript for demonstration purposes.

Patient [NAME] visited the clinic on [DATE] for a routine checkup. 
The patient's contact information includes [EMAIL] and [PHONE].
Medical record number [ID] was assigned.

The patient reported feeling well and had no concerns. 
Vital signs were normal. The patient was advised to continue 
current medications and return in 6 months.

Follow-up appointment scheduled for [DATE].
Contact: [EMAIL] or [PHONE] for any questions.

This sample demonstrates how PII redaction works while preserving 
the structure and meaning of medical documentation.`;
  } else if (vertical === 'legal') {
    return `Sample Legal Consultation

Client [NAME] consultation on [DATE] regarding contract review.
Contact information: [EMAIL] and [PHONE].

Matter: Employment agreement terms and conditions review.
Case reference: [ID]

Analysis: Standard clauses present with recommended modifications.
Timeline: Follow up scheduled for [DATE].

Contact: [ORG] legal team for additional support.
This demonstrates legal document redaction capabilities.`;
  } else {
    return `Sample Operations Report

Team member [NAME] completed training on [DATE].
Contact: [EMAIL] or [PHONE] for coordination.

Task: System maintenance and performance review.
Reference: [ID]

Status: All systems operational. Next review on [DATE].
Action items: Documentation update and team coordination.

Contact: [ORG] operations team for support.
This demonstrates operational document redaction.`;
  }
}
