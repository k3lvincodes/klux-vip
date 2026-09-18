import { ArrowLeft, DollarSign, Sparkles, ShieldCheck, ArrowRight, Check } from 'lucide-react';
import type { FareBreakdown } from './types';

interface Props {
  fare: FareBreakdown;
  tipMode: 'percent' | 'custom' | 'none';
  tipPercent: number | null;
  customTip: string;
  onTipModeChange: (mode: 'percent' | 'custom' | 'none') => void;
  onTipPercentChange: (pct: number) => void;
  onCustomTipChange: (val: string) => void;
  onBack: () => void;
  onContinue: () => void;
}

export default function BookingFare({
  fare,
  tipMode,
  tipPercent,
  customTip,
  onTipModeChange,
  onTipPercentChange,
  onCustomTipChange,
  onBack,
  onContinue,
}: Props) {
  return (
    <div>
      <button onClick={onBack} className="booking-btn-back">
        <ArrowLeft size={15} /> Back to Trip Details
      </button>

      <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
        <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--admin-primary, #F4C522)', textTransform: 'uppercase', letterSpacing: '0.08em', display: 'block', marginBottom: 4 }}>
          Guaranteed Executive Quote
        </span>
        <h2 style={{ margin: 0, fontSize: '1.65rem', fontWeight: 800, color: '#ffffff', letterSpacing: '-0.02em' }}>
          Tariff & Gratuity
        </h2>
        <p style={{ margin: '4px 0 0', fontSize: '0.82rem', color: '#a1a1aa' }}>
          All tolls, airport fees, and chauffeur dispatch included
        </p>
      </div>

      {/* ── Fare Breakdown Card ── */}
      <div className="booking-fare-card">
        <div className="booking-fare-row">
          <span>Base Chauffeur Dispatch</span>
          <span className="booking-fare-val">${fare.baseFare.toFixed(2)}</span>
        </div>
        <div className="booking-fare-row">
          <span>Mileage & Service Tariff</span>
          <span className="booking-fare-val">${fare.tripFare.toFixed(2)}</span>
        </div>
        <div className="booking-fare-row">
          <span>Chauffeur Gratuity</span>
          <span className="booking-fare-val" style={{ color: fare.tip > 0 ? '#F4C522' : '#a1a1aa' }}>
            ${fare.tip.toFixed(2)}
          </span>
        </div>
        <div className="booking-fare-row subtotal">
          <span>Subtotal</span>
          <span className="booking-fare-val" style={{ color: '#ffffff', fontSize: '1rem' }}>
            ${(fare.subtotal + fare.tip).toFixed(2)}
          </span>
        </div>
      </div>

      {/* ── Tip Selector ── */}
      <div style={{ marginBottom: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
          <label className="booking-label" style={{ margin: 0 }}>
            <DollarSign size={14} /> Chauffeur Gratuity
          </label>
          <span style={{ fontSize: '0.72rem', color: '#71717a' }}>Directly awarded to your chauffeur</span>
        </div>

        <div className="booking-tip-grid">
          {[
            { pct: 18, label: 'Standard' },
            { pct: 20, label: 'Recommended' },
            { pct: 25, label: 'Exceptional' },
          ].map(({ pct, label }) => {
            const isActive = tipMode === 'percent' && tipPercent === pct;
            return (
              <button
                key={pct}
                type="button"
                onClick={() => onTipPercentChange(pct)}
                className={`booking-tip-btn ${isActive ? 'active' : ''}`}
              >
                <span className="booking-tip-pct">{pct}%</span>
                <span className="booking-tip-amt">${(fare.subtotal * pct / 100).toFixed(2)}</span>
                <span style={{ fontSize: '0.62rem', textTransform: 'uppercase', letterSpacing: '0.04em', display: 'block', marginTop: 2, opacity: 0.8 }}>
                  {label}
                </span>
              </button>
            );
          })}
        </div>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <div style={{ flex: 1, position: 'relative' }}>
            <span style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#71717a', fontWeight: 600, fontSize: '0.85rem' }}>
              $
            </span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={customTip}
              onChange={e => onCustomTipChange(e.target.value)}
              placeholder="Custom tip amount"
              className="booking-input"
              style={{ paddingLeft: '28px' }}
            />
          </div>

          <button
            type="button"
            onClick={() => onTipModeChange('none')}
            className={`booking-tip-btn ${tipMode === 'none' ? 'active' : ''}`}
            style={{ width: '100px', padding: '10px', fontSize: '0.82rem', fontWeight: 600 }}
          >
            No Tip
          </button>
        </div>
      </div>

      {/* ── Included Executive Amenities ── */}
      <div>
        <div style={{ fontSize: '0.72rem', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em', color: '#a1a1aa', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: 6 }}>
          <Sparkles size={12} style={{ color: '#F4C522' }} />
          Complimentary Executive Privileges Included
        </div>
        <div className="booking-amenities-strip">
          <span className="booking-amenity-pill"><Check size={11} /> Live Flight Monitoring</span>
          <span className="booking-amenity-pill"><Check size={11} /> 15-Min Free Wait Time</span>
          <span className="booking-amenity-pill"><Check size={11} /> Chilled Artisan Water</span>
          <span className="booking-amenity-pill"><Check size={11} /> Luggage Handling</span>
        </div>
      </div>

      {/* ── Total Highlight Box ── */}
      <div className="booking-total-box">
        <div>
          <span className="booking-total-label">Total Reservation Amount</span>
          <div style={{ fontSize: '0.74rem', color: '#71717a', marginTop: 2 }}>
            Guaranteed all-inclusive total
          </div>
        </div>
        <span className="booking-total-val">${fare.total.toFixed(2)}</span>
      </div>

      {/* ── Security Trust Notice ── */}
      <div className="booking-security-badge">
        <ShieldCheck size={14} />
        <span>Bank-grade 256-bit encrypted reservation checkout</span>
      </div>

      <button onClick={onContinue} className="booking-btn-primary">
        <span>Proceed to Secure Checkout</span>
        <ArrowRight size={18} />
      </button>
    </div>
  );
}

