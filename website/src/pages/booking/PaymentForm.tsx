import { useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { CardElement, useStripe, useElements } from '@stripe/react-stripe-js';
import { supabase } from '../../lib/supabase';
import type { FareBreakdown, BookingFormData, BookingConfirmation } from './types';
import { primaryBtnStyle } from './styles';

interface Props {
  fare: FareBreakdown;
  bookingForm: BookingFormData;
  onBack: () => void;
  onSuccess: (confirmation: BookingConfirmation) => void;
  onError: (msg: string) => void;
}

export default function PaymentForm({
  fare,
  bookingForm,
  onBack,
  onSuccess,
  onError,
}: Props) {
  const stripe = useStripe();
  const elements = useElements();
  const [processing, setProcessing] = useState(false);

  const handlePay = async () => {
    if (!stripe || !elements) return;
    const card = elements.getElement(CardElement);
    if (!card) return;
    setProcessing(true);
    onError('');

    try {
      const { data, error: fnError } = await supabase.functions.invoke('create-booking', {
        body: {
          pickup: bookingForm.pickup,
          dropoff: bookingForm.dropoff,
          date: bookingForm.date,
          time: bookingForm.time,
          vehicle: bookingForm.vehicle,
          passengers: parseInt(bookingForm.passengers),
          name: bookingForm.name,
          email: bookingForm.email,
          phone: bookingForm.phone,
          base_fare: fare.baseFare,
          trip_fare: fare.tripFare,
          tip: fare.tip,
          tax: 0,
          total: fare.total,
        },
      });

      if (fnError) throw new Error(fnError.message);

      const { client_secret } = data;

      const result = await stripe.confirmCardPayment(client_secret, {
        payment_method: {
          card,
          billing_details: {
            name: bookingForm.name,
            email: bookingForm.email,
            phone: bookingForm.phone,
          },
        },
      });

      if (result.error) {
        throw new Error(result.error.message);
      }

      if (result.paymentIntent?.status === 'succeeded') {
        const invoiceNum = `INV-${Date.now().toString(36).toUpperCase()}`;
        const confirmNum = `BK-${Date.now().toString(36).toUpperCase()}-${(crypto.getRandomValues(new Uint32Array(1))[0]).toString(36).substring(2, 6).toUpperCase()}`;
        onSuccess({
          invoiceNumber: invoiceNum,
          confirmationNumber: confirmNum,
          pickup: bookingForm.pickup,
          dropoff: bookingForm.dropoff,
          date: bookingForm.date,
          time: bookingForm.time,
          vehicle: bookingForm.vehicle,
          baseFare: fare.baseFare,
          tip: fare.tip,
          tax: 0,
          total: fare.total,
        });
      }
    } catch (err: unknown) {
      onError(err instanceof Error ? err.message : 'Payment failed. Please try again.');
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div>
      <button onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: '6px', background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', fontSize: '0.9rem', marginBottom: '20px', padding: 0, fontFamily: 'inherit' }}>
        <ArrowLeft size={16} /> Back
      </button>

      <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#000', marginBottom: '16px' }}>Order Summary</h3>
      <div style={{ background: '#f9fafb', borderRadius: '12px', padding: '16px', marginBottom: '20px', border: '1px solid #e5e7eb' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
          <span style={{ color: '#64748b', fontSize: '0.9rem' }}>Trip Fare</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.tripFare.toFixed(2)}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
          <span style={{ color: '#64748b', fontSize: '0.9rem' }}>Base Fare</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.baseFare.toFixed(2)}</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
          <span style={{ color: '#64748b', fontSize: '0.9rem' }}>Tip</span>
          <span style={{ fontWeight: 600, color: '#000' }}>${fare.tip.toFixed(2)}</span>
        </div>
        <div style={{ borderTop: '1px solid #e5e7eb', marginTop: '8px', paddingTop: '8px', display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ fontWeight: 700, color: '#000' }}>Total</span>
          <span style={{ fontWeight: 700, color: '#F4C522', fontSize: '1.1rem' }}>${fare.total.toFixed(2)}</span>
        </div>
      </div>

      <h3 style={{ fontSize: '1.1rem', fontWeight: 700, color: '#000', marginBottom: '12px' }}>Card Details</h3>
      <div style={{ border: '1.5px solid #d1d5db', borderRadius: '10px', padding: '14px', marginBottom: '24px', background: '#fff' }}>
        <CardElement options={{
          style: {
            base: { fontSize: '16px', color: '#000', '::placeholder': { color: '#9ca3af' } },
            invalid: { color: '#dc2626' },
          },
        }} />
      </div>

      <button
        onClick={handlePay}
        disabled={!stripe || processing}
        style={{
          ...primaryBtnStyle,
          opacity: processing || !stripe ? 0.7 : 1,
          cursor: processing || !stripe ? 'not-allowed' : 'pointer',
        }}
        onMouseEnter={e => { if (!processing && stripe) e.currentTarget.style.background = '#DCA70B'; }}
        onMouseLeave={e => { e.currentTarget.style.background = '#F4C522'; }}
      >
        {processing ? 'Processing...' : `Pay $${fare.total.toFixed(2)}`}
      </button>
    </div>
  );
}
