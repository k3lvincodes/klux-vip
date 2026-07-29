import { useTranslation } from 'react-i18next';
import { CheckCircle2, MapPin } from 'lucide-react';
import type { BookingConfirmation as ConfirmationType } from './types';
import { secondaryBtnStyle } from './styles';

interface Props {
  confirmation: ConfirmationType;
  onReset: () => void;
}

export default function BookingConfirmation({ confirmation, onReset }: Props) {
  const { t } = useTranslation();

  return (
    <div style={{ textAlign: 'center' }}>
      <div style={{ width: '72px', height: '72px', borderRadius: '50%', background: '#f0fdf4', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px' }}>
        <CheckCircle2 size={48} color="#10b981" />
      </div>

      <h2 style={{ fontSize: '1.5rem', fontWeight: 700, color: '#000', marginBottom: '6px' }}>Booking Confirmed!</h2>
      <p style={{ color: '#64748b', fontSize: '0.9rem', marginBottom: '24px' }}>Your ride has been booked successfully.</p>

      <div style={{ background: '#f9fafb', borderRadius: '14px', padding: '20px', border: '1px solid #e5e7eb', textAlign: 'left', marginBottom: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
          <span style={{ color: '#64748b', fontSize: '0.85rem' }}>Invoice</span>
          <span style={{ fontWeight: 600, color: '#000', fontSize: '0.88rem' }}>{confirmation.invoiceNumber}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
          <span style={{ color: '#64748b', fontSize: '0.85rem' }}>Confirmation #</span>
          <span style={{ fontWeight: 600, color: '#F4C522', fontSize: '0.88rem' }}>{confirmation.confirmationNumber}</span>
        </div>

        <div style={{ borderTop: '1px solid #e5e7eb', paddingTop: '14px', marginBottom: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
            <MapPin size={14} color="#F4C522" />
            <span style={{ fontWeight: 600, color: '#000', fontSize: '0.9rem' }}>{confirmation.pickup} → {confirmation.dropoff}</span>
          </div>
          <div style={{ display: 'flex', gap: '16px', paddingLeft: '22px' }}>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>{confirmation.date}</span>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>{confirmation.time}</span>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>{confirmation.vehicle}</span>
          </div>
        </div>

        <div style={{ borderTop: '1px solid #e5e7eb', paddingTop: '14px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>Base Fare</span>
            <span style={{ fontWeight: 500, color: '#000', fontSize: '0.88rem' }}>${confirmation.baseFare.toFixed(2)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>Tip</span>
            <span style={{ fontWeight: 500, color: '#000', fontSize: '0.88rem' }}>${confirmation.tip.toFixed(2)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '6px' }}>
            <span style={{ color: '#64748b', fontSize: '0.85rem' }}>Tax</span>
            <span style={{ fontWeight: 500, color: '#000', fontSize: '0.88rem' }}>${confirmation.tax.toFixed(2)}</span>
          </div>
          <div style={{ borderTop: '1px solid #e5e7eb', marginTop: '8px', paddingTop: '8px', display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontWeight: 700, color: '#000' }}>Total</span>
            <span style={{ fontWeight: 700, color: '#F4C522', fontSize: '1.1rem' }}>${confirmation.total.toFixed(2)}</span>
          </div>
        </div>

        <div style={{ marginTop: '14px', textAlign: 'center' }}>
          <span style={{ display: 'inline-block', background: '#f0fdf4', color: '#10b981', fontWeight: 600, fontSize: '0.8rem', padding: '4px 14px', borderRadius: '999px', border: '1px solid #bbf7d0' }}>
            PAID
          </span>
        </div>
      </div>

      <button onClick={onReset} style={secondaryBtnStyle}>
        {t('booking.book_another_ride')}
      </button>
    </div>
  );
}
