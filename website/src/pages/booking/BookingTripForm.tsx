import { useTranslation } from 'react-i18next';
import { MapPin, Calendar, Clock, Car, User, Mail, Phone } from 'lucide-react';
import type { BookingFormData } from './types';
import { inputStyle, labelStyle, primaryBtnStyle } from './styles';

interface Props {
  bookingForm: BookingFormData;
  onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  onSubmit: () => void;
  isCalculating: boolean;
}

export default function BookingTripForm({ bookingForm, onChange, onSubmit, isCalculating }: Props) {
  const { t } = useTranslation();

  return (
    <>
      <h2 style={{ textAlign: 'center', marginBottom: '1.75rem', fontSize: '1.75rem', fontWeight: 700, color: '#000' }}>
        {t('booking.title')}
      </h2>

      <div style={{ marginBottom: '20px' }}>
        <label htmlFor="booking-pickup" style={labelStyle}>
          <MapPin size={15} /> {t('booking.pickup_location')}
        </label>
        <input
          id="booking-pickup"
          type="text"
          name="pickup"
          value={bookingForm.pickup}
          onChange={onChange}
          placeholder={t('booking.pickup_placeholder')}
          required
          style={inputStyle}
          onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
          onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
        />
      </div>

      <div style={{ marginBottom: '20px' }}>
        <label htmlFor="booking-dropoff" style={labelStyle}>
          <MapPin size={15} /> {t('booking.dropoff_location')}
        </label>
        <input
          id="booking-dropoff"
          type="text"
          name="dropoff"
          value={bookingForm.dropoff}
          onChange={onChange}
          placeholder={t('booking.dropoff_placeholder')}
          required
          style={inputStyle}
          onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
          onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
        />
      </div>

      <div className="booking-form-row" style={{ marginBottom: '20px' }}>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-date" style={labelStyle}>
            <Calendar size={15} /> {t('booking.date')}
          </label>
          <input
            id="booking-date"
            type="date"
            name="date"
            value={bookingForm.date}
            onChange={onChange}
            required
            style={inputStyle}
          />
        </div>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-time" style={labelStyle}>
            <Clock size={15} /> {t('booking.time')}
          </label>
          <input
            id="booking-time"
            type="time"
            name="time"
            value={bookingForm.time}
            onChange={onChange}
            required
            style={inputStyle}
          />
        </div>
      </div>

      <div className="booking-form-row" style={{ marginBottom: '20px' }}>
        <div style={{ flex: 2 }}>
          <label htmlFor="booking-vehicle" style={labelStyle}>
            <Car size={15} /> {t('booking.vehicle_type')}
          </label>
          <select
            id="booking-vehicle"
            name="vehicle"
            value={bookingForm.vehicle}
            onChange={onChange}
            style={{ ...inputStyle, cursor: 'pointer' }}
          >
            <option value="GMC Yukon">{t('fleet.gmc_yukon')}</option>
            <option value="Cadillac Escalade">{t('fleet.cadillac_escalade')}</option>
            <option value="Ford Expedition">{t('fleet.ford_expedition')}</option>
            <option value="Standard SUV">{t('fleet.standard_suv')}</option>
          </select>
        </div>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-passengers" style={labelStyle}>
            {t('booking.passengers')}
          </label>
          <input
            id="booking-passengers"
            type="number"
            name="passengers"
            min="1"
            max="8"
            value={bookingForm.passengers}
            onChange={onChange}
            style={inputStyle}
          />
        </div>
      </div>

      <div style={{ marginBottom: '20px' }}>
        <label htmlFor="booking-name" style={labelStyle}>
          <User size={15} /> {t('booking.full_name')}
        </label>
        <input
          id="booking-name"
          type="text"
          name="name"
          value={bookingForm.name}
          onChange={onChange}
          placeholder={t('booking.name_placeholder')}
          required
          style={inputStyle}
          onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
          onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
        />
      </div>

      <div className="booking-form-row" style={{ marginBottom: '20px' }}>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-email" style={labelStyle}>
            <Mail size={15} /> {t('booking.email')}
          </label>
          <input
            id="booking-email"
            type="email"
            name="email"
            value={bookingForm.email}
            onChange={onChange}
            placeholder={t('booking.email_placeholder')}
            required
            style={inputStyle}
            onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
            onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
          />
        </div>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-phone" style={labelStyle}>
            <Phone size={15} /> {t('booking.phone')}
          </label>
          <input
            id="booking-phone"
            type="tel"
            name="phone"
            value={bookingForm.phone}
            onChange={onChange}
            placeholder={t('booking.phone_placeholder')}
            required
            style={inputStyle}
            onFocus={e => e.currentTarget.style.borderColor = '#F4C522'}
            onBlur={e => e.currentTarget.style.borderColor = '#d1d5db'}
          />
        </div>
      </div>

      <button
        onClick={onSubmit}
        disabled={isCalculating}
        style={{
          ...primaryBtnStyle,
          opacity: isCalculating ? 0.7 : 1,
          cursor: isCalculating ? 'not-allowed' : 'pointer',
        }}
        onMouseEnter={e => { if (!isCalculating) e.currentTarget.style.background = '#DCA70B'; }}
        onMouseLeave={e => { if (!isCalculating) e.currentTarget.style.background = '#F4C522'; }}
      >
        {isCalculating ? 'Calculating...' : t('booking.continue')}
      </button>
    </>
  );
}
