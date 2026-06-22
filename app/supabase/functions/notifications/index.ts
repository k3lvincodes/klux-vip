import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')
if (!fcmServerKey) throw new Error('Missing FCM_SERVER_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface FCMMessage {
  to?: string
  registration_ids?: string[]
  notification: {
    title: string
    body: string
  }
  data?: Record<string, string>
}

async function sendFCM(message: FCMMessage): Promise<boolean> {
  if (!fcmServerKey) {
    console.log('FCM not configured, skipping notification')
    return false
  }

  try {
    const response = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${fcmServerKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    })

    return response.ok
  } catch (error) {
    console.error('FCM send error:', error)
    return false
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
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
      to: fcmToken.fcm_token,
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
      JSON.stringify({ error: 'Notification failed', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})