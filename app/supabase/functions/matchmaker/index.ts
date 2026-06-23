import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

if (!supabaseUrl) throw new Error('Missing SUPABASE_URL environment variable')
if (!supabaseServiceKey) throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable')

const supabase = createClient(supabaseUrl, supabaseServiceKey)
const allowedOrigin = Deno.env.get('ALLOWED_ORIGIN') || '*'

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
    const { ride_id, pickup_lat, pickup_lng, radius_meters: raw_radius = 5000 } = await req.json()
    const radius_meters = Math.max(100, Math.min(50000, raw_radius))

    if (!ride_id || !pickup_lat || !pickup_lng) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: ride_id, pickup_lat, pickup_lng' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: ride, error: rideError } = await supabase
      .from('rides')
      .select('driver_id, pickup_address, dropoff_address, fare_amount, passenger:profiles(first_name)')
      .eq('id', ride_id)
      .single()

    if (rideError) {
      return new Response(
        JSON.stringify({ error: 'Ride not found', details: rideError }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (ride.driver_id) {
      return new Response(
        JSON.stringify({ error: 'Ride already accepted', driver_id: ride.driver_id }),
        { status: 409, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: nearbyDrivers, error: driversError } = await supabase.rpc(
      'find_nearby_drivers',
      {
        pickup_lat,
        pickup_lng,
        radius_meters,
      }
    )

    if (driversError) {
      return new Response(
        JSON.stringify({ error: 'Failed to find chauffeurs', details: driversError }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!nearbyDrivers || nearbyDrivers.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No chauffeurs available nearby', ride_id, retry: true }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const selectedDriver = nearbyDrivers[0]

    const { data: driverProfile, error: profileError } = await supabase
      .from('profiles')
      .select('*, driver_details:profile_id(*)')
      .eq('id', selectedDriver.user_id)
      .single()

    if (profileError) {
      return new Response(
        JSON.stringify({ error: 'Failed to get chauffeur profile' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: driverVehicle, error: vehicleError } = await supabase
      .from('vehicles')
      .select('id')
      .eq('driver_id', selectedDriver.user_id)
      .eq('is_active', true)
      .maybeSingle()

    if (vehicleError || !driverVehicle) {
      return new Response(
        JSON.stringify({ error: 'Chauffeur has no active vehicle' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: docsApproved, error: docsError } = await supabase.rpc('driver_documents_approved', {
      driver_uuid: selectedDriver.user_id,
    })

    if (docsError || !docsApproved) {
      return new Response(
        JSON.stringify({ error: 'Chauffeur documents not approved' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { error: assignError } = await supabase
      .from('rides')
      .update({
        driver_id: selectedDriver.user_id,
        status: 'accepted',
      })
      .eq('id', ride_id)
      .is('driver_id', null)

    if (assignError) {
      return new Response(
        JSON.stringify({ error: 'Failed to accept ride', details: assignError }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    supabase.from('notifications').insert({
      user_id: selectedDriver.user_id,
      type: 'ride_request',
      title: 'New Ride Request',
      body: `Ride from ${ride.pickup_address} to ${ride.dropoff_address}`,
      data: {
        ride_id,
        pickup_address: ride.pickup_address,
        dropoff_address: ride.dropoff_address,
        passenger_name: ride.passenger?.first_name,
        fare_amount: ride.fare_amount,
      },
    }).then().catch(() => {})

    return new Response(
      JSON.stringify({
        success: true,
        ride_id,
        driver: {
          user_id: selectedDriver.user_id,
          first_name: selectedDriver.first_name,
          last_name: selectedDriver.last_name,
          rating: selectedDriver.rating,
          distance_meters: selectedDriver.distance_meters,
        },
        message: 'Ride assigned to closest available chauffeur',
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})