// supabase/functions/sv_run_pipeline/send_email.ts
// Resend email helper for transactional emails

import { Resend } from 'npm:resend@3';

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FROM_EMAIL = Deno.env.get("FROM_EMAIL") || "SmartVoiceNotes <notifications@updates.smartvoicenotes.com>";

if (!RESEND_API_KEY) {
  throw new Error("RESEND_API_KEY environment variable is required");
}

const resend = new Resend(RESEND_API_KEY);

export interface SendSummaryEmailParams {
  to: string;
  subject: string;
  html: string;
  text: string;
  traceId: string;
  replyTo?: string;
}

export async function sendSummaryEmail({
  to,
  subject,
  html,
  text,
  traceId,
  replyTo = "support@updates.smartvoicenotes.com"
}: SendSummaryEmailParams): Promise<{ id: string }> {
  try {
    const result = await resend.emails.send({
      from: FROM_EMAIL,
      to: [to],
      subject,
      html,
      text,
      reply_to: replyTo
    }, {
      headers: {
        "Idempotency-Key": `sv-email-${traceId}`
      }
    });

    if (result.error) {
      throw new Error(`Resend API error: ${result.error.message}`);
    }

    if (!result.data?.id) {
      throw new Error("Resend returned no message ID");
    }

    return { id: result.data.id };
  } catch (error) {
    console.error('[send_email] failed', { 
      traceId, 
      to, 
      error: error instanceof Error ? error.message : String(error) 
    });
    throw error;
  }
}
