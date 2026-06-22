import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@17.6.0?target=deno'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' }) : null

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { action, data } = await req.json()

    if (!stripe) {
      return new Response(
        JSON.stringify({ error: 'Stripe not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    switch (action) {
      case 'create-setup-intent': {
        const { customer_id, user_id, payment_method_id } = data

        if (!user_id || !payment_method_id || !customer_id) {
          return new Response(
            JSON.stringify({ error: 'Missing required fields' }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          )
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

        return new Response(
          JSON.stringify({ setup_intent: setupIntent.client_secret }),
          { headers: { 'Content-Type': 'application/json' } }
        )
      }

      case 'process-ride-payment': {
        const { ride_id, user_id, amount } = data

        if (!ride_id || !user_id || !amount) {
          return new Response(
            JSON.stringify({ error: 'Missing required fields' }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          )
        }

        const { data: paymentMethod, error: pmError } = await supabase
          .from('payment_methods')
          .select('*')
          .eq('user_id', user_id)
          .order('created_at', { ascending: false })
          .limit(1)
          .single()

        if (pmError || !paymentMethod) {
          return new Response(
            JSON.stringify({ error: 'No payment method found' }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          )
        }

        const paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(amount * 100),
          currency: 'usd',
          payment_method: paymentMethod.stripe_pm_id || paymentMethod.provider_token,
          confirm: true,
          metadata: { ride_id, user_id },
        })

        if (paymentIntent.status === 'succeeded') {
          await supabase.from('transactions').insert({
            ride_id,
            user_id,
            payer_id: user_id,
            amount,
            type: 'ride_payment',
            status: 'completed',
          })

          await supabase
            .from('rides')
            .update({ status: 'completed' })
            .eq('id', ride_id)
        } else {
          await supabase.from('transactions').insert({
            ride_id,
            user_id,
            payer_id: user_id,
            amount,
            type: 'ride_payment',
            status: 'pending',
          })
        }

        return new Response(
          JSON.stringify({
            success: paymentIntent.status === 'succeeded',
            payment_intent: paymentIntent.client_secret,
            status: paymentIntent.status,
          }),
          { headers: { 'Content-Type': 'application/json' } }
        )
      }

      case 'payout-driver': {
        const { driver_id, ride_id, amount, stripe_connect_id } = data

        if (!driver_id || !ride_id || !amount || !stripe_connect_id) {
          return new Response(
            JSON.stringify({ error: 'Missing required fields' }),
            { status: 400, headers: { 'Content-Type': 'application/json' } }
          )
        }

        const transfer = await stripe.transfers.create({
          amount: Math.round(amount * 100),
          currency: 'usd',
          destination: stripe_connect_id,
          metadata: { ride_id, driver_id },
        })

        await supabase.from('transactions').insert({
          ride_id,
          user_id: driver_id,
          payee_id: driver_id,
          amount,
          type: 'withdrawal',
          status: 'completed',
        })

        return new Response(
          JSON.stringify({
            success: true,
            transfer_id: transfer.id,
          }),
          { headers: { 'Content-Type': 'application/json' } }
        )
      }

      default:
        return new Response(
          JSON.stringify({ error: 'Invalid action' }),
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
    }
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Payment processing failed', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})