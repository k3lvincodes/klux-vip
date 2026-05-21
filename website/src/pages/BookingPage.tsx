import { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { CheckCircle2, MapPin, Calendar, Clock, Car } from 'lucide-react';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';

mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN;

export default function BookingPage() {
  const [searchParams] = useSearchParams();
  const initialVehicle = searchParams.get('vehicle') || 'Standard SUV';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);

  const [bookingForm, setBookingForm] = useState({
    pickup: '',
    dropoff: '',
    date: '',
    time: '',
    vehicle: initialVehicle,
    passengers: '1'
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  useEffect(() => {
    if (searchParams.get('vehicle')) {
      setBookingForm(prev => ({ ...prev, vehicle: searchParams.get('vehicle')! }));
    }
  }, [searchParams]);

  // Initialize Mapbox
  // Initialize Mapbox / Fallback Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) return;

    // React 18 Strict Mode workaround: ensure container is empty
    mapContainerRef.current.innerHTML = '';

    let leafletLoaded = false;

    const loadLeafletFallback = () => {
      if (leafletLoaded) return;
      leafletLoaded = true;

      // 1. Append Leaflet CSS to head if not present
      if (!document.getElementById('leaflet-css')) {
        const link = document.createElement('link');
        link.id = 'leaflet-css';
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        document.head.appendChild(link);
      }

      // 2. Load Leaflet JS
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.async = true;
      script.onload = () => {
        if (!mapContainerRef.current) return;
        mapContainerRef.current.innerHTML = '';
        
        // @ts-ignore
        const L = window.L;
        if (!L) return;

        const lMap = L.map(mapContainerRef.current, {
          zoomControl: false
        }).setView([40.7128, -74.006], 12);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
          subdomains: 'abcd',
          maxZoom: 20
        }).addTo(lMap);

        L.control.zoom({
          position: 'bottomleft'
        }).addTo(lMap);

        // Add a custom marker
        const customIcon = L.divIcon({
          className: 'custom-leaflet-marker',
          html: `
            <div style="display:flex;flex-direction:column;align-items:center;">
              <div style="background:#F4C522;color:#000;padding:6px 14px;border-radius:20px;font-weight:bold;font-size:12px;margin-bottom:6px;box-shadow:0 4px 12px rgba(0,0,0,0.3);font-family:Poppins,sans-serif;white-space:nowrap;transform:translateY(-10px);">
                You are here
              </div>
              <div style="width:20px;height:20px;background:#F4C522;border:3px solid #000;border-radius:50%;box-shadow:0 0 0 6px rgba(244,197,34,0.3);"></div>
            </div>
          `,
          iconSize: [20, 20],
          iconAnchor: [10, 20]
        });

        const marker = L.marker([40.7128, -74.006], { icon: customIcon }).addTo(lMap);

        // Get user's current location
        if ('geolocation' in navigator) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              const { longitude, latitude } = position.coords;
              lMap.setView([latitude, longitude], 14);
              marker.setLatLng([latitude, longitude]);
            },
            (err) => {
              console.warn('Leaflet Geolocation error:', err.message);
            }
          );
        }
      };
      document.body.appendChild(script);
    };

    let map: mapboxgl.Map | null = null;
    let mapTimeout: number | undefined;

    try {
      // Set a timeout of 2.5 seconds. If Mapbox style fails to load or takes too long, switch to Leaflet CartoDB map
      mapTimeout = window.setTimeout(() => {
        if (!map || !map.isStyleLoaded()) {
          console.warn('Mapbox style loading timed out. Swapping to Leaflet fallback...');
          if (map) {
            try {
              map.remove();
            } catch (e) {
              console.warn('Failed to clean up mapbox on timeout:', e);
            }
            map = null;
            mapRef.current = null;
          }
          loadLeafletFallback();
        }
      }, 2500);

      map = new mapboxgl.Map({
        container: mapContainerRef.current,
        style: 'mapbox://styles/mapbox/dark-v11',
        center: [-74.006, 40.7128], // Default: New York
        zoom: 12,
      });

      mapRef.current = map;

      map.on('load', () => {
        if (mapTimeout) clearTimeout(mapTimeout);
        if (map) {
          map.resize();
        }
      });

      map.on('error', (e) => {
        console.warn('Mapbox encountered error, swapping to Leaflet...', e);
        if (mapTimeout) clearTimeout(mapTimeout);
        if (map) {
          try {
            map.remove();
          } catch (err) {
            console.warn('Failed to remove Mapbox map on error:', err);
          }
          map = null;
          mapRef.current = null;
        }
        loadLeafletFallback();
      });

      map.addControl(new mapboxgl.NavigationControl(), 'bottom-left');

      // Get user's current location
      if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            if (!map) return;
            const { longitude, latitude } = position.coords;

            // Fly to user location
            map.flyTo({
              center: [longitude, latitude],
              zoom: 14,
              padding: { right: 480, left: 0, top: 0, bottom: 0 }, // offset so marker centers in visible left area
              duration: 2000,
            });

            // Create a custom marker element
            const markerEl = document.createElement('div');
            markerEl.innerHTML = `
              <div style="display:flex;flex-direction:column;align-items:center;">
                <div style="background:#F4C522;color:#000;padding:6px 14px;border-radius:20px;font-weight:bold;font-size:12px;margin-bottom:6px;box-shadow:0 4px 12px rgba(0,0,0,0.3);font-family:Poppins,sans-serif;white-space:nowrap;">
                  You are here
                </div>
                <div style="width:20px;height:20px;background:#F4C522;border:3px solid #000;border-radius:50%;box-shadow:0 0 0 6px rgba(244,197,34,0.3);"></div>
              </div>
            `;

            new mapboxgl.Marker({ element: markerEl, anchor: 'bottom' })
              .setLngLat([longitude, latitude])
              .addTo(map);
          },
          (err) => {
            console.warn('Geolocation error:', err.message);
          }
        );
      }
    } catch (err) {
      console.warn('Failed to initialize Mapbox synchronously. Swapping to Leaflet fallback...', err);
      if (mapTimeout) clearTimeout(mapTimeout);
      if (map) {
        try {
          map.remove();
        } catch (e) {
          console.warn('Failed to clean up Mapbox map on exception:', e);
        }
        map = null;
        mapRef.current = null;
      }
      loadLeafletFallback();
    }

    return () => {
      if (mapTimeout) clearTimeout(mapTimeout);
      if (mapRef.current) {
        try {
          mapRef.current.remove();
        } catch (e) {
          console.warn('Cleanup error:', e);
        }
        mapRef.current = null;
      }
    };
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setBookingForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    await new Promise(resolve => setTimeout(resolve, 1500));
    setIsSubmitting(false);
    setSubmitSuccess(true);
  };

  return (
    <div className="booking-page-container">

      {/* Full-Screen Mapbox Container */}
      <div ref={mapContainerRef} className="booking-map-container" />

      {/* Floating Booking Modal - right side */}
      <div className="booking-modal-container no-scrollbar">
        <div className="booking-modal-content">
          <h2 style={{
            textAlign: 'center',
            marginBottom: '1.75rem',
            fontSize: '1.75rem',
            fontWeight: 700,
            color: '#000',
          }}>
            Book Your Ride
          </h2>

          {submitSuccess ? (
            <div style={{ textAlign: 'center', padding: '20px', background: '#f0fdf4', borderRadius: '16px', border: '1px solid #bbf7d0' }}>
              <CheckCircle2 size={64} color="#10b981" style={{ margin: '0 auto 20px' }} />
              <h3 style={{ color: '#000', marginBottom: '8px' }}>Booking Confirmed!</h3>
              <p style={{ color: '#64748b', marginTop: '10px', fontSize: '0.9rem' }}>
                Your ride for {bookingForm.date} at {bookingForm.time} has been successfully booked.
                We'll send a confirmation email shortly.
              </p>
              <button
                style={{
                  marginTop: '20px',
                  width: '100%',
                  padding: '14px',
                  background: '#000',
                  color: '#fff',
                  borderRadius: '12px',
                  fontWeight: 600,
                  fontSize: '0.95rem',
                  cursor: 'pointer',
                  border: 'none',
                  fontFamily: 'inherit',
                  transition: 'background 0.3s',
                }}
                onClick={() => {
                  setSubmitSuccess(false);
                  setBookingForm({ pickup: '', dropoff: '', date: '', time: '', vehicle: 'Standard SUV', passengers: '1' });
                }}
              >
                Book Another Ride
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>

              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                  <MapPin size={15} /> Pickup Location
                </label>
                <input
                  type="text"
                  name="pickup"
                  value={bookingForm.pickup}
                  onChange={handleChange}
                  placeholder="Enter pickup address or airport"
                  required
                  style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', outline: 'none', transition: 'border 0.2s', color: '#000', background: '#fff' }}
                  onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
                  onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
                />
              </div>

              <div style={{ marginBottom: '20px' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                  <MapPin size={15} /> Drop-off Location
                </label>
                <input
                  type="text"
                  name="dropoff"
                  value={bookingForm.dropoff}
                  onChange={handleChange}
                  placeholder="Enter drop-off address or airport"
                  required
                  style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', outline: 'none', transition: 'border 0.2s', color: '#000', background: '#fff' }}
                  onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
                  onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
                />
              </div>

              <div className="booking-form-row" style={{ marginBottom: '20px' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                    <Calendar size={15} /> Date
                  </label>
                  <input
                    type="date"
                    name="date"
                    value={bookingForm.date}
                    onChange={handleChange}
                    required
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', outline: 'none', color: '#000', background: '#fff' }}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                    <Clock size={15} /> Time
                  </label>
                  <input
                    type="time"
                    name="time"
                    value={bookingForm.time}
                    onChange={handleChange}
                    required
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', outline: 'none', color: '#000', background: '#fff' }}
                  />
                </div>
              </div>

              <div className="booking-form-row" style={{ marginBottom: '28px' }}>
                <div style={{ flex: 2 }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                    <Car size={15} /> Vehicle Type
                  </label>
                  <select
                    name="vehicle"
                    value={bookingForm.vehicle}
                    onChange={handleChange}
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', color: '#000', background: '#fff', cursor: 'pointer' }}
                  >
                    <option value="GMC Yukon">GMC Yukon</option>
                    <option value="Cadillac Escalade">Cadillac Escalade</option>
                    <option value="Ford Expedition">Ford Expedition</option>
                    <option value="Standard SUV">Standard SUV</option>
                  </select>
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px', fontWeight: 600, fontSize: '0.88rem', color: '#333' }}>
                    Passengers
                  </label>
                  <select
                    name="passengers"
                    value={bookingForm.passengers}
                    onChange={handleChange}
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '10px', border: '1.5px solid #d1d5db', fontSize: '0.95rem', fontFamily: 'inherit', color: '#000', background: '#fff', cursor: 'pointer' }}
                  >
                    {[1, 2, 3, 4, 5, 6, 7].map(num => (
                      <option key={num} value={num}>{num}</option>
                    ))}
                  </select>
                </div>
              </div>

              <button
                type="submit"
                disabled={isSubmitting}
                style={{
                  width: '100%',
                  padding: '16px',
                  fontSize: '1rem',
                  fontWeight: 700,
                  borderRadius: '12px',
                  background: '#F4C522',
                  color: '#000',
                  border: 'none',
                  cursor: isSubmitting ? 'not-allowed' : 'pointer',
                  opacity: isSubmitting ? 0.7 : 1,
                  fontFamily: 'inherit',
                  transition: 'background 0.3s, transform 0.15s',
                }}
                onMouseEnter={e => { if (!isSubmitting) e.currentTarget.style.background = '#DCA70B'; }}
                onMouseLeave={e => { e.currentTarget.style.background = '#F4C522'; }}
              >
                {isSubmitting ? 'Processing...' : 'Confirm Booking'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
