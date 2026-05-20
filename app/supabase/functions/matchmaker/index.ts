import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const supabase = createClient(supabaseUrl, supabaseServiceKey)

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
    const { ride_id, pickup_lat, pickup_lng, radius_meters = 5000 } = await req.json()

    if (!ride_id || !pickup_lat || !pickup_lng) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: ride_id, pickup_lat, pickup_lng' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const { data: ride, error: rideError } = await supabase
      .from('rides')
      .select('*, passenger:passenger_id(first_name, last_name)')
      .eq('id', ride_id)
      .single()

    if (rideError || !ride) {
      return new Response(
        JSON.stringify({ error: 'Ride not found' }),
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
        JSON.stringify({ error: 'Failed to find drivers', details: driversError }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!nearbyDrivers || nearbyDrivers.length === 0) {
      await supabase
        .from('rides')
        .update({ status: 'cancelled' })
        .eq('id', ride_id)

      return new Response(
        JSON.stringify({ error: 'No drivers available nearby' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const selectedDriver = nearbyDrivers[0]

    const { data: driverProfile, error: profileError } = await supabase
      .from('driver_profiles')
      .select('*, user:user_id(*)')
      .eq('user_id', selectedDriver.user_id)
      .single()

    if (profileError) {
      return new Response(
        JSON.stringify({ error: 'Failed to get driver profile' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const driverHasVehicle = await supabase
      .from('vehicles')
      .select('id')
      .eq('driver_id', selectedDriver.user_id)
      .eq('is_active', true)
      .single()

    if (!driverHasVehicle) {
      return new Response(
        JSON.stringify({ error: 'Driver has no active vehicle' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const driverHasApprovedDocs = await supabase.rpc('driver_documents_approved', {
      driver_uuid: selectedDriver.user_id,
    })

    if (!driverHasApprovedDocs) {
      return new Response(
        JSON.stringify({ error: 'Driver documents not approved' }),
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

    await supabase.from('notifications').insert({
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
    })

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
        message: 'Ride assigned to closest available driver',
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