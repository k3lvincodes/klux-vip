import { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { Check, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { STEPS, type Step, type BookingFormData, type FareBreakdown, type BookingConfirmation as BookingConfirmationData, type AssignedChauffeur } from './booking/types';
import type { LocationSuggestion } from '../services/locationService';
import BookingTripForm from './booking/BookingTripForm';
import BookingFare from './booking/BookingFare';
import ChauffeurAssignment from './booking/ChauffeurAssignment';
import PaymentForm from './booking/PaymentForm';
import BookingConfirmation from './booking/BookingConfirmation';
import '../styles/booking.css';



mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN;

export default function BookingPage() {
  const [searchParams] = useSearchParams();
  const initialVehicle = searchParams.get('vehicle') || 'Standard SUV';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const leafletRef = useRef<{ map: unknown; script: HTMLScriptElement | null } | null>(null);
  const pickupMarkerRef = useRef<any>(null);
  const dropoffMarkerRef = useRef<any>(null);

  const [step, setStep] = useState<Step>(STEPS.TRIP);
  const [bookingForm, setBookingForm] = useState<BookingFormData>({
    pickup: '',
    dropoff: '',
    date: '',
    time: '',
    vehicle: initialVehicle,
    passengers: '1',
    name: '',
    email: '',
    phone: '',
  });

  const [isCalculating, setIsCalculating] = useState(false);
  const [fare, setFare] = useState<FareBreakdown | null>(null);
  const [tipPercent, setTipPercent] = useState<number | null>(20);
  const [customTip, setCustomTip] = useState('');
  const [tipMode, setTipMode] = useState<'percent' | 'custom' | 'none'>('percent');
  const [error, setError] = useState('');
  const [chauffeur, setChauffeur] = useState<AssignedChauffeur | null>(null);
  const [confirmation, setConfirmation] = useState<BookingConfirmationData | null>(null);

  useEffect(() => {
    if (searchParams.get('vehicle')) {
      setBookingForm((prev: BookingFormData) => ({ ...prev, vehicle: searchParams.get('vehicle')! }));
    }

    // Check for return from Stripe Hosted Checkout
    const isConfirmed = searchParams.get('confirmed') === 'true';
    const isCanceled = searchParams.get('canceled') === 'true';

    if (isConfirmed) {
      let storedBooking: Partial<BookingConfirmationData> = {};
      try {
        const raw = sessionStorage.getItem('kenick_pending_booking');
        if (raw) storedBooking = JSON.parse(raw);
      } catch {
        // Ignore JSON error
      }

      const invoice = searchParams.get('invoice') || storedBooking.invoiceNumber || `INV-${Date.now().toString(36).toUpperCase()}`;
      const booking = searchParams.get('booking') || storedBooking.confirmationNumber || `BK-${Date.now().toString(36).toUpperCase()}`;
      const pickup = searchParams.get('pickup') || storedBooking.pickup || 'Pickup Location';
      const dropoff = searchParams.get('dropoff') || storedBooking.dropoff || 'Destination';
      const date = searchParams.get('date') || storedBooking.date || new Date().toISOString().split('T')[0];
      const time = searchParams.get('time') || storedBooking.time || '12:00';
      const vehicle = searchParams.get('vehicle') || storedBooking.vehicle || 'Standard SUV';
      const total = parseFloat(searchParams.get('total') || '0') || storedBooking.total || 145.00;

      if (storedBooking.chauffeur) {
        setChauffeur(storedBooking.chauffeur);
      }

      setConfirmation({
        invoiceNumber: invoice,
        confirmationNumber: booking,
        pickup,
        dropoff,
        date,
        time,
        vehicle,
        baseFare: storedBooking.baseFare || total * 0.8,
        tip: storedBooking.tip || total * 0.2,
        tax: 0,
        total,
        chauffeur: storedBooking.chauffeur,
      });
      setStep(STEPS.CONFIRMATION);
    } else if (isCanceled) {
      setError('Payment was canceled on Stripe. You can review your trip details and try again.');
    }
  }, [searchParams]);

  // Initialize Mapbox / Fallback Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) return;

    mapContainerRef.current.innerHTML = '';

    let leafletLoaded = false;

    const loadLeafletFallback = () => {
      if (leafletLoaded) return;
      leafletLoaded = true;

      if (!document.getElementById('leaflet-css')) {
        const link = document.createElement('link');
        link.id = 'leaflet-css';
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        document.head.appendChild(link);
      }

      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.async = true;
      script.onload = () => {
        if (!mapContainerRef.current) return;
        mapContainerRef.current.innerHTML = '';
        
        const L = (window as any).L;
        if (!L) return;

        leafletRef.current = { map: null, script };

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

        leafletRef.current!.map = lMap;

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

        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (pos) => {
              const { latitude, longitude } = pos.coords;
              lMap.setView([latitude, longitude], 14);
              marker.setLatLng([latitude, longitude]);
            },
            () => {},
            { enableHighAccuracy: true, timeout: 5000 }
          );
        }
      };
      document.head.appendChild(script);
    };

    try {
      const testMap = new mapboxgl.Map({
        container: document.createElement('div'),
        style: 'mapbox://styles/mapbox/dark-v11',
        accessToken: mapboxgl.accessToken || '',
      });
      
      const timeout = setTimeout(() => {
        try { testMap.remove(); } catch {}
        loadLeafletFallback();
      }, 4000);

      testMap.on('load', () => {
        clearTimeout(timeout);
        try { testMap.remove(); } catch {}
        
        if (!mapContainerRef.current) return;

        const map = new mapboxgl.Map({
          container: mapContainerRef.current,
          style: 'mapbox://styles/mapbox/dark-v11',
          zoom: 12,
          center: [-74.006, 40.7128],
          attributionControl: false,
        });

        map.addControl(new mapboxgl.NavigationControl({ showCompass: false }), 'bottom-left');

        const marker = new mapboxgl.Marker({ color: '#F4C522' })
          .setLngLat([-74.006, 40.7128])
          .addTo(map);

        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (pos) => {
              const { latitude, longitude } = pos.coords;
              map.setCenter([longitude, latitude]);
              map.setZoom(14);
              marker.setLngLat([longitude, latitude]);
            },
            () => {},
            { enableHighAccuracy: true, timeout: 5000 }
          );
        }

        mapRef.current = map;
      });

      testMap.on('error', () => {
        loadLeafletFallback();
      });
    } catch {
      loadLeafletFallback();
    }

    return () => {
      if (mapRef.current) {
        try { mapRef.current.remove(); } catch {}
        mapRef.current = null;
      }
      if (leafletRef.current?.script) {
        leafletRef.current.script.remove();
        leafletRef.current = null;
      }
    };
  }, []);

  const updateMapLocation = (type: 'pickup' | 'dropoff', lat: number, lng: number) => {
    if (mapRef.current) {
      const map = mapRef.current;
      if (type === 'pickup') {
        if (!pickupMarkerRef.current) {
          pickupMarkerRef.current = new mapboxgl.Marker({ color: '#F4C522' })
            .setLngLat([lng, lat])
            .addTo(map);
        } else {
          pickupMarkerRef.current.setLngLat([lng, lat]);
        }
      } else {
        if (!dropoffMarkerRef.current) {
          dropoffMarkerRef.current = new mapboxgl.Marker({ color: '#ffffff' })
            .setLngLat([lng, lat])
            .addTo(map);
        } else {
          dropoffMarkerRef.current.setLngLat([lng, lat]);
        }
      }

      if (pickupMarkerRef.current && dropoffMarkerRef.current) {
        const pLngLat = pickupMarkerRef.current.getLngLat();
        const dLngLat = dropoffMarkerRef.current.getLngLat();
        const bounds = new mapboxgl.LngLatBounds();
        bounds.extend(pLngLat);
        bounds.extend(dLngLat);
        map.fitBounds(bounds, { padding: 120, maxZoom: 15 });
      } else {
        map.flyTo({ center: [lng, lat], zoom: 14, essential: true });
      }
    } else if (leafletRef.current?.map) {
      const lMap = leafletRef.current.map as any;
      const L = (window as any).L;
      if (L && lMap) {
        if (type === 'pickup') {
          if (!pickupMarkerRef.current) {
            pickupMarkerRef.current = L.marker([lat, lng]).addTo(lMap);
          } else {
            pickupMarkerRef.current.setLatLng([lat, lng]);
          }
        } else {
          if (!dropoffMarkerRef.current) {
            dropoffMarkerRef.current = L.marker([lat, lng]).addTo(lMap);
          } else {
            dropoffMarkerRef.current.setLatLng([lat, lng]);
          }
        }

        if (pickupMarkerRef.current && dropoffMarkerRef.current) {
          const group = L.featureGroup([pickupMarkerRef.current, dropoffMarkerRef.current]);
          lMap.fitBounds(group.getBounds().pad(0.2));
        } else {
          lMap.setView([lat, lng], 14);
        }
      }
    }
  };

  const handleSelectPickupLocation = (loc: LocationSuggestion) => {
    setBookingForm((prev) => ({
      ...prev,
      pickup: loc.placeName,
      pickupCoords: { lat: loc.lat, lng: loc.lng },
    }));
    updateMapLocation('pickup', loc.lat, loc.lng);
  };

  const handleSelectDropoffLocation = (loc: LocationSuggestion) => {
    setBookingForm((prev) => ({
      ...prev,
      dropoff: loc.placeName,
      dropoffCoords: { lat: loc.lat, lng: loc.lng },
    }));
    updateMapLocation('dropoff', loc.lat, loc.lng);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setBookingForm((prev: BookingFormData) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleTipPercent = (pct: number) => {
    setTipMode('percent');
    setTipPercent(pct);
    setCustomTip('');
    if (fare) {
      const tipAmount = fare.subtotal * (pct / 100);
      setFare((prev: FareBreakdown | null) => prev ? { ...prev, tip: tipAmount, total: prev.subtotal + tipAmount } : prev);
    }
  };

  const handleCustomTip = (val: string) => {
    setTipMode('custom');
    setTipPercent(null);
    setCustomTip(val);
    const tipAmount = parseFloat(val) || 0;
    if (fare) {
      setFare((prev: FareBreakdown | null) => prev ? { ...prev, tip: tipAmount, total: prev.subtotal + tipAmount } : prev);
    }
  };

  const validateBookingForm = (): string | null => {
    if (!bookingForm.pickup?.trim()) return 'Pickup location is required';
    if (!bookingForm.dropoff?.trim()) return 'Dropoff location is required';
    if (!bookingForm.date) return 'Date is required';
    if (!bookingForm.time) return 'Time is required';
    if (!bookingForm.name?.trim()) return 'Full name is required';
    if (!bookingForm.email?.trim()) return 'Email is required';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(bookingForm.email)) return 'Invalid email format';
    if (!bookingForm.phone?.trim()) return 'Phone is required';
    if (!/^\+?[\d\s-]{7,}$/.test(bookingForm.phone)) return 'Invalid phone format';
    return null;
  };

  const handleCalculateFare = async () => {
    const validationError = validateBookingForm();
    if (validationError) {
      setError(validationError);
      return;
    }

    setIsCalculating(true);
    setError('');
    try {
      const { data: rates } = await supabase
        .from('fare_rates')
        .select('*')
        .eq('country_code', 'US')
        .is('state_or_region', null)
        .single();

      const baseFare = rates?.base_fare ?? 3.50;
      const perKmRate = rates?.per_km_rate ?? 1.85;
      const estimatedDistanceKm = 8 + Math.random() * 12;
      const tripFare = baseFare + (estimatedDistanceKm * perKmRate);
      const subtotal = baseFare + tripFare;
      const initialTip = subtotal * 0.20;

      setFare({
        baseFare,
        tripFare: Math.round(tripFare * 100) / 100,
        subtotal: Math.round(subtotal * 100) / 100,
        tip: Math.round(initialTip * 100) / 100,
        total: Math.round((subtotal + initialTip) * 100) / 100,
      });
      setStep(STEPS.FARE);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to calculate fare. Please try again.');
    } finally {
      setIsCalculating(false);
    }
  };

  const handleReset = () => {
    setStep(STEPS.TRIP);
    setFare(null);
    setConfirmation(null);
    setChauffeur(null);
    setError('');
    setBookingForm({ pickup: '', dropoff: '', date: '', time: '', vehicle: initialVehicle, passengers: '1', name: '', email: '', phone: '' });
  };

  return (
    <div className="booking-page-container">
      {/* Full-Screen Mapbox Container */}
      <div ref={mapContainerRef} className="booking-map-container" />

      {/* Floating Booking Modal - right side */}
      <div className="booking-modal-container no-scrollbar">
        <div className="booking-modal-content">
          {/* Step Progress Tracker (Centered Connected Segments) */}
          <div className="booking-step-tracker">
            {/* Step 1: Route */}
            <div className={`booking-step-node ${step === STEPS.TRIP ? 'active' : step > STEPS.TRIP ? 'completed' : ''}`}>
              <div className="booking-step-circle">
                {step > STEPS.TRIP ? <Check size={13} strokeWidth={3} /> : '1'}
              </div>
              <span className="booking-step-label">Route</span>
            </div>

            <div className={`booking-step-connector ${step > STEPS.TRIP ? 'filled' : ''}`} />

            {/* Step 2: Tariff */}
            <div className={`booking-step-node ${step === STEPS.FARE ? 'active' : step > STEPS.FARE ? 'completed' : ''}`}>
              <div className="booking-step-circle">
                {step > STEPS.FARE ? <Check size={13} strokeWidth={3} /> : '2'}
              </div>
              <span className="booking-step-label">Tariff</span>
            </div>

            <div className={`booking-step-connector ${step > STEPS.FARE ? 'filled' : ''}`} />

            {/* Step 3: Chauffeur */}
            <div className={`booking-step-node ${step === STEPS.CHAUFFEUR ? 'active' : step > STEPS.CHAUFFEUR ? 'completed' : ''}`}>
              <div className="booking-step-circle">
                {step > STEPS.CHAUFFEUR ? <Check size={13} strokeWidth={3} /> : '3'}
              </div>
              <span className="booking-step-label">Chauffeur</span>
            </div>

            <div className={`booking-step-connector ${step > STEPS.CHAUFFEUR ? 'filled' : ''}`} />

            {/* Step 4: Payment */}
            <div className={`booking-step-node ${step === STEPS.PAYMENT ? 'active' : step > STEPS.PAYMENT ? 'completed' : ''}`}>
              <div className="booking-step-circle">
                {step > STEPS.PAYMENT ? <Check size={13} strokeWidth={3} /> : '4'}
              </div>
              <span className="booking-step-label">Payment</span>
            </div>

            <div className={`booking-step-connector ${step > STEPS.PAYMENT ? 'filled' : ''}`} />

            {/* Step 5: Voucher */}
            <div className={`booking-step-node ${step === STEPS.CONFIRMATION ? 'active' : ''}`}>
              <div className="booking-step-circle">
                {step === STEPS.CONFIRMATION ? <Check size={13} strokeWidth={3} /> : '5'}
              </div>
              <span className="booking-step-label">Voucher</span>
            </div>
          </div>

          {error && (
            <div style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.25)', borderRadius: '10px', padding: '12px 16px', marginBottom: '20px', color: '#fca5a5', fontSize: '0.86rem', display: 'flex', alignItems: 'center', gap: 8 }}>
              <AlertCircle size={16} color="#ef4444" style={{ flexShrink: 0 }} />
              <span>{error}</span>
            </div>
          )}

          {/* STEP 1: Trip Details */}
          {step === STEPS.TRIP && (
            <BookingTripForm
              bookingForm={bookingForm}
              onChange={handleChange}
              onSubmit={handleCalculateFare}
              isCalculating={isCalculating}
              onSelectPickupLocation={handleSelectPickupLocation}
              onSelectDropoffLocation={handleSelectDropoffLocation}
            />
          )}

          {/* STEP 2: Fare Breakdown + Tip */}
          {step === STEPS.FARE && fare && (
            <BookingFare
              fare={fare}
              tipMode={tipMode}
              tipPercent={tipPercent}
              customTip={customTip}
              onTipModeChange={setTipMode}
              onTipPercentChange={handleTipPercent}
              onCustomTipChange={handleCustomTip}
              onBack={() => setStep(STEPS.TRIP)}
              onContinue={() => setStep(STEPS.CHAUFFEUR)}
            />
          )}

          {/* STEP 3: Chauffeur Assignment */}
          {step === STEPS.CHAUFFEUR && fare && (
            <ChauffeurAssignment
              bookingForm={bookingForm}
              fare={fare}
              onBack={() => setStep(STEPS.FARE)}
              onConfirmChauffeur={(assigned) => {
                setChauffeur(assigned);
                setStep(STEPS.PAYMENT);
              }}
            />
          )}

          {/* STEP 4: Stripe Hosted Payment */}
          {step === STEPS.PAYMENT && fare && (
            <PaymentForm
              fare={fare}
              bookingForm={bookingForm}
              chauffeur={chauffeur}
              onBack={() => setStep(STEPS.CHAUFFEUR)}
              onSuccess={(conf) => {
                setConfirmation(conf);
                setStep(STEPS.CONFIRMATION);
              }}
              onError={setError}
            />
          )}

          {/* STEP 5: Confirmation + Invoice */}
          {step === STEPS.CONFIRMATION && confirmation && (
            <BookingConfirmation confirmation={confirmation} onReset={handleReset} />
          )}

        </div>
      </div>
    </div>
  );
}

