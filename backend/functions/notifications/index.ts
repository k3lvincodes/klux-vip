import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const fcmProjectId = Deno.env.get('FCM_PROJECT_ID')
const firebaseServiceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

let cachedToken: string | null = null
let tokenExpiresAt = 0

async function getAccessToken(): Promise<string | null> {
  if (!firebaseServiceAccount || !fcmProjectId) return null
  if (cachedToken && Date.now() < tokenExpiresAt) return cachedToken

  try {
    const sa = JSON.parse(firebaseServiceAccount)
    const now = Math.floor(Date.now() / 1000)
    const expiry = now + 3600

    const header = { alg: 'RS256', typ: 'JWT' }
    const payload = {
      iss: sa.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: expiry,
    }

    const encode = (obj: Record<string, unknown>) =>
      btoa(JSON.stringify(obj)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

    const unsignedJwt = `${encode(header)}.${encode(payload)}`

    const key = await crypto.subtle.importKey(
      'pkcs8',
      pemToArrayBuffer(sa.private_key),
      { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsignedJwt))
    const jwt = `${unsignedJwt}.${btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}`

    const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
    })

    if (!tokenRes.ok) {
      return null
    }

    const tokenData = await tokenRes.json()
    cachedToken = tokenData.access_token
    tokenExpiresAt = Date.now() + (tokenData.expires_in - 60) * 1000
    return cachedToken
  } catch (err) {
    return null
  }
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const binary = atob(b64)
  const buffer = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    buffer[i] = binary.charCodeAt(i)
  }
  return buffer.buffer
}

interface FCMMessage {
  token: string
  notification: {
    title: string
    body: string
  }
  data?: Record<string, string>
}

async function sendFCM(message: FCMMessage): Promise<boolean> {
  const accessToken = await getAccessToken()
  if (!accessToken || !fcmProjectId) {
    return false
  }

  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message }),
      }
    )

    if (!response.ok) {
      const errBody = await response.text()
      return false
    }

    return true
  } catch (error) {
    return false
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
    const { user_id, type, title, body, data } = await req.json()

    if (!user_id || !type || !title) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, type, title' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: fcmToken, error: tokenError } = await supabase
      .from('user_devices')
      .select('fcm_token')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single()

    if (tokenError || !fcmToken?.fcm_token) {
      await supabase.from('notifications').insert({
        user_id,
        type,
        title,
        body,
        data,
        status: 'pending',
        delivery_status: 'pending',
      })

      return new Response(
        JSON.stringify({ success: true, delivered: false, reason: 'No FCM token' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: notificationRecord, error: insertError } = await supabase
      .from('notifications')
      .insert({
        user_id, type, title, body, data,
        status: 'sent',
        delivery_status: 'sent',
      })
      .select()
      .single()

    const fcmSent = await sendFCM({
      token: fcmToken.fcm_token,
      notification: { title, body },
      data: data || {},
    })

    if (!fcmSent && notificationRecord?.id) {
      await supabase
        .from('notifications')
        .update({ status: 'failed', delivery_status: 'failed' })
        .eq('id', notificationRecord.id)
    }

    return new Response(
      JSON.stringify({ success: true, delivered: fcmSent }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Notification failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
