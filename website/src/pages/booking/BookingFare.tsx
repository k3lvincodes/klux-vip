import { ArrowLeft, DollarSign } from 'lucide-react';
import type { FareBreakdown } from './types';
import { inputStyle, labelStyle, primaryBtnStyle } from './styles';

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
    <>
      <button onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: '6px', background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', fontSize: '0.9rem', marginBottom: '20px', padding: 0, fontFamily: 'inherit' }}>
        <ArrowLeft size={16} /> Back
      </button>

      <h2 style={{ textAlign: 'center', marginBottom: '1.5rem', fontSize: '1.5rem', fontWeight: 700, color: '#000' }}>
        Fare Breakdown
      </h2>

      <div style={{ background: '#f9fafb', borderRadius: '14px', padding: '20px', marginBottom: '24px', border: '1px solid #e5e7eb' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
          <span style={{ color: '#64748b', fontSize: '0.95rem' }}>Base Fare</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.baseFare.toFixed(2)}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
          <span style={{ color: '#64748b', fontSize: '0.95rem' }}>Trip Fare</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.tripFare.toFixed(2)}</span>
        </div>
        <div style={{ borderTop: '1px solid #e5e7eb', paddingTop: '12px', marginBottom: '4px', display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ fontWeight: 600, color: '#000' }}>Subtotal</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.subtotal.toFixed(2)}</span>
        </div>
      </div>

      <div style={{ marginBottom: '24px' }}>
        <h3 style={{ fontSize: '1rem', fontWeight: 700, color: '#000', marginBottom: '14px' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: '6px' }}><DollarSign size={16} /> Add a Tip</span>
        </h3>

        <div style={{ display: 'flex', gap: '10px', marginBottom: '14px' }}>
          {[20, 25, 30].map(pct => (
            <button
              key={pct}
              onClick={() => onTipPercentChange(pct)}
              style={{
                flex: 1,
                padding: '12px 8px',
                borderRadius: '10px',
                border: tipMode === 'percent' && tipPercent === pct ? '2px solid #F4C522' : '1.5px solid #d1d5db',
                background: tipMode === 'percent' && tipPercent === pct ? '#fef9e3' : '#fff',
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: '0.9rem',
                color: '#000',
                fontFamily: 'inherit',
                transition: 'all 0.2s',
                textAlign: 'center',
              }}
            >
              {pct}%<br /><span style={{ fontSize: '0.78rem', color: '#64748b', fontWeight: 400 }}>${(fare.subtotal * pct / 100).toFixed(2)}</span>
            </button>
          ))}
        </div>

        <div style={{ marginBottom: '14px' }}>
          <label style={labelStyle}>Custom Tip</label>
          <div style={{ position: 'relative' }}>
            <span style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: '#9ca3af', fontWeight: 600 }}>$</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={customTip}
              onChange={e => onCustomTipChange(e.target.value)}
              placeholder="0.00"
              style={{ ...inputStyle, paddingLeft: '30px' }}
              onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
              onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
            />
          </div>
        </div>

        <button
          onClick={() => onTipModeChange('none')}
          style={{
            width: '100%',
            padding: '10px',
            borderRadius: '10px',
            border: tipMode === 'none' ? '2px solid #F4C522' : '1.5px solid #d1d5db',
            background: tipMode === 'none' ? '#fef9e3' : '#fff',
            cursor: 'pointer',
            fontWeight: 500,
            fontSize: '0.88rem',
            color: '#64748b',
            fontFamily: 'inherit',
            transition: 'all 0.2s',
          }}
        >
          No Tip
        </button>
      </div>

      <div style={{ background: '#000', borderRadius: '14px', padding: '18px 20px', marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ color: '#fff', fontWeight: 600, fontSize: '1rem' }}>Total</span>
        <span style={{ color: '#F4C522', fontWeight: 700, fontSize: '1.3rem' }}>${fare.total.toFixed(2)}</span>
      </div>

      <button
        onClick={onContinue}
        style={primaryBtnStyle}
        onMouseEnter={e => e.currentTarget.style.background = '#DCA70B'}
        onMouseLeave={e => e.currentTarget.style.background = '#F4C522'}
      >
        Continue to Payment
      </button>
    </>
  );
}
