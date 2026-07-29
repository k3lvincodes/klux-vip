import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const resendApiKey = Deno.env.get('RESEND_API_KEY')
const fromEmail = Deno.env.get('FROM_EMAIL') || 'notifications@kenicktransportation.com'
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)

interface EmailData {
  customer_name?: string
  booking_confirmation?: string
  pickup_address?: string
  dropoff_address?: string
  vehicle_type?: string
  trip_date?: string
  trip_time?: string
  fare_amount?: number
  tip_amount?: number
  total_amount?: number
  invoice_number?: string
  payment_method_last4?: string
  contact_email?: string
  contact_phone?: string
  scheduled_time?: string
  driver_name?: string
  eta?: string
}

interface EmailRequest {
  type: 'booking_confirmation' | 'payment_receipt' | 'admin_new_booking' | 'admin_payment' | 'driver_assigned'
  to: string
  data: EmailData
}

const baseStyles = `
  body { margin: 0; padding: 0; background-color: #0a0a0a; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
  .container { max-width: 600px; margin: 0 auto; background-color: #111111; }
  .header { background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 100%); padding: 32px 24px; text-align: center; border-bottom: 2px solid #d4af37; }
  .logo { font-size: 28px; font-weight: 700; color: #d4af37; letter-spacing: 4px; margin: 0; }
  .tagline { font-size: 12px; color: #888; letter-spacing: 2px; margin-top: 4px; }
  .content { padding: 32px 24px; color: #e0e0e0; }
  .title { font-size: 22px; font-weight: 600; color: #ffffff; margin: 0 0 8px 0; }
  .subtitle { font-size: 14px; color: #888; margin: 0 0 24px 0; }
  .badge { display: inline-block; padding: 6px 16px; border-radius: 20px; font-size: 13px; font-weight: 600; letter-spacing: 1px; }
  .badge-gold { background-color: rgba(212, 175, 55, 0.15); color: #d4af37; border: 1px solid rgba(212, 175, 55, 0.3); }
  .badge-green { background-color: rgba(34, 197, 94, 0.15); color: #22c55e; border: 1px solid rgba(34, 197, 94, 0.3); }
  .badge-blue { background-color: rgba(59, 130, 246, 0.15); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.3); }
  .detail-card { background-color: #1a1a1a; border: 1px solid #2a2a2a; border-radius: 12px; padding: 20px; margin: 16px 0; }
  .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #2a2a2a; }
  .detail-row:last-child { border-bottom: none; }
  .detail-label { color: #888; font-size: 13px; }
  .detail-value { color: #e0e0e0; font-size: 13px; font-weight: 500; }
  .total-row { border-top: 2px solid #d4af37; padding-top: 12px; margin-top: 8px; }
  .total-value { color: #d4af37; font-size: 18px; font-weight: 700; }
  .btn { display: inline-block; padding: 14px 32px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 14px; letter-spacing: 0.5px; }
  .btn-gold { background: linear-gradient(135deg, #d4af37, #b8960c); color: #000000; }
  .footer { padding: 24px; text-align: center; border-top: 1px solid #2a2a2a; }
  .footer-text { color: #555; font-size: 11px; line-height: 1.6; }
  .footer-link { color: #d4af37; text-decoration: none; }
`

function wrapHtml(title: string, bodyHtml: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>${title}</title></head>
<body>
<div class="container">
  <div class="header">
    <p class="logo">KLUX VIP</p>
    <p class="tagline">LUXURY GROUND TRANSPORTATION</p>
  </div>
  <div class="content">${bodyHtml}</div>
  <div class="footer">
    <p class="footer-text">&copy; ${new Date().getFullYear()} KLUX VIP Transportation. All rights reserved.<br>
    <a href="https://kluxvip.com" class="footer-link">kluxvip.com</a></p>
  </div>
</div>
</body>
</html>`
}

function buildEmailHtml(type: EmailRequest['type'], data: EmailData): { subject: string; html: string } {
  switch (type) {
    case 'booking_confirmation':
      return {
        subject: `Booking Confirmed - ${data.booking_confirmation}`,
        html: wrapHtml('Booking Confirmed', `
          <h1 class="title">Booking Confirmed</h1>
          <p class="subtitle">Your luxury ride has been booked successfully.</p>
          <div style="text-align:center;margin:24px 0">
            <span class="badge badge-gold">${data.booking_confirmation}</span>
          </div>
          <div class="detail-card">
            <div class="detail-row">
              <span class="detail-label">Pickup</span>
              <span class="detail-value">${data.pickup_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Dropoff</span>
              <span class="detail-value">${data.dropoff_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Vehicle</span>
              <span class="detail-value">${data.vehicle_type}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Date &amp; Time</span>
              <span class="detail-value">${data.trip_date} at ${data.trip_time}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Fare</span>
              <span class="detail-value">$${data.fare_amount?.toFixed(2)}</span>
            </div>
            ${data.tip_amount ? `<div class="detail-row">
              <span class="detail-label">Tip</span>
              <span class="detail-value">$${data.tip_amount?.toFixed(2)}</span>
            </div>` : ''}
            <div class="detail-row total-row">
              <span class="detail-label" style="font-weight:600;color:#fff">Total</span>
              <span class="detail-value total-value">$${data.total_amount?.toFixed(2)}</span>
            </div>
          </div>
          <div style="text-align:center;margin:28px 0">
            <a href="https://kluxvip.com/booking/track/${data.booking_confirmation}" class="btn btn-gold">Track Your Ride</a>
          </div>
        `),
      }

    case 'payment_receipt':
      return {
        subject: `Payment Receipt - Invoice ${data.invoice_number}`,
        html: wrapHtml('Payment Receipt', `
          <h1 class="title">Payment Received</h1>
          <p class="subtitle">Your payment has been processed successfully.</p>
          <div style="text-align:center;margin:24px 0">
            <span class="badge badge-green">PAID</span>
            <span class="badge badge-blue" style="margin-left:8px">${data.invoice_number}</span>
          </div>
          <div class="detail-card">
            <div class="detail-row">
              <span class="detail-label">Pickup</span>
              <span class="detail-value">${data.pickup_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Dropoff</span>
              <span class="detail-value">${data.dropoff_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Vehicle</span>
              <span class="detail-value">${data.vehicle_type}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Date &amp; Time</span>
              <span class="detail-value">${data.trip_date} at ${data.trip_time}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Fare</span>
              <span class="detail-value">$${data.fare_amount?.toFixed(2)}</span>
            </div>
            ${data.tip_amount ? `<div class="detail-row">
              <span class="detail-label">Tip</span>
              <span class="detail-value">$${data.tip_amount?.toFixed(2)}</span>
            </div>` : ''}
            <div class="detail-row total-row">
              <span class="detail-label" style="font-weight:600;color:#fff">Total Paid</span>
              <span class="detail-value total-value">$${data.total_amount?.toFixed(2)}</span>
            </div>
          </div>
        `),
      }

    case 'admin_new_booking':
      return {
        subject: `New Booking - ${data.contact_name}`,
        html: wrapHtml('New Booking Alert', `
          <h1 class="title">New Website Booking</h1>
          <p class="subtitle">A new booking has been placed on the website.</p>
          <div style="text-align:center;margin:24px 0">
            <span class="badge badge-blue">${data.booking_confirmation}</span>
          </div>
          <div class="detail-card">
            <div class="detail-row">
              <span class="detail-label">Customer</span>
              <span class="detail-value">${data.contact_name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Email</span>
              <span class="detail-value">${data.contact_email}</span>
            </div>
            ${data.contact_phone ? `<div class="detail-row">
              <span class="detail-label">Phone</span>
              <span class="detail-value">${data.contact_phone}</span>
            </div>` : ''}
            <div class="detail-row">
              <span class="detail-label">Pickup</span>
              <span class="detail-value">${data.pickup_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Dropoff</span>
              <span class="detail-value">${data.dropoff_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Vehicle</span>
              <span class="detail-value">${data.vehicle_type}</span>
            </div>
            ${data.scheduled_time ? `<div class="detail-row">
              <span class="detail-label">Scheduled</span>
              <span class="detail-value">${data.scheduled_time}</span>
            </div>` : ''}
            <div class="detail-row total-row">
              <span class="detail-label" style="font-weight:600;color:#fff">Total</span>
              <span class="detail-value total-value">$${data.total_amount?.toFixed(2)}</span>
            </div>
          </div>
          <div style="text-align:center;margin:28px 0">
            <a href="https://kluxvip.com/admin/rides" class="btn btn-gold">View in Dashboard</a>
          </div>
        `),
      }

    case 'admin_payment':
      return {
        subject: `Payment Received - ${data.customer_name} - $${data.total_amount}`,
        html: wrapHtml('Payment Received', `
          <h1 class="title">Payment Received</h1>
          <p class="subtitle">A payment has been processed for a booking.</p>
          <div style="text-align:center;margin:24px 0">
            <span class="badge badge-green">PAID</span>
          </div>
          <div class="detail-card">
            <div class="detail-row">
              <span class="detail-label">Customer</span>
              <span class="detail-value">${data.customer_name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Invoice</span>
              <span class="detail-value">${data.invoice_number}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Pickup</span>
              <span class="detail-value">${data.pickup_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Dropoff</span>
              <span class="detail-value">${data.dropoff_address}</span>
            </div>
            <div class="detail-row total-row">
              <span class="detail-label" style="font-weight:600;color:#fff">Amount</span>
              <span class="detail-value total-value">$${data.total_amount?.toFixed(2)}</span>
            </div>
          </div>
          <div style="text-align:center;margin:28px 0">
            <a href="https://kluxvip.com/admin/transactions" class="btn btn-gold">View Transactions</a>
          </div>
        `),
      }

    case 'driver_assigned':
      return {
        subject: `Your Chauffeur is On the Way`,
        html: wrapHtml('Driver Assigned', `
          <h1 class="title">Your Chauffeur is On the Way</h1>
          <p class="subtitle">A driver has been assigned to your ride.</p>
          <div class="detail-card">
            <div class="detail-row">
              <span class="detail-label">Driver</span>
              <span class="detail-value" style="color:#d4af37;font-size:15px">${data.driver_name}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">ETA</span>
              <span class="detail-value">${data.eta || '5-10 min'}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Pickup</span>
              <span class="detail-value">${data.pickup_address}</span>
            </div>
            <div class="detail-row">
              <span class="detail-label">Dropoff</span>
              <span class="detail-value">${data.dropoff_address}</span>
            </div>
          </div>
          <div style="text-align:center;margin:28px 0">
            <a href="https://kluxvip.com/booking/track/${data.booking_confirmation || ''}" class="btn btn-gold">Track Your Ride</a>
          </div>
        `),
      }

    default:
      throw new Error(`Unknown email type: ${type}`)
  }
}

async function sendResendEmail(to: string, subject: string, html: string): Promise<boolean> {
  if (!resendApiKey) {
    return true
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [to],
        subject,
        html,
      }),
    })

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
    const { type, to, data } = await req.json() as EmailRequest

    if (!type || !to) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: type, to' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { subject, html } = buildEmailHtml(type, data)
    const sent = await sendResendEmail(to, subject, html)

    return new Response(
      JSON.stringify({ success: true, sent, type, to }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Email notification failed', details: error instanceof Error ? error.message : String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
