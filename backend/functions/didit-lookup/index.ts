import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const diditApiKey = Deno.env.get('DIDIT_API_KEY') || 'Ljgu4XQ0a_Ux3yMkPi6nLSGijRHOuUmTeBXyzPVVsjA'
const diditClientId = Deno.env.get('DIDIT_CLIENT_ID')
const diditClientSecret = Deno.env.get('DIDIT_CLIENT_SECRET')

const supabase = supabaseUrl && supabaseServiceKey ? createClient(supabaseUrl, supabaseServiceKey) : null
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN') || '*'

async function getOAuthToken(): Promise<string | null> {
  if (!diditClientId || !diditClientSecret) return null
  try {
    const body = new URLSearchParams()
    body.set('grant_type', 'client_credentials')
    body.set('client_id', diditClientId)
    body.set('client_secret', diditClientSecret)

    const res = await fetch('https://apx.didit.me/auth/v2/token/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    })

    if (!res.ok) return null
    const data = await res.json()
    return data.access_token || null
  } catch {
    return null
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': allowedOrigin,
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { session_id } = await req.json()

    if (!session_id) {
      return new Response(
        JSON.stringify({ error: 'Missing session_id' }),
        { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': allowedOrigin } },
      )
    }

    // 1. Primary approach: Use Didit API Key on /v3/session/{session_id}/decision/
    const decisionHeaders: Record<string, string> = {
      'Content-Type': 'application/json',
      'x-api-key': diditApiKey,
    }

    let decisionRes = await fetch(`https://verification.didit.me/v3/session/${session_id}/decision/`, {
      method: 'GET',
      headers: decisionHeaders,
    })

    // 2. Secondary approach: If API key rejected and OAuth credentials exist, try OAuth
    if (!decisionRes.ok && diditClientId && diditClientSecret) {
      const token = await getOAuthToken()
      if (token) {
        decisionRes = await fetch(`https://verification.didit.me/v3/session/${session_id}/decision/`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
          },
        })
      }
    }

    if (!decisionRes.ok) {
      const errorText = await decisionRes.text()
      return new Response(
        JSON.stringify({ error: 'Failed to fetch session decision from Didit', details: errorText }),
        { status: decisionRes.status, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': allowedOrigin } },
      )
    }

    const decisionData = await decisionRes.json()

    // Query corresponding driver document if Supabase client is available
    let driverId = null
    if (supabase) {
      try {
        const { data: docRecord } = await supabase
          .from('driver_documents')
          .select('driver_id')
          .eq('file_url', `didit://${session_id}`)
          .maybeSingle()
        driverId = docRecord?.driver_id || null
      } catch {
        // non-blocking
      }
    }

    return new Response(
      JSON.stringify({
        session: decisionData,
        driver_id: driverId,
      }),
      { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': allowedOrigin } },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Didit lookup failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': allowedOrigin } },
    )
  }
})
