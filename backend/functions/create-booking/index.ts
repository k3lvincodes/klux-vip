import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@17.6.0?target=deno'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const stripe = stripeSecretKey ? new Stripe(stripeSecretKey, { apiVersion: '2023-10-16' }) : null
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN')
if (!allowedOrigin) throw new Error('Missing ALLOWED_ORIGIN environment variable')

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  })
}

function generateBookingConfirmation(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let result = ''
  for (let i = 0; i < 6; i++) {
    const arr = new Uint8Array(1)
    crypto.getRandomValues(arr)
    result += chars.charAt(arr[0] % chars.length)
  }
  return result
}

function generateInvoiceNumber(): string {
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const arr = new Uint8Array(2)
  crypto.getRandomValues(arr)
  const rand = (arr[0] << 8) | arr[1]
  const seq = String(rand % 9999).padStart(4, '0')
  return `KLX-${yyyy}${mm}${dd}-${seq}`
}

function calculateDistanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371
  const dLat = ((lat2 - lat1) * Math.PI) / 180
  const dLng = ((lng2 - lng1) * Math.PI) / 180
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() })
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405)
  }

  try {
    const authHeader = req.headers.get('authorization')
    let passengerId: string | null = null

    if (authHeader) {
      const { data: user, error: authError } = await supabase.auth.getUser(
        authHeader.replace('Bearer ', '')
      )
      if (!authError && user?.user) {
        passengerId = user.user.id
      }
    }

    const body = await req.json()

    const {
      pickup_address,
      dropoff_address,
      pickup_lat,
      pickup_lng,
      dropoff_lat,
      dropoff_lng,
      date,
      time,
      vehicle_type,
      passengers,
      contact_name,
      contact_email,
      contact_phone,
      fare_amount,
      tip_amount = 0,
      payment_method_id,
    } = body

    if (
      !pickup_address ||
      !dropoff_address ||
      pickup_lat == null ||
      pickup_lng == null ||
      dropoff_lat == null ||
      dropoff_lng == null ||
      !date ||
      !time ||
      !vehicle_type ||
      !passengers ||
      !contact_name ||
      !contact_email ||
      !contact_phone ||
      fare_amount == null
    ) {
      return jsonResponse({ error: 'Missing required fields' }, 400)
    }

    if (!Number.isFinite(fare_amount) || fare_amount < 0) {
      return jsonResponse({ error: 'Invalid fare_amount' }, 400)
    }

    if (!Number.isFinite(tip_amount) || tip_amount < 0) {
      return jsonResponse({ error: 'Invalid tip_amount' }, 400)
    }

    if (!Number.isFinite(pickup_lat) || !Number.isFinite(pickup_lng) || !Number.isFinite(dropoff_lat) || !Number.isFinite(dropoff_lng)) {
      return jsonResponse({ error: 'Invalid coordinates: all lat/lng values must be finite numbers' }, 400)
    }

    if (!stripe) {
      return jsonResponse({ error: 'Payment processing not configured' }, 500)
    }

    const { data: fareRates, error: fareError } = await supabase
      .from('fare_rates')
      .select('base_fare, per_km_rate, vehicle_type')
      .eq('vehicle_type', vehicle_type)
      .eq('is_active', true)
      .maybeSingle()

    if (fareError || !fareRates) {
      return jsonResponse({ error: 'Invalid vehicle type or no active fare rate found' }, 400)
    }

    const distanceKm = calculateDistanceKm(pickup_lat, pickup_lng, dropoff_lat, dropoff_lng)
    const expectedFare = fareRates.base_fare + distanceKm * fareRates.per_km_rate
    const tolerance = expectedFare * 0.1

    if (Math.abs(fare_amount - expectedFare) > tolerance) {
      return jsonResponse(
        {
          error: 'Fare amount does not match expected fare',
          expected: Math.round(expectedFare * 100) / 100,
          submitted: fare_amount,
          tolerance: Math.round(tolerance * 100) / 100,
        },
        400
      )
    }

    if (!passengerId && contact_email) {
      const { data: existingProfile } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', contact_email)
        .maybeSingle()

      if (existingProfile) {
        passengerId = existingProfile.id
      } else {
        const { data: newProfile, error: profileError } = await supabase
          .from('profiles')
          .insert({
            email: contact_email,
            first_name: contact_name.split(' ')[0] || contact_name,
            last_name: contact_name.split(' ').slice(1).join(' ') || '',
            phone: contact_phone,
            role: 'client',
          })
          .select('id')
          .single()

        if (profileError || !newProfile) {
        } else {
          passengerId = newProfile.id
        }
      }
    }

    const scheduledTime = `${date}T${time}:00Z`
    const totalAmount = fare_amount + tip_amount

    const { data: ride, error: rideError } = await supabase
      .from('rides')
      .insert({
        passenger_id: passengerId,
        pickup_location: `ST_SetSRID(ST_MakePoint(${pickup_lng}, ${pickup_lat}), 4326)::geography`,
        pickup_address,
        dropoff_address,
        dropoff_location: `ST_SetSRID(ST_MakePoint(${dropoff_lng}, ${dropoff_lat}), 4326)::geography`,
        fare_amount: totalAmount,
        tip_amount,
        status: 'requested',
        type: 'scheduled',
        scheduled_time: scheduledTime,
        vehicle_type,
        passengers,
        contact_name,
        contact_email,
        contact_phone,
      })
      .select('id')
      .single()

    if (rideError || !ride) {
      return jsonResponse({ error: 'Failed to create booking', details: rideError }, 500)
    }

    const rideId = ride.id
    const invoiceNumber = generateInvoiceNumber()
    const bookingConfirmation = generateBookingConfirmation()

    const paymentIntentData: Stripe.PaymentIntentCreateParams = {
      amount: Math.round(totalAmount * 100),
      currency: 'usd',
      capture_method: 'manual',
      metadata: {
        ride_id: rideId,
        contact_email,
        contact_name,
        vehicle_type,
        pickup_address,
        dropoff_address,
        total_amount: String(totalAmount),
        invoice_number: invoiceNumber,
      },
    }

    if (payment_method_id) {
      paymentIntentData.payment_method = payment_method_id
      paymentIntentData.confirm = true
    }

    const idempotencyKey = `booking_${rideId}_${Date.now()}`
    const paymentIntent = await stripe.paymentIntents.create(paymentIntentData, {
      idempotencyKey,
    })

    let txStatus: string
    if (paymentIntent.status === 'requires_action') {
      txStatus = 'requires_action'
    } else if (paymentIntent.status === 'requires_capture') {
      txStatus = 'authorized'
    } else if (paymentIntent.status === 'succeeded') {
      txStatus = 'completed'
    } else {
      txStatus = 'pending'
    }

    await supabase.from('transactions').insert({
      ride_id: rideId,
      user_id: passengerId,
      payer_id: passengerId,
      amount: totalAmount,
      type: 'ride_payment',
      status: txStatus,
      stripe_payment_intent_id: paymentIntent.id,
    })

    await supabase.from('invoices').insert({
      ride_id: rideId,
      user_id: passengerId,
      invoice_number: invoiceNumber,
      booking_confirmation: bookingConfirmation,
      amount: fare_amount,
      tip_amount,
      total_amount: totalAmount,
      contact_name,
      contact_email,
      contact_phone,
      status: 'issued',
    })

    // Send booking confirmation email to customer
    supabase.functions.invoke('email-notifications', {
      body: {
        type: 'booking_confirmation',
        to: contact_email,
        data: {
          customer_name: contact_name,
          booking_confirmation: bookingConfirmation,
          pickup_address,
          dropoff_address,
          vehicle_type,
          trip_date: date,
          trip_time: time,
          fare_amount,
          tip_amount,
          total_amount: totalAmount,
        },
      },
    }).then().catch(() => {})

    // Send booking confirmation SMS to customer
    if (contact_phone) {
      supabase.functions.invoke('sms-notifications', {
        body: {
          type: 'booking_confirmation',
          to: contact_phone,
          data: {
            customer_name: contact_name,
            booking_confirmation: bookingConfirmation,
            pickup_address,
            dropoff_address,
            vehicle_type,
            trip_date: date,
            trip_time: time,
            total_amount: totalAmount,
          },
        },
      }).then().catch(() => {})
    }

    // Send payment receipt email
    if (txStatus === 'authorized' || txStatus === 'completed') {
      supabase.functions.invoke('email-notifications', {
        body: {
          type: 'payment_receipt',
          to: contact_email,
          data: {
            customer_name: contact_name,
            invoice_number: invoiceNumber,
            booking_confirmation: bookingConfirmation,
            pickup_address,
            dropoff_address,
            vehicle_type,
            trip_date: date,
            trip_time: time,
            fare_amount,
            tip_amount,
            total_amount: totalAmount,
            payment_method_last4: '****',
          },
        },
      }).then().catch(() => {})
    }

    // Send payment receipt SMS
    if ((txStatus === 'authorized' || txStatus === 'completed') && contact_phone) {
      supabase.functions.invoke('sms-notifications', {
        body: {
          type: 'payment_receipt',
          to: contact_phone,
          data: {
            invoice_number: invoiceNumber,
            pickup_address,
            dropoff_address,
            total_amount: totalAmount,
          },
        },
      }).then().catch(() => {})
    }

    const { data: adminProfiles } = await supabase
      .from('profiles')
      .select('id')
      .eq('role', 'admin')
      .limit(5)

    if (adminProfiles && adminProfiles.length > 0) {
      for (const admin of adminProfiles) {
        supabase
          .from('notifications')
          .insert({
            user_id: admin.id,
            type: 'booking_created',
            title: 'New Website Booking',
            body: `New booking from ${contact_name}: ${pickup_address} to ${dropoff_address}`,
            data: {
              ride_id: rideId,
              booking_confirmation: bookingConfirmation,
              invoice_number: invoiceNumber,
              contact_name,
              contact_email,
              vehicle_type,
              total_amount: String(totalAmount),
              scheduled_time: scheduledTime,
            },
            status: 'pending',
            delivery_status: 'pending',
          })
          .then()
          .catch(() => {})
      }

      // Notify admins via email
      const { data: adminEmails } = await supabase
        .from('profiles')
        .select('email')
        .eq('role', 'admin')
        .limit(5)

      for (const admin of (adminEmails || [])) {
        if (admin.email) {
          supabase.functions.invoke('email-notifications', {
            body: {
              type: 'admin_new_booking',
              to: admin.email,
              data: {
                contact_name,
                contact_email,
                contact_phone,
                vehicle_type,
                total_amount: totalAmount,
                scheduled_time: scheduledTime,
                booking_confirmation: bookingConfirmation,
                pickup_address,
                dropoff_address,
              },
            },
          }).then().catch(() => {})
        }
      }
    }

    return jsonResponse({
      ride_id: rideId,
      client_secret: paymentIntent.client_secret,
      invoice_number: invoiceNumber,
      booking_confirmation: bookingConfirmation,
      total_amount: totalAmount,
      payment_status: paymentIntent.status,
    })
  } catch (error) {
    return jsonResponse(
      { error: 'Booking creation failed', details: error instanceof Error ? error.message : String(error) },
      500
    )
  }
})
