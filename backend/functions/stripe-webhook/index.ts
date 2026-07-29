import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@17.6.0?target=deno'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' }) : null
const whSecret = webhookSecret
if (!whSecret) throw new Error('Missing STRIPE_WEBHOOK_SECRET environment variable')

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const rawBody = await req.text()
    const signature = req.headers.get('stripe-signature')

    if (!signature) {
      return new Response(JSON.stringify({ error: 'Missing signature' }), { status: 401 })
    }

    if (!stripe || !whSecret) {
      return new Response(JSON.stringify({ error: 'Webhook not configured' }), { status: 500 })
    }

    let event: Stripe.Event
    try {
      event = stripe.webhooks.constructEvent(rawBody, signature, whSecret)
    } catch (err) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), { status: 401 })
    }

    const eventId = event.id
    const eventType = event.type

    const { data: existing } = await supabase
      .from('stripe_events')
      .select('id, status')
      .eq('stripe_event_id', eventId)
      .maybeSingle()

    if (existing) {
      return new Response(JSON.stringify({ received: true, duplicate: true }), { status: 200 })
    }

    await supabase.from('stripe_events').insert({
      stripe_event_id: eventId,
      type: eventType,
      related_object: (event.data.object as any)?.id,
      status: 'processing',
    })

    try {
      await handleEvent(event)
    } catch (handlerErr) {
      await supabase
        .from('stripe_events')
        .update({ status: 'failed', error: handlerErr.message })
        .eq('stripe_event_id', eventId)
      return new Response(JSON.stringify({ received: true, error: handlerErr.message }), { status: 200 })
    }

    await supabase
      .from('stripe_events')
      .update({ status: 'completed', processed_at: new Date().toISOString() })
      .eq('stripe_event_id', eventId)

    return new Response(JSON.stringify({ received: true }), { status: 200 })
  } catch (err) {
    return new Response(JSON.stringify({ error: 'Internal error' }), { status: 500 })
  }
})

async function handleEvent(event: Stripe.Event): Promise<void> {
  const object = event.data.object as any

  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentIntentSucceeded(object)
      break
    case 'payment_intent.payment_failed':
      await handlePaymentIntentFailed(object)
      break
    case 'charge.refunded':
      await handleChargeRefunded(object)
      break
    case 'charge.disputed':
      break
    case 'payout.failed':
      break
    case 'payout.paid':
      break
    default:
  }
}

async function handlePaymentIntentSucceeded(pi: any): Promise<void> {
  const piId = pi.id
  const rideId = pi.metadata?.ride_id

  if (!rideId) {
    return
  }

  const { data: tx } = await supabase
    .from('transactions')
    .select('id, status')
    .eq('stripe_payment_intent_id', piId)
    .maybeSingle()

  if (tx && tx.status !== 'completed') {
    await supabase
      .from('transactions')
      .update({ status: 'completed' })
      .eq('id', tx.id)
  }

  const { data: ride } = await supabase
    .from('rides')
    .select('status')
    .eq('id', rideId)
    .single()

  if (ride && ride.status !== 'completed') {
    await supabase
      .from('rides')
      .update({ status: 'completed' })
      .eq('id', rideId)
  }

  // Send admin payment notification emails
  const { data: adminProfiles } = await supabase
    .from('profiles')
    .select('email')
    .eq('role', 'admin')
    .limit(5)

  for (const admin of (adminProfiles || [])) {
    if (admin.email) {
      supabase.functions.invoke('email-notifications', {
        body: {
          type: 'admin_payment',
          to: admin.email,
          data: {
            customer_name: pi.metadata?.contact_name || 'Customer',
            invoice_number: pi.metadata?.invoice_number || 'N/A',
            pickup_address: pi.metadata?.pickup_address || 'N/A',
            dropoff_address: pi.metadata?.dropoff_address || 'N/A',
            total_amount: parseFloat(pi.metadata?.total_amount || '0'),
          },
        },
      }).then().catch(() => {})
    }
  }

  // Send admin payment SMS notifications
  const adminPhone = Deno.env.get('ADMIN_PHONE')
  if (adminPhone) {
    supabase.functions.invoke('sms-notifications', {
      body: {
        type: 'admin_payment',
        to: adminPhone,
        data: {
          customer_name: pi.metadata?.contact_name || 'Customer',
          invoice_number: pi.metadata?.invoice_number || 'N/A',
          total_amount: parseFloat(pi.metadata?.total_amount || '0'),
        },
      },
    }).then().catch(() => {})
  }
}

async function handlePaymentIntentFailed(pi: any): Promise<void> {
  const piId = pi.id

  const { data: tx } = await supabase
    .from('transactions')
    .select('id')
    .eq('stripe_payment_intent_id', piId)
    .maybeSingle()

  if (tx) {
    await supabase
      .from('transactions')
      .update({ status: 'failed' })
      .eq('id', tx.id)
  }
}

async function handleChargeRefunded(charge: any): Promise<void> {
  const piId = charge.payment_intent
  if (!piId) return

  const { data: tx } = await supabase
    .from('transactions')
    .select('id, ride_id, user_id, amount')
    .eq('stripe_payment_intent_id', piId)
    .maybeSingle()

  if (!tx) {
    return
  }

  const refundAmount = (charge.amount_refunded ?? charge.amount) / 100

  await supabase.from('transactions').insert({
    ride_id: tx.ride_id,
    user_id: tx.user_id,
    payer_id: tx.user_id,
    amount: refundAmount,
    type: 'ride_payment',
    status: 'completed',
    stripe_payment_intent_id: piId,
  })

}
