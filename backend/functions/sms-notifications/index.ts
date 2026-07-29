import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const plivoAuthId = Deno.env.get('PLIVO_AUTH_ID')
const plivoAuthToken = Deno.env.get('PLIVO_AUTH_TOKEN')
const plivoPhoneNumber = Deno.env.get('PLIVO_PHONE_NUMBER')
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface SmsData {
  customer_name?: string
  booking_confirmation?: string
  pickup_address?: string
  dropoff_address?: string
  vehicle_type?: string
  trip_date?: string
  trip_time?: string
  total_amount?: number
  invoice_number?: string
  driver_name?: string
  eta?: string
}

interface SmsRequest {
  type: 'booking_confirmation' | 'payment_receipt' | 'admin_new_booking' | 'admin_payment' | 'driver_assigned'
  to: string
  data: SmsData
}

function buildSmsBody(type: SmsRequest['type'], data: SmsData): string {
  switch (type) {
    case 'booking_confirmation':
      return [
        'KLUX VIP - Booking Confirmed!',
        `Confirmation: ${data.booking_confirmation}`,
        `Pickup: ${data.pickup_address}`,
        `Dropoff: ${data.dropoff_address}`,
        `Date: ${data.trip_date} at ${data.trip_time}`,
        `Total: $${data.total_amount}`,
        'Thank you for booking with KLUX VIP!',
      ].join('\n')

    case 'payment_receipt':
      return [
        'KLUX VIP - Payment Receipt',
        `Invoice: ${data.invoice_number}`,
        `Amount: $${data.total_amount}`,
        'Status: PAID',
        `Pickup: ${data.pickup_address}`,
        `Dropoff: ${data.dropoff_address}`,
        'Thank you for your payment!',
      ].join('\n')

    case 'admin_new_booking':
      return [
        'KLUX VIP - New Booking Alert',
        `Customer: ${data.customer_name}`,
        `Pickup: ${data.pickup_address}`,
        `Dropoff: ${data.dropoff_address}`,
        `Vehicle: ${data.vehicle_type}`,
        `Total: $${data.total_amount}`,
        `Confirmation: ${data.booking_confirmation}`,
      ].join('\n')

    case 'admin_payment':
      return [
        'KLUX VIP - Payment Received',
        `Customer: ${data.customer_name}`,
        `Invoice: ${data.invoice_number}`,
        `Amount: $${data.total_amount}`,
        'Status: PAID',
      ].join('\n')

    case 'driver_assigned':
      return [
        'KLUX VIP - Your chauffeur is on the way!',
        `Driver: ${data.driver_name}`,
        `ETA: ${data.eta}`,
        `Pickup: ${data.pickup_address}`,
        'Track your ride in the app.',
      ].join('\n')

    default:
      throw new Error(`Unknown SMS type: ${type}`)
  }
}

function validateE164(phone: string): boolean {
  return /^\+[1-9]\d{6,14}$/.test(phone)
}

async function sendPlivoSms(to: string, text: string): Promise<boolean> {
  if (!plivoAuthId || !plivoAuthToken || !plivoPhoneNumber) {
    return true
  }

  const credentials = btoa(`${plivoAuthId}:${plivoAuthToken}`)

  try {
    const response = await fetch(
      `https://api.plivo.com/v1/Account/${plivoAuthId}/Message/`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          src: plivoPhoneNumber,
          dst: to,
          text: text,
        }),
      }
    )

    if (!response.ok) {
      const errorBody = await response.text()
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
    const { type, to, data } = await req.json() as SmsRequest

    if (!type || !to) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: type, to' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!validateE164(to)) {
      return new Response(
        JSON.stringify({ error: 'Invalid phone number format. Must be E.164 (e.g., +14155552671)' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const smsBody = buildSmsBody(type, data)
    const sent = await sendPlivoSms(to, smsBody)

    return new Response(
      JSON.stringify({ success: true, sent, type, to }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'SMS notification failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
