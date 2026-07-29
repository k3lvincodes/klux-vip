import { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import mapboxgl from 'mapbox-gl';
import 'mapbox-gl/dist/mapbox-gl.css';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';
import { supabase } from '../lib/supabase';
import { STEPS, type Step, type BookingFormData, type FareBreakdown, type BookingConfirmation as BookingConfirmationData } from './booking/types';
import BookingTripForm from './booking/BookingTripForm';
import BookingFare from './booking/BookingFare';
import PaymentForm from './booking/PaymentForm';
import BookingConfirmation from './booking/BookingConfirmation';

mapboxgl.accessToken = import.meta.env.VITE_MAPBOX_TOKEN;

const stripePromise = loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY || '');

export default function BookingPage() {
  const [searchParams] = useSearchParams();
  const initialVehicle = searchParams.get('vehicle') || 'Standard SUV';

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const leafletRef = useRef<{ map: unknown; script: HTMLScriptElement | null } | null>(null);

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
  const [confirmation, setConfirmation] = useState<BookingConfirmationData | null>(null);

  useEffect(() => {
    if (searchParams.get('vehicle')) {
      setBookingForm((prev: BookingFormData) => ({ ...prev, vehicle: searchParams.get('vehicle')! }));
    }
  }, [searchParams.get('vehicle')]);

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

          {error && (
            <div style={{ background: '#fef2f2', border: '1px solid #fecaca', borderRadius: '10px', padding: '12px 16px', marginBottom: '20px', color: '#dc2626', fontSize: '0.9rem' }}>
              {error}
            </div>
          )}

          {/* STEP 1: Trip Details */}
          {step === STEPS.TRIP && (
            <BookingTripForm
              bookingForm={bookingForm}
              onChange={handleChange}
              onSubmit={handleCalculateFare}
              isCalculating={isCalculating}
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
              onContinue={() => setStep(STEPS.PAYMENT)}
            />
          )}

          {/* STEP 3: Stripe Payment */}
          {step === STEPS.PAYMENT && fare && (
            <Elements stripe={stripePromise}>
              <PaymentForm
                fare={fare}
                bookingForm={bookingForm}
                onBack={() => setStep(STEPS.FARE)}
                onSuccess={(conf) => {
                  setConfirmation(conf);
                  setStep(STEPS.CONFIRMATION);
                }}
                onError={setError}
              />
            </Elements>
          )}

          {/* STEP 4: Confirmation + Invoice */}
          {step === STEPS.CONFIRMATION && confirmation && (
            <BookingConfirmation confirmation={confirmation} onReset={handleReset} />
          )}

        </div>
      </div>
    </div>
  );
}
