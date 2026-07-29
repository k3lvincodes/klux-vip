import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from 'https://deno.land/std@0.224.0/crypto/mod.ts'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const resendApiKey = Deno.env.get('RESEND_API_KEY')
const webhookSecret = Deno.env.get('DIDIT_WEBHOOK_SECRET')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')
if (!webhookSecret) throw new Error('Missing DIDIT_WEBHOOK_SECRET environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

const WEBHOOK_SIG_HEADER = 'x-didit-signature'

async function verifySignature(rawBody: string, signature: string): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(webhookSecret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['verify'],
  )
  const sigBytes = hexToBytes(signature)
  return await crypto.subtle.verify('HMAC', key, sigBytes, new TextEncoder().encode(rawBody))
}

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2)
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16)
  }
  return bytes
}

async function sendEmail(to: string, subject: string, html: string): Promise<boolean> {
  if (!resendApiKey) {
    return false
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Klux VIP <noreply@kluxvip.com>',
        to: [to],
        subject,
        html,
      }),
    })

    if (!response.ok) {
      const errorBody = await response.text()
    }

    return response.ok
  } catch (error) {
    return false
  }
}

function buildEmailContent(status: string, rejectionReason: string | null): { subject: string; html: string } {
  if (status === 'approved') {
    return {
      subject: 'Identity Verification Approved - Klux VIP',
      html: `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden;">
    <tr>
      <td style="padding: 40px 32px 24px; text-align: center; background: linear-gradient(135deg, #d4a853, #f5d78e);">
        <h1 style="color: #1a1a1a; font-size: 28px; margin: 0;">Klux VIP</h1>
      </td>
    </tr>
    <tr>
      <td style="padding: 32px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <div style="width: 64px; height: 64px; background-color: #22c55e; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center;">
            <span style="color: white; font-size: 32px;">&#10003;</span>
          </div>
        </div>
        <h2 style="color: #22c55e; font-size: 22px; text-align: center; margin: 0 0 16px;">Verification Approved</h2>
        <p style="color: #4a4a4a; font-size: 15px; line-height: 1.6; margin: 0 0 16px;">Your identity verification has been approved!</p>
        <p style="color: #4a4a4a; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">You can now complete your vehicle registration and start driving with Klux VIP.</p>
        <p style="color: #888888; font-size: 13px; line-height: 1.5; margin: 0;">Safe driving,<br>The Klux VIP Team</p>
      </td>
    </tr>
  </table>
</body>
</html>`,
    }
  }

  return {
    subject: 'Identity Verification Declined - Klux VIP',
    html: `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
  <table role="presentation" style="width: 100%; max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden;">
    <tr>
      <td style="padding: 40px 32px 24px; text-align: center; background: linear-gradient(135deg, #d4a853, #f5d78e);">
        <h1 style="color: #1a1a1a; font-size: 28px; margin: 0;">Klux VIP</h1>
      </td>
    </tr>
    <tr>
      <td style="padding: 32px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <div style="width: 64px; height: 64px; background-color: #ef4444; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center;">
            <span style="color: white; font-size: 32px;">&#10007;</span>
          </div>
        </div>
        <h2 style="color: #ef4444; font-size: 22px; text-align: center; margin: 0 0 16px;">Verification Declined</h2>
        <p style="color: #4a4a4a; font-size: 15px; line-height: 1.6; margin: 0 0 16px;">Your identity verification was not approved.</p>
        ${rejectionReason ? `<p style="color: #4a4a4a; font-size: 15px; line-height: 1.6; margin: 0 0 16px;">Reason: <strong style="color: #ef4444;">${rejectionReason}</strong></p>` : ''}
        <p style="color: #4a4a4a; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">Please open the Klux VIP app and try again with a clear photo of your ID and face in good lighting.</p>
        <p style="color: #888888; font-size: 13px; line-height: 1.5; margin: 0;">Best regards,<br>The Klux VIP Team</p>
      </td>
    </tr>
  </table>
</body>
</html>`,
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const rawBody = await req.text()
    const signature = req.headers.get(WEBHOOK_SIG_HEADER)

    if (!signature) {
      return new Response(
        JSON.stringify({ error: 'Missing signature header' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const valid = await verifySignature(rawBody, signature)
    if (!valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const payload = JSON.parse(rawBody)

    const event = payload.event || ''
    const session = payload.session || payload
    const sessionId = session.id || session.session_id || session.session_token || ''
    const status = (session.status || '').toLowerCase()
    const vendorData = session.vendor_data || ''
    const rejectionReason = session.rejection_reason || session.decline_reason || null

    if (!sessionId || !status) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: session.id and status' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      )
    }

    if (!['approved', 'declined'].includes(status)) {
      return new Response(
        JSON.stringify({ success: true, ignored: true, reason: `Status ${status} does not require action` }),
        { headers: { 'Content-Type': 'application/json' } },
      )
    }

    if (!vendorData) {
      return new Response(
        JSON.stringify({ error: 'No vendor_data in session' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const userId = vendorData
    const docStatus = status === 'approved' ? 'approved' : 'rejected'

    const { error: profileError } = await supabase
      .from('driver_details')
      .update({ verification_status: docStatus })
      .eq('profile_id', userId)

    if (profileError) {
    } else {
    }

    const { error: docError, data: updatedDocs } = await supabase
      .from('driver_documents')
      .update({
        status: docStatus,
        rejection_reason: rejectionReason,
      })
      .eq('driver_id', userId)
      .eq('file_url', `didit://${sessionId}`)
      .select()

    if (docError) {
    } else {
    }

    const { data: authUser, error: authError } = await supabase.auth.admin.getUserById(userId)

    if (authError || !authUser?.user?.email) {
      return new Response(
        JSON.stringify({
          success: true,
          documents_updated: !docError,
          email_sent: false,
          reason: 'Could not find user email',
        }),
        { headers: { 'Content-Type': 'application/json' } },
      )
    }

    const { subject, html } = buildEmailContent(docStatus, rejectionReason)
    const emailSent = await sendEmail(authUser.user.email, subject, html)

    return new Response(
      JSON.stringify({
        success: true,
        documents_updated: !docError,
        email_sent: emailSent,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Webhook processing failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
