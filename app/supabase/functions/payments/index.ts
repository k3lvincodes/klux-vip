import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@17.6.0?target=deno'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' }) : null
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN') || '*'

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, GET',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() })
  }

  try {
    const authHeader = req.headers.get('authorization')
    let callerId: string | null = null
    if (authHeader) {
      const { data: user, error: authError } = await supabase.auth.getUser(
        authHeader.replace('Bearer ', ''),
      )
      if (!authError && user?.user) {
        callerId = user.user.id
      }
    }

    const { action, data } = await req.json()

    if (!stripe) {
      return jsonResponse({ error: 'Stripe not configured' }, 500)
    }

    switch (action) {
      case 'create-setup-intent': {
        const { customer_id, user_id, payment_method_id } = data

        if (!user_id || !payment_method_id || !customer_id) {
          return jsonResponse({ error: 'Missing required fields' }, 400)
        }

        if (callerId && callerId !== user_id) {
          return jsonResponse({ error: 'Unauthorized' }, 403)
        }

        const [paymentMethod, setupIntent] = await Promise.all([
          stripe.paymentMethods.retrieve(payment_method_id),
          stripe.setupIntents.create({
            payment_method: payment_method_id,
            customer: customer_id,
            metadata: { user_id },
          }),
        ])

        const last4 = paymentMethod?.card?.last4 ?? payment_method_id.slice(-4)

        await supabase.from('payment_methods').insert({
          user_id,
          provider_token: payment_method_id,
          stripe_pm_id: payment_method_id,
          type: 'card',
          last4,
        })

        return jsonResponse({ setup_intent: setupIntent.client_secret })
      }

      case 'process-ride-payment': {
        const { ride_id, user_id, amount, payment_method_id } = data

        if (!ride_id || !user_id || !amount) {
          return jsonResponse({ error: 'Missing required fields' }, 400)
        }

        if (!Number.isFinite(amount) || amount <= 0) {
          return jsonResponse({ error: 'Invalid amount' }, 400)
        }

        if (callerId && callerId !== user_id) {
          return jsonResponse({ error: 'Unauthorized' }, 403)
        }

        const { data: ride, error: rideError } = await supabase
          .from('rides')
          .select('status, fare_amount')
          .eq('id', ride_id)
          .single()

        if (rideError || !ride) {
          return jsonResponse({ error: 'Ride not found' }, 404)
        }

        if (ride.fare_amount != null && Math.round(amount * 100) !== Math.round(ride.fare_amount * 100)) {
          return jsonResponse({ error: 'Amount mismatch' }, 400)
        }

        let pmId = payment_method_id
        if (!pmId) {
          const { data: pm } = await supabase
            .from('payment_methods')
            .select('stripe_pm_id')
            .eq('user_id', user_id)
            .order('created_at', { ascending: false })
            .limit(1)
            .single()
          if (pm?.stripe_pm_id) pmId = pm.stripe_pm_id
        }

        if (!pmId) {
          return jsonResponse({ error: 'No payment method found' }, 400)
        }

        const idempotencyKey = `ride_auth_${ride_id}_${Date.now()}`
        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100),
          currency: 'usd',
          payment_method: pmId,
          confirm: true,
          capture_method: 'manual',
          metadata: { ride_id, user_id },
          idempotencyKey,
        })

        if (paymentIntent.status === 'requires_action') {
          await supabase.from('transactions').insert({
            ride_id,
            user_id,
            payer_id: user_id,
            amount,
            type: 'ride_payment',
            status: 'requires_action',
            stripe_payment_intent_id: paymentIntent.id,
          })

          return jsonResponse({
            success: false,
            requires_action: true,
            payment_intent_client_secret: paymentIntent.client_secret,
            status: paymentIntent.status,
          })
        }

        const txStatus = paymentIntent.status === 'requires_capture' ? 'authorized' : 'pending'
        await supabase.from('transactions').insert({
          ride_id,
          user_id,
          payer_id: user_id,
          amount,
          type: 'ride_payment',
          status: txStatus,
          stripe_payment_intent_id: paymentIntent.id,
        })

        return jsonResponse({
          success: txStatus === 'authorized',
          payment_intent: paymentIntent.client_secret,
          status: paymentIntent.status,
        })
      }

      case 'capture-ride-payment': {
        const { ride_id } = data

        if (!ride_id) {
          return jsonResponse({ error: 'Missing ride_id' }, 400)
        }

        const { data: tx } = await supabase
          .from('transactions')
          .select('id, stripe_payment_intent_id, status, amount')
          .eq('ride_id', ride_id)
          .eq('type', 'ride_payment')
          .order('created_at', { ascending: false })
          .limit(1)
          .single()

        if (!tx || !tx.stripe_payment_intent_id) {
          return jsonResponse({ error: 'No authorized payment found' }, 404)
        }

        if (tx.status !== 'authorized') {
          return jsonResponse({ error: `Payment is not in authorized state (${tx.status})` }, 400)
        }

        const captured = await stripe.paymentIntents.capture(tx.stripe_payment_intent_id)

        if (captured.status === 'succeeded') {
          await supabase
            .from('transactions')
            .update({ status: 'completed' })
            .eq('id', tx.id)

          return jsonResponse({ success: true, status: 'completed' })
        }

        return jsonResponse({ success: false, status: captured.status }, 400)
      }

      case 'cancel-ride-payment': {
        const { ride_id } = data

        if (!ride_id) {
          return jsonResponse({ error: 'Missing ride_id' }, 400)
        }

        const { data: tx } = await supabase
          .from('transactions')
          .select('id, stripe_payment_intent_id, status')
          .eq('ride_id', ride_id)
          .eq('type', 'ride_payment')
          .order('created_at', { ascending: false })
          .limit(1)
          .single()

        if (!tx || !tx.stripe_payment_intent_id) {
          return jsonResponse({ error: 'No payment found' }, 404)
        }

        if (!['authorized', 'pending', 'requires_action'].includes(tx.status)) {
          return jsonResponse({ error: `Payment cannot be cancelled in state ${tx.status}` }, 400)
        }

        await stripe.paymentIntents.cancel(tx.stripe_payment_intent_id)

        await supabase
          .from('transactions')
          .update({ status: 'cancelled' })
          .eq('id', tx.id)

        return jsonResponse({ success: true, status: 'cancelled' })
      }

      case 'payout-driver': {
        const { driver_id, ride_id, amount, stripe_connect_id } = data

        if (!driver_id || !ride_id || !amount || !stripe_connect_id) {
          return jsonResponse({ error: 'Missing required fields' }, 400)
        }

        if (!Number.isFinite(amount) || amount <= 0) {
          return jsonResponse({ error: 'Invalid amount' }, 400)
        }

        if (callerId && callerId !== driver_id) {
          return jsonResponse({ error: 'Unauthorized' }, 403)
        }

        const { data: driverProfile } = await supabase
          .from('profiles')
          .select('stripe_connect_id')
          .eq('id', driver_id)
          .single()

        if (!driverProfile || driverProfile.stripe_connect_id !== stripe_connect_id) {
          return jsonResponse({ error: 'Invalid stripe connect account' }, 403)
        }

        const idempotencyKey = `payout_${ride_id}_${Date.now()}`
        const transfer = await stripe.transfers.create({
          amount: Math.round(amount * 100),
          currency: 'usd',
          destination: stripe_connect_id,
          metadata: { ride_id, driver_id },
          idempotencyKey,
        })

        await supabase.from('transactions').insert({
          ride_id,
          user_id: driver_id,
          payee_id: driver_id,
          amount,
          type: 'withdrawal',
          status: 'completed',
          stripe_transfer_id: transfer.id,
        })

        return jsonResponse({
          success: true,
          transfer_id: transfer.id,
        })
      }

      default:
        return jsonResponse({ error: 'Invalid action' }, 400)
    }
  } catch (error) {
    return jsonResponse({ error: 'Payment processing failed' }, 500)
  }
})