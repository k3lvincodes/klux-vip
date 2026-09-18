import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CheckCircle2, MapPin, Copy, Check, Printer, Calendar, Car } from 'lucide-react';
import type { BookingConfirmation as ConfirmationType } from './types';

interface Props {
  confirmation: ConfirmationType;
  onReset: () => void;
}

export default function BookingConfirmation({ confirmation, onReset }: Props) {
  const { t } = useTranslation();
  const [copied, setCopied] = useState(false);



  const copyCode = () => {
    navigator.clipboard.writeText(confirmation.confirmationNumber);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div style={{ textAlign: 'center' }}>
      {/* ── Success Icon ── */}
      <div style={{ width: '64px', height: '64px', borderRadius: '50%', background: 'rgba(16, 185, 129, 0.12)', border: '1.5px solid rgba(16, 185, 129, 0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
        <CheckCircle2 size={36} color="#10b981" />
      </div>

      <span style={{ fontSize: '0.72rem', fontWeight: 700, color: '#10b981', textTransform: 'uppercase', letterSpacing: '0.08em', display: 'block', marginBottom: 4 }}>
        Itinerary Confirmed
      </span>
      <h2 style={{ fontSize: '1.65rem', fontWeight: 800, color: '#ffffff', letterSpacing: '-0.02em', margin: '0 0 6px' }}>
        Reservation Confirmed
      </h2>
      <p style={{ color: '#a1a1aa', fontSize: '0.82rem', margin: '0 0 22px' }}>
        A complete digital itinerary has been dispatched to your email and mobile phone.
      </p>

      {/* ── Executive Boarding Pass Voucher ── */}
      <div className="booking-voucher-card">
        <div className="booking-voucher-header">
          <div>
            <span style={{ fontSize: '0.68rem', textTransform: 'uppercase', letterSpacing: '0.05em', color: '#71717a', display: 'block' }}>
              Invoice Reference
            </span>
            <span style={{ fontWeight: 600, color: '#ffffff', fontSize: '0.84rem' }}>
              {confirmation.invoiceNumber}
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ fontSize: '0.68rem', fontWeight: 700, background: 'rgba(16, 185, 129, 0.15)', color: '#10b981', border: '1px solid rgba(16, 185, 129, 0.3)', padding: '2px 8px', borderRadius: '999px', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
              PAID & DISPATCHED
            </span>
          </div>
        </div>

        <div className="booking-voucher-body">
          {/* Confirmation Code Pill */}
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', background: '#141418', padding: '10px 14px', borderRadius: '10px', border: '1px solid rgba(255, 255, 255, 0.06)' }}>
            <span style={{ fontSize: '0.75rem', color: '#a1a1aa', textTransform: 'uppercase', letterSpacing: '0.05em', fontWeight: 600 }}>
              Confirmation Code
            </span>
            <button
              onClick={copyCode}
              className="booking-voucher-code"
              title="Click to copy confirmation code"
              style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
            >
              <span>{confirmation.confirmationNumber}</span>
              {copied ? <Check size={13} color="#10b981" /> : <Copy size={13} />}
            </button>
          </div>

          {/* Route Overview */}
          <div className="booking-voucher-route">
            <div className="booking-voucher-route-row">
              <MapPin size={14} color="#10b981" style={{ flexShrink: 0 }} />
              <div style={{ fontSize: '0.84rem', color: '#e4e4e7', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                <strong style={{ color: '#71717a', fontSize: '0.74rem', display: 'block', textTransform: 'uppercase' }}>Pickup Origin</strong>
                {confirmation.pickup}
              </div>
            </div>

            <div className="booking-voucher-route-row">
              <MapPin size={14} color="#F4C522" style={{ flexShrink: 0 }} />
              <div style={{ fontSize: '0.84rem', color: '#e4e4e7', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                <strong style={{ color: '#71717a', fontSize: '0.74rem', display: 'block', textTransform: 'uppercase' }}>Destination</strong>
                {confirmation.dropoff}
              </div>
            </div>
          </div>

          {/* Schedule & Vehicle Specs */}
          <div className="booking-voucher-specs">
            <div className="booking-voucher-spec-item">
              <span><Calendar size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: -1 }} /> Date & Time</span>
              <strong>{confirmation.date} · {confirmation.time}</strong>
            </div>
            <div className="booking-voucher-spec-item">
              <span><Car size={12} style={{ display: 'inline', marginRight: 4, verticalAlign: -1 }} /> Vehicle Tier</span>
              <strong>{confirmation.vehicle}</strong>
            </div>
          </div>

          {/* Chauffeur Details or Protocol Notice */}
          {confirmation.chauffeur ? (
            <div style={{
              background: 'linear-gradient(135deg, rgba(20,20,24,0.95), rgba(28,28,34,0.95))',
              border: '1px solid rgba(244, 197, 34, 0.3)',
              borderRadius: '12px',
              padding: '12px 14px',
              marginBottom: '16px',
              textAlign: 'left',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
            }}>
              {confirmation.chauffeur.avatarUrl ? (
                <img
                  src={confirmation.chauffeur.avatarUrl}
                  alt={confirmation.chauffeur.name}
                  style={{ width: '44px', height: '44px', borderRadius: '50%', objectFit: 'cover', border: '2px solid #F4C522', flexShrink: 0 }}
                />
              ) : (
                <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: '#F4C522', color: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 800, fontSize: '1rem', flexShrink: 0 }}>
                  {confirmation.chauffeur.name.charAt(0)}
                </div>
              )}

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 2 }}>
                  <span style={{ fontSize: '0.66rem', fontWeight: 700, color: '#10b981', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
                    Confirmed Chauffeur
                  </span>
                  <span style={{ background: 'rgba(244,197,34,0.12)', border: '1px solid rgba(244,197,34,0.3)', color: '#F4C522', padding: '1px 6px', borderRadius: '4px', fontFamily: 'monospace', fontSize: '0.7rem', fontWeight: 700 }}>
                    {confirmation.chauffeur.licensePlate}
                  </span>
                </div>
                <div style={{ fontWeight: 700, color: '#ffffff', fontSize: '0.9rem', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {confirmation.chauffeur.name}
                </div>
                <div style={{ fontSize: '0.74rem', color: '#a1a1aa', display: 'flex', alignItems: 'center', gap: 6, marginTop: 2 }}>
                  <span>{confirmation.chauffeur.vehicleName}</span>
                  <span>·</span>
                  <span style={{ color: '#F4C522', fontWeight: 600 }}>★ {confirmation.chauffeur.rating.toFixed(2)}</span>
                  <span>·</span>
                  <a href={`tel:${confirmation.chauffeur.phone}`} style={{ color: '#F4C522', textDecoration: 'none', fontWeight: 600 }}>
                    {confirmation.chauffeur.phone}
                  </a>
                </div>
              </div>
            </div>
          ) : (
            <div style={{ background: 'rgba(244, 197, 34, 0.06)', border: '1px solid rgba(244, 197, 34, 0.18)', borderRadius: '10px', padding: '10px 12px', fontSize: '0.76rem', color: '#a1a1aa', lineHeight: 1.45, marginBottom: '16px', textAlign: 'left' }}>
              <strong style={{ color: '#ffffff' }}>Chauffeur Assignment Notice:</strong> Your dedicated executive chauffeur and luxury vehicle credentials will be assigned 2 hours prior to scheduled departure with real-time GPS tracking.
            </div>
          )}


          {/* Receipt Breakdown */}
          <div style={{ borderTop: '1px solid rgba(255, 255, 255, 0.08)', paddingTop: '12px', fontSize: '0.82rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', color: '#a1a1aa', marginBottom: '6px' }}>
              <span>Base Chauffeur Tariff</span>
              <span style={{ color: '#ffffff' }}>${confirmation.baseFare.toFixed(2)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', color: '#a1a1aa', marginBottom: '6px' }}>
              <span>Chauffeur Gratuity</span>
              <span style={{ color: '#ffffff' }}>${confirmation.tip.toFixed(2)}</span>
            </div>
            <div style={{ borderTop: '1px solid rgba(255, 255, 255, 0.08)', marginTop: '8px', paddingTop: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 700, color: '#ffffff' }}>Total Paid</span>
              <span style={{ fontWeight: 800, color: '#F4C522', fontSize: '1.25rem' }}>${confirmation.total.toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div style={{ display: 'flex', gap: '10px' }}>
        <button
          onClick={handlePrint}
          className="booking-btn-secondary"
          style={{ flex: 1 }}
        >
          <Printer size={15} /> Print Itinerary
        </button>

        <button
          onClick={onReset}
          className="booking-btn-primary"
          style={{ flex: 1 }}
        >
          {t('booking.book_another_ride')}
        </button>
      </div>
    </div>
  );
}

