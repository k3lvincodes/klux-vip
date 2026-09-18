import { useState, useEffect, useRef, useCallback } from 'react';
import { ArrowLeft, ArrowRight, Star, Car, CheckCircle2, Clock, AlertTriangle, UserCheck, RefreshCw, XCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';

import type { BookingFormData, FareBreakdown, AssignedChauffeur } from './types';

interface Props {
  bookingForm: BookingFormData;
  fare: FareBreakdown;
  onBack: () => void;
  onConfirmChauffeur: (chauffeur: AssignedChauffeur) => void;
}

// Car-Specific Executive Chauffeur Fleets (3 verified drivers per vehicle tier)
const FLEET_CANDIDATES: Record<string, AssignedChauffeur[]> = {
  'Cadillac Escalade': [
    {
      id: 'd1000000-0000-0000-0000-000000000001',
      name: 'Marcus Vance',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 742-8901',
      rating: 4.99,
      tripsCount: 342,
      yearsExperience: 7,
      vehicleName: '2024 Cadillac Escalade ESV',
      licensePlate: 'KLX-8821',
      color: 'Onyx Black · Extended Wheelbase',
    },
    {
      id: 'd1000000-0000-0000-0000-000000000002',
      name: 'Robert Sterling',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 742-9922',
      rating: 4.98,
      tripsCount: 295,
      yearsExperience: 6,
      vehicleName: '2024 Cadillac Escalade ESV Luxury',
      licensePlate: 'KLX-8845',
      color: 'Jet Black Metallic · Privacy Glass',
    },
    {
      id: 'd1000000-0000-0000-0000-000000000003',
      name: 'Anthony Davis',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 742-1044',
      rating: 4.97,
      tripsCount: 218,
      yearsExperience: 5,
      vehicleName: '2023 Cadillac Escalade Sport Platinum',
      licensePlate: 'KLX-8890',
      color: 'Black Velvet · Captain Chairs',
    },
  ],
  'GMC Yukon': [
    {
      id: 'd2000000-0000-0000-0000-000000000001',
      name: 'David Sterling',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 619-3320',
      rating: 4.98,
      tripsCount: 289,
      yearsExperience: 6,
      vehicleName: '2024 GMC Yukon Denali XL',
      licensePlate: 'KLX-4092',
      color: 'Midnight Black · Chrome Trim',
    },
    {
      id: 'd2000000-0000-0000-0000-000000000002',
      name: 'Michael Chen',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 619-8811',
      rating: 4.96,
      tripsCount: 240,
      yearsExperience: 5,
      vehicleName: '2024 GMC Yukon Denali XL Ultimate',
      licensePlate: 'KLX-4055',
      color: 'Onyx Black · Luxury Interior',
    },
    {
      id: 'd2000000-0000-0000-0000-000000000003',
      name: 'Raymond Hayes',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 619-4455',
      rating: 4.97,
      tripsCount: 195,
      yearsExperience: 5,
      vehicleName: '2023 GMC Yukon XL AT4',
      licensePlate: 'KLX-4100',
      color: 'Summit Black · Extended Cabin',
    },
  ],
  'Ford Expedition': [
    {
      id: 'd3000000-0000-0000-0000-000000000001',
      name: 'James Montgomery',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 883-4912',
      rating: 4.97,
      tripsCount: 215,
      yearsExperience: 5,
      vehicleName: '2024 Ford Expedition Max Limited',
      licensePlate: 'KLX-7714',
      color: 'Agate Black · Long Wheelbase',
    },
    {
      id: 'd3000000-0000-0000-0000-000000000002',
      name: 'Ethan Wright',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 883-2288',
      rating: 4.95,
      tripsCount: 180,
      yearsExperience: 4,
      vehicleName: '2024 Ford Expedition Max Platinum',
      licensePlate: 'KLX-7730',
      color: 'Shadow Black · Executive Glass',
    },
    {
      id: 'd3000000-0000-0000-0000-000000000003',
      name: 'William Price',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 883-6611',
      rating: 4.96,
      tripsCount: 172,
      yearsExperience: 5,
      vehicleName: '2023 Ford Expedition Max Stealth',
      licensePlate: 'KLX-7799',
      color: 'Magnetic Black Metallic',
    },
  ],
  'Standard SUV': [
    {
      id: 'd4000000-0000-0000-0000-000000000001',
      name: 'Lucas Bennett',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 431-2950',
      rating: 4.96,
      tripsCount: 198,
      yearsExperience: 5,
      vehicleName: 'Executive Suburban SUV',
      licensePlate: 'KLX-3390',
      color: 'Jet Black Metallic',
    },
    {
      id: 'd4000000-0000-0000-0000-000000000002',
      name: 'Oliver Ross',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 431-8844',
      rating: 4.94,
      tripsCount: 165,
      yearsExperience: 4,
      vehicleName: 'Executive Tahoe SUV',
      licensePlate: 'KLX-3312',
      color: 'Midnight Black',
    },
    {
      id: 'd4000000-0000-0000-0000-000000000003',
      name: 'Daniel Cooper',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      phone: '+1 (555) 431-7711',
      rating: 4.95,
      tripsCount: 154,
      yearsExperience: 4,
      vehicleName: 'Executive Navigator SUV',
      licensePlate: 'KLX-3367',
      color: 'Black Obsidian',
    },
  ],
};

type DispatchState = 'dispatching' | 'accepted' | 'timed_out_cancelled';

export default function ChauffeurAssignment({
  bookingForm,
  fare,
  onBack,
  onConfirmChauffeur,
}: Props) {
  // Pool of chauffeurs registered for the client's chosen vehicle
  const candidatePool = FLEET_CANDIDATES[bookingForm.vehicle] || FLEET_CANDIDATES['Standard SUV'];

  const [driverIndex, setDriverIndex] = useState(0);
  const [driverSecondsLeft, setDriverSecondsLeft] = useState(120); // 2 minutes (120s) per chauffeur
  const [globalSecondsLeft, setGlobalSecondsLeft] = useState(1800); // 30 minutes (1800s) maximum window
  const [dispatchStatus, setDispatchStatus] = useState<DispatchState>('dispatching');
  const [confirmedDriver, setConfirmedDriver] = useState<AssignedChauffeur | null>(null);
  const [rotationNotice, setRotationNotice] = useState<string | null>(null);
  const [requestId, setRequestId] = useState<string | null>(null);

  const currentCandidate = candidatePool[driverIndex % candidatePool.length];
  const totalAvailable = candidatePool.length;
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Advance dispatch to next available chauffeur with matching car
  const advanceToNextChauffeur = useCallback((reason: 'timeout' | 'declined') => {
    setDriverIndex((prevIdx) => {
      const nextIdx = (prevIdx + 1) % candidatePool.length;
      const prevDriverName = candidatePool[prevIdx % candidatePool.length].name;
      const nextDriverName = candidatePool[nextIdx].name;

      if (reason === 'timeout') {
        setRotationNotice(`2-minute response window expired for ${prevDriverName}. Now dispatching reservation to ${nextDriverName}…`);
      } else {
        setRotationNotice(`${prevDriverName} is currently unavailable. Dispatched to ${nextDriverName}…`);
      }

      setDriverSecondsLeft(120); // Reset 2-minute timer for next driver
      return nextIdx;
    });
  }, [candidatePool]);

  // Handle Driver Acceptance (triggered by Flutter mobile app via Realtime or simulation)
  const handleDriverAcceptance = useCallback((acceptedChauffeur?: AssignedChauffeur) => {
    if (timerRef.current) clearInterval(timerRef.current);
    const chosen = acceptedChauffeur || currentCandidate;
    setConfirmedDriver(chosen);
    setDispatchStatus('accepted');
    setRotationNotice(null);
  }, [currentCandidate]);

  // Initialize ride request and Supabase Realtime channel
  useEffect(() => {
    const generatedReqId = `REQ-${Date.now().toString(36).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
    setRequestId(generatedReqId);

    // Record pending request in ride_requests table if schema permits
    const pushRideRequest = async () => {
      try {
        await supabase.from('ride_requests').insert({
          pickup_address: bookingForm.pickup,
          dropoff_address: bookingForm.dropoff,
          fare_amount: fare.total,
          type: 'instant',
          vehicle_type: bookingForm.vehicle,
          status: 'pending',
          target_driver_id: currentCandidate.id,
          dispatched_at: new Date().toISOString(),
          dispatch_expires_at: new Date(Date.now() + 120 * 1000).toISOString(),
          expires_at: new Date(Date.now() + 1800 * 1000).toISOString(),
        });
      } catch {
        // Best-effort database insert
      }
    };
    pushRideRequest();

    // Subscribe to Supabase Realtime changes for real driver acceptance from Flutter mobile app
    const channel = supabase
      .channel(`dispatch_${generatedReqId}`)
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'ride_requests' },
        (payload: any) => {
          if (payload.new?.status === 'accepted') {
            handleDriverAcceptance();
          } else if (payload.new?.status === 'declined') {
            advanceToNextChauffeur('declined');
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [bookingForm.pickup, bookingForm.dropoff, bookingForm.vehicle, fare.total, currentCandidate.id, advanceToNextChauffeur, handleDriverAcceptance]);

  // Countdown clock: 2-minute per-driver window & 30-minute global timeout
  useEffect(() => {
    if (dispatchStatus !== 'dispatching') {
      if (timerRef.current) clearInterval(timerRef.current);
      return;
    }

    timerRef.current = setInterval(() => {
      setGlobalSecondsLeft((prevGlobal) => {
        if (prevGlobal <= 1) {
          if (timerRef.current) clearInterval(timerRef.current);
          setDispatchStatus('timed_out_cancelled');
          return 0;
        }
        return prevGlobal - 1;
      });

      setDriverSecondsLeft((prevDriver) => {
        if (prevDriver <= 1) {
          // 2 minutes expired for this chauffeur! Rotate to next chauffeur with this car
          advanceToNextChauffeur('timeout');
          return 120;
        }
        return prevDriver - 1;
      });
    }, 1000);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [dispatchStatus, advanceToNextChauffeur]);

  // Format MM:SS helper
  const formatTime = (totalSeconds: number) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // 2-minute progress percentage (120s down to 0)
  const driverTimeProgress = Math.max(0, Math.min(100, ((120 - driverSecondsLeft) / 120) * 100));

  return (
    <div>
      <button onClick={onBack} className="booking-btn-back">
        <ArrowLeft size={15} /> Back to Tariff Review
      </button>

      {/* ── Header ── */}
      <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginBottom: 4 }}>
          <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--admin-primary, #F4C522)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Live Chauffeur Dispatch System
          </span>
          {requestId && (
            <span style={{ fontFamily: 'monospace', fontSize: '0.68rem', color: '#71717a', background: 'rgba(255,255,255,0.05)', padding: '1px 6px', borderRadius: '4px' }}>
              {requestId}
            </span>
          )}
        </div>
        <h2 style={{ margin: 0, fontSize: '1.65rem', fontWeight: 800, color: '#ffffff', letterSpacing: '-0.02em' }}>
          {dispatchStatus === 'dispatching' && `Contacting ${bookingForm.vehicle} Chauffeur…`}
          {dispatchStatus === 'accepted' && 'Chauffeur Confirmed'}
          {dispatchStatus === 'timed_out_cancelled' && 'Dispatch Expired (30 Min)'}
        </h2>
        <p style={{ margin: '4px 0 0', fontSize: '0.82rem', color: '#a1a1aa' }}>
          {dispatchStatus === 'dispatching' && `Connecting 1-on-1 with verified chauffeurs equipped with ${bookingForm.vehicle}`}
          {dispatchStatus === 'accepted' && 'Your assigned executive chauffeur is reserved and preparing for departure'}
          {dispatchStatus === 'timed_out_cancelled' && 'No chauffeur accepted this booking within the 30-minute window'}
        </p>
      </div>


      {/* ── Live Rotation Alert Banner ── */}
      {rotationNotice && dispatchStatus === 'dispatching' && (
        <div style={{
          background: 'rgba(244, 197, 34, 0.08)',
          border: '1px solid rgba(244, 197, 34, 0.25)',
          borderRadius: '12px',
          padding: '10px 14px',
          marginBottom: '16px',
          fontSize: '0.78rem',
          color: '#F4C522',
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          animation: 'fadeIn 0.3s ease-out',
        }}>
          <RefreshCw size={14} className="admin-spin" style={{ flexShrink: 0 }} />
          <span>{rotationNotice}</span>
        </div>
      )}

      {/* ── STATE 1: DISPATCHING (Active 2-Min Chauffeur Window) ── */}
      {dispatchStatus === 'dispatching' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '20px' }}>
          {/* Radar Dispatching Card */}
          <div style={{
            background: '#141418',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            borderRadius: '16px',
            padding: '24px 20px',
            textAlign: 'center',
            position: 'relative',
            overflow: 'hidden',
          }}>
            {/* Radar Animation */}
            <div style={{ position: 'relative', width: '68px', height: '68px', margin: '0 auto 14px' }}>
              <div style={{
                position: 'absolute',
                inset: 0,
                borderRadius: '50%',
                background: 'rgba(244, 197, 34, 0.15)',
                border: '2px solid rgba(244, 197, 34, 0.35)',
                animation: 'ping 1.6s cubic-bezier(0, 0, 0.2, 1) infinite',
              }} />
              <div style={{
                position: 'relative',
                width: '100%',
                height: '100%',
                borderRadius: '50%',
                background: '#1a1a20',
                border: '2px solid #F4C522',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#F4C522',
              }}>
                <Car size={30} />
              </div>
            </div>

            <div style={{ fontSize: '1rem', fontWeight: 800, color: '#ffffff', marginBottom: 4 }}>
              Contacting Chauffeur {(driverIndex % totalAvailable) + 1} of {totalAvailable}
            </div>
            <div style={{ fontSize: '0.8rem', color: '#a1a1aa', marginBottom: '16px' }}>
              Waiting for driver confirmation in mobile app…
            </div>

            {/* Current Candidate Target Preview */}
            <div style={{
              background: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid rgba(255, 255, 255, 0.07)',
              borderRadius: '12px',
              padding: '12px 14px',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              textAlign: 'left',
              marginBottom: '16px',
            }}>
              <img
                src={currentCandidate.avatarUrl}
                alt={currentCandidate.name}
                style={{ width: '44px', height: '44px', borderRadius: '50%', objectFit: 'cover', border: '1.5px solid #F4C522' }}
              />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: 700, color: '#ffffff', fontSize: '0.9rem' }}>
                    {currentCandidate.name}
                  </span>
                  <span style={{ fontSize: '0.74rem', color: '#F4C522', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 3 }}>
                    <Star size={11} fill="#F4C522" /> {currentCandidate.rating.toFixed(2)}
                  </span>
                </div>
                <div style={{ fontSize: '0.74rem', color: '#a1a1aa', marginTop: 2 }}>
                  {currentCandidate.vehicleName} · <span style={{ fontFamily: 'monospace', color: '#ffffff' }}>{currentCandidate.licensePlate}</span>
                </div>
              </div>
            </div>

            {/* 2-Minute Response Countdown */}
            <div style={{ marginBottom: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.76rem', color: '#a1a1aa', marginBottom: 6 }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                  <Clock size={12} style={{ color: '#F4C522' }} /> Chauffeur Response Window
                </span>
                <span style={{ fontFamily: 'monospace', fontWeight: 700, color: driverSecondsLeft < 30 ? '#ef4444' : '#F4C522', fontSize: '0.85rem' }}>
                  {formatTime(driverSecondsLeft)} remaining
                </span>
              </div>
              <div style={{ width: '100%', height: '6px', background: 'rgba(255, 255, 255, 0.08)', borderRadius: '999px', overflow: 'hidden' }}>
                <div style={{
                  height: '100%',
                  width: `${driverTimeProgress}%`,
                  background: driverSecondsLeft < 30 ? '#ef4444' : 'linear-gradient(90deg, #F4C522, #fbbf24)',
                  transition: 'width 1s linear',
                }} />
              </div>
            </div>

            {/* 30-Minute Global Search Timer */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: 10, borderTop: '1px solid rgba(255, 255, 255, 0.06)', fontSize: '0.74rem', color: '#71717a' }}>
              <span>Total Search Window (30 min auto-cancel):</span>
              <span style={{ fontFamily: 'monospace', color: '#e4e4e7' }}>{formatTime(globalSecondsLeft)}</span>
            </div>
          </div>

          {/* Standards & Dispatch Protocol Note */}
          <div style={{
            background: 'rgba(255, 255, 255, 0.02)',
            border: '1px solid rgba(255, 255, 255, 0.06)',
            borderRadius: '12px',
            padding: '12px 14px',
            fontSize: '0.76rem',
            color: '#a1a1aa',
            lineHeight: 1.45,
          }}>
            <strong style={{ color: '#ffffff' }}>Chauffeur Assignment Protocol:</strong> If this chauffeur does not accept within 2 minutes, your reservation is instantly routed to the next verified chauffeur equipped with {bookingForm.vehicle}.
          </div>

          {/* ── Interactive Simulation / Test Control (Only for Testing & Verification) ── */}
          <div style={{
            background: 'rgba(99, 91, 255, 0.06)',
            border: '1px dashed rgba(99, 91, 255, 0.3)',
            borderRadius: '12px',
            padding: '12px 14px',
          }}>
            <div style={{ fontSize: '0.7rem', fontWeight: 700, color: '#818cf8', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: 8, display: 'flex', alignItems: 'center', gap: 6 }}>
              <span>Chauffeur Response Simulator</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
              <button
                type="button"
                onClick={() => handleDriverAcceptance()}
                className="booking-btn-primary"
                style={{ height: '36px', fontSize: '0.78rem', background: '#10b981', color: '#ffffff' }}
              >
                <CheckCircle2 size={13} /> Driver Accepts
              </button>
              <button
                type="button"
                onClick={() => advanceToNextChauffeur('declined')}
                className="booking-btn-secondary"
                style={{ height: '36px', fontSize: '0.78rem' }}
              >
                <XCircle size={13} /> Driver Declines
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── STATE 2: ACCEPTED (Chauffeur Confirmed) ── */}
      {dispatchStatus === 'accepted' && confirmedDriver && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', marginBottom: '22px' }}>
          {/* Confirmed Chauffeur Card */}
          <div style={{
            background: '#16161b',
            border: '1.5px solid rgba(244, 197, 34, 0.4)',
            borderRadius: '16px',
            padding: '20px',
            boxShadow: '0 10px 30px rgba(0, 0, 0, 0.5), 0 0 20px rgba(244, 197, 34, 0.08)',
          }}>
            {/* Accepted Banner */}
            <div style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 6,
              background: 'rgba(16, 185, 129, 0.12)',
              color: '#10b981',
              border: '1px solid rgba(16, 185, 129, 0.3)',
              borderRadius: '999px',
              padding: '3px 10px',
              fontSize: '0.72rem',
              fontWeight: 700,
              marginBottom: '14px',
            }}>
              <UserCheck size={13} />
              <span>Chauffeur Accepted & Locked In</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              {/* Avatar */}
              <div style={{ position: 'relative' }}>
                <img
                  src={confirmedDriver.avatarUrl}
                  alt={confirmedDriver.name}
                  style={{
                    width: '64px',
                    height: '64px',
                    borderRadius: '50%',
                    objectFit: 'cover',
                    border: '2px solid #F4C522',
                    boxShadow: '0 0 12px rgba(244, 197, 34, 0.3)',
                  }}
                />
                <span
                  title="Online Confirmed"
                  style={{
                    position: 'absolute',
                    bottom: 2,
                    right: 2,
                    width: '14px',
                    height: '14px',
                    borderRadius: '50%',
                    background: '#10b981',
                    border: '2.5px solid #16161b',
                  }}
                />
              </div>

              {/* Chauffeur Credentials */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: '1.2rem', fontWeight: 800, color: '#ffffff' }}>
                  {confirmedDriver.name}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 4 }}>
                  <span style={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 3,
                    background: 'rgba(244, 197, 34, 0.1)',
                    color: '#F4C522',
                    padding: '2px 7px',
                    borderRadius: '6px',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                  }}>
                    <Star size={11} fill="#F4C522" />
                    {confirmedDriver.rating.toFixed(2)}
                  </span>
                  <span style={{ fontSize: '0.78rem', color: '#a1a1aa' }}>
                    {confirmedDriver.tripsCount}+ Verified Trips
                  </span>
                </div>
                <div style={{ fontSize: '0.74rem', color: '#71717a', marginTop: 4 }}>
                  {confirmedDriver.yearsExperience}+ Years Executive Service
                </div>
              </div>
            </div>

            {/* Vehicle & Plate Specs */}
            <div style={{
              marginTop: '16px',
              paddingTop: '14px',
              borderTop: '1px solid rgba(255, 255, 255, 0.08)',
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: '10px',
            }}>
              <div>
                <span style={{ fontSize: '0.68rem', color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block' }}>
                  Assigned Vehicle
                </span>
                <span style={{ fontSize: '0.84rem', fontWeight: 700, color: '#ffffff' }}>
                  {confirmedDriver.vehicleName}
                </span>
                <span style={{ fontSize: '0.72rem', color: '#a1a1aa', display: 'block' }}>
                  {confirmedDriver.color}
                </span>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontSize: '0.68rem', color: '#71717a', textTransform: 'uppercase', letterSpacing: '0.05em', display: 'block' }}>
                  License Plate
                </span>
                <span style={{
                  display: 'inline-block',
                  background: '#09090b',
                  border: '1.5px solid rgba(244, 197, 34, 0.4)',
                  color: '#F4C522',
                  padding: '3px 8px',
                  borderRadius: '6px',
                  fontFamily: 'monospace',
                  fontWeight: 800,
                  fontSize: '0.86rem',
                  letterSpacing: '0.05em',
                  marginTop: 2,
                }}>
                  {confirmedDriver.licensePlate}
                </span>
              </div>
            </div>
          </div>

          {/* Protocol Guarantee */}
          <div style={{
            background: 'rgba(255, 255, 255, 0.03)',
            border: '1px solid rgba(255, 255, 255, 0.08)',
            borderRadius: '12px',
            padding: '12px 16px',
            fontSize: '0.78rem',
            color: '#a1a1aa',
            display: 'flex',
            flexDirection: 'column',
            gap: 6,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#ffffff', fontWeight: 600 }}>
              <CheckCircle2 size={13} style={{ color: '#10b981' }} />
              Chauffeur Standards Guaranteed
            </div>
            <div>• Arrives 10 minutes prior to scheduled pickup time with personalized name board.</div>
            <div>• Real-time GPS flight tracking & complimentary 45-minute airport wait time included.</div>
          </div>

          {/* Confirm & Proceed Button */}
          <button
            onClick={() => onConfirmChauffeur(confirmedDriver)}
            className="booking-btn-primary"
            style={{ height: '52px', fontSize: '1rem' }}
          >
            <span>Confirm Chauffeur & Pay · ${fare.total.toFixed(2)}</span>
            <ArrowRight size={18} />
          </button>
        </div>
      )}

      {/* ── STATE 3: TIMED OUT (30 Minutes Expired Without Acceptance) ── */}
      {dispatchStatus === 'timed_out_cancelled' && (
        <div style={{
          background: 'rgba(239, 68, 68, 0.06)',
          border: '1px solid rgba(239, 68, 68, 0.3)',
          borderRadius: '16px',
          padding: '28px 20px',
          textAlign: 'center',
          marginBottom: '20px',
        }}>
          <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: 'rgba(239, 68, 68, 0.12)', border: '1.5px solid rgba(239, 68, 68, 0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
            <AlertTriangle size={30} color="#ef4444" />
          </div>
          <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#ffffff', margin: '0 0 6px' }}>
            Ride Search Expired
          </h3>
          <p style={{ fontSize: '0.82rem', color: '#a1a1aa', margin: '0 0 20px', lineHeight: 1.5 }}>
            No verified active chauffeurs with <strong style={{ color: '#ffffff' }}>{bookingForm.vehicle}</strong> accepted this itinerary within the 30-minute window.
          </p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <button
              onClick={() => {
                setGlobalSecondsLeft(1800);
                setDriverSecondsLeft(120);
                setDispatchStatus('dispatching');
              }}
              className="booking-btn-primary"
              style={{ height: '46px', fontSize: '0.9rem' }}
            >
              <RefreshCw size={16} /> Retry Chauffeur Dispatch
            </button>
            <button
              onClick={onBack}
              className="booking-btn-secondary"
              style={{ height: '44px', fontSize: '0.88rem' }}
            >
              Choose Another Vehicle Tier
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
