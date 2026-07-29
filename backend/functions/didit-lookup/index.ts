import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const diditClientId = Deno.env.get('DIDIT_CLIENT_ID')
const diditClientSecret = Deno.env.get('DIDIT_CLIENT_SECRET')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')
if (!diditClientId) throw new Error('Missing DIDIT_CLIENT_ID environment variable')
if (!diditClientSecret) throw new Error('Missing DIDIT_CLIENT_SECRET environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

interface DiditDocument {
  type: string
  status: string
  front_image?: string
  back_image?: string
  face_image?: string
  images?: { image: string; type: string }[]
}

interface DiditSession {
  id: string
  status: string
  created_at: string
  updated_at: string
  documents?: DiditDocument[]
  selfie?: { image: string }
  rejection_reason?: string | null
}

async function getAccessToken(): Promise<string> {
  const body = new URLSearchParams()
  body.set('grant_type', 'client_credentials')
  body.set('client_id', diditClientId)
  body.set('client_secret', diditClientSecret)

  const res = await fetch('https://apx.didit.me/auth/v2/token/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  })

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Didit auth failed (${res.status}): ${text}`)
  }

  const data = await res.json()
  return data.access_token
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': 'POST, GET',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { session_id } = await req.json()

    if (!session_id) {
      return new Response(
        JSON.stringify({ error: 'Missing session_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const token = await getAccessToken()

    const res = await fetch(`https://verification.didit.me/v3/session/${session_id}/`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
    })

    if (!res.ok) {
      const errorText = await res.text()
      return new Response(
        JSON.stringify({ error: 'Failed to fetch session from Didit', details: errorText }),
        { status: res.status, headers: { 'Content-Type': 'application/json' } },
      )
    }

    const session: DiditSession = await res.json()

    const { data: docRecord } = await supabase
      .from('driver_documents')
      .select('driver_id')
      .eq('file_url', `didit://${session_id}`)
      .maybeSingle()

    return new Response(
      JSON.stringify({
        session,
        driver_id: docRecord?.driver_id || null,
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': allowedOrigin } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Didit lookup failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    )
  }
})
