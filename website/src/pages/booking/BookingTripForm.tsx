import { Calendar, Clock, Car, User, Mail, Phone, Users, Briefcase, ArrowRight, RotateCw, Check } from 'lucide-react';

import type { BookingFormData } from './types';
import LocationSearchInput from './LocationSearchInput';
import type { LocationSuggestion } from '../../services/locationService';

interface Props {
  bookingForm: BookingFormData;
  onChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => void;
  onSubmit: () => void;
  isCalculating: boolean;
  onSelectPickupLocation?: (loc: LocationSuggestion) => void;
  onSelectDropoffLocation?: (loc: LocationSuggestion) => void;
}

const VEHICLES = [
  {
    id: 'Cadillac Escalade',
    name: 'Cadillac Escalade',
    tag: 'Flagship SUV',
    passengers: '6',
    luggage: '5',
    desc: 'Bespoke leather & acoustic executive cabin',
  },
  {
    id: 'GMC Yukon',
    name: 'GMC Yukon Denali',
    tag: 'Executive Class',
    passengers: '7',
    luggage: '6',
    desc: 'Spacious high-comfort long-wheelbase luxury',
  },
  {
    id: 'Ford Expedition',
    name: 'Ford Expedition',
    tag: 'Group Premium',
    passengers: '7',
    luggage: '6',
    desc: 'Extended cargo capacity & group comfort',
  },
  {
    id: 'Standard SUV',
    name: 'Standard Executive SUV',
    tag: 'SUVs',
    passengers: '5',
    luggage: '4',
    desc: 'Refined comfort for executive airport transit',
  },
];

export default function BookingTripForm({
  bookingForm,
  onChange,
  onSubmit,
  isCalculating,
  onSelectPickupLocation,
  onSelectDropoffLocation,
}: Props) {
  const handleSelectVehicle = (vehicleId: string) => {

    const syntheticEvent = {
      target: {
        name: 'vehicle',
        value: vehicleId,
      },
    } as React.ChangeEvent<HTMLInputElement>;
    onChange(syntheticEvent);
  };

  return (
    <div>
      <div style={{ textAlign: 'center', marginBottom: '1.75rem' }}>
        <span style={{ fontSize: '0.72rem', fontWeight: 700, color: 'var(--admin-primary, #F4C522)', textTransform: 'uppercase', letterSpacing: '0.08em', display: 'block', marginBottom: 4 }}>
          Executive Chauffeur Service
        </span>
        <h2 style={{ margin: 0, fontSize: '1.65rem', fontWeight: 800, color: '#ffffff', letterSpacing: '-0.02em' }}>
          Reserve Your Chauffeur
        </h2>
        <p style={{ margin: '4px 0 0', fontSize: '0.82rem', color: '#a1a1aa' }}>
          Fixed transparent pricing · Flight tracking included
        </p>
      </div>

      {/* ── Ride Service Type Selector ── */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '18px', overflowX: 'auto', paddingBottom: '4px' }}>
        {(['One way', 'Round trip', 'By-the-hour', 'Event', 'Out of state'] as const).map((type) => {
          const isSelected = (bookingForm.rideType || 'One way') === type;
          return (
            <button
              key={type}
              type="button"
              onClick={() => {
                const syntheticEvent = {
                  target: { name: 'rideType', value: type },
                } as unknown as React.ChangeEvent<HTMLInputElement>;
                onChange(syntheticEvent);
              }}
              style={{
                padding: '8px 14px',
                borderRadius: '20px',
                fontSize: '0.82rem',
                fontWeight: isSelected ? 600 : 400,
                border: isSelected ? '1px solid var(--admin-primary, #F4C522)' : '1px solid rgba(255,255,255,0.12)',
                backgroundColor: isSelected ? 'rgba(244, 197, 34, 0.15)' : 'rgba(255,255,255,0.04)',
                color: isSelected ? 'var(--admin-primary, #F4C522)' : '#a1a1aa',
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                transition: 'all 0.2s',
              }}
            >
              {type}
            </button>
          );
        })}
      </div>

      {/* ── Connected Route Inputs with 1-Letter Autocomplete & GPS Location ── */}
      <div className="booking-route-box">
        <div className="booking-route-timeline">
          <div className="booking-node-line" />

          {/* Pickup Origin with GPS & Autocomplete */}
          <div className="booking-route-row">
            <div className="booking-node-dot pickup" title="Pickup Location" />
            <div style={{ flex: 1 }}>
              <LocationSearchInput
                id="booking-pickup"
                name="pickup"
                label="Pickup Origin"
                value={bookingForm.pickup}
                placeholder="Hotel, airport terminal, or address..."
                required
                isPickup={true}
                onChange={onChange}
                onSelectLocation={onSelectPickupLocation}
              />
            </div>
          </div>

          {/* Destination with Autocomplete */}
          <div className="booking-route-row">
            <div className="booking-node-dot dropoff" title="Dropoff Destination" />
            <div style={{ flex: 1 }}>
              <LocationSearchInput
                id="booking-dropoff"
                name="dropoff"
                label="Destination"
                value={bookingForm.dropoff}
                placeholder="Airport, private residence, or venue..."
                required
                isPickup={false}
                onChange={onChange}
                onSelectLocation={onSelectDropoffLocation}
              />
            </div>
          </div>
        </div>
      </div>

      {/* ── Schedule (Date & Time for all ride types) ── */}
      <div className="booking-form-row" style={{ marginBottom: '18px' }}>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-date" className="booking-label">
            <Calendar size={14} /> {bookingForm.rideType === 'Round trip' ? 'Departure Date' : 'Pickup Date'}
          </label>
          <input
            id="booking-date"
            type="date"
            name="date"
            value={bookingForm.date}
            onChange={onChange}
            required
            className="booking-input"
          />
        </div>
        <div style={{ flex: 1 }}>
          <label htmlFor="booking-time" className="booking-label">
            <Clock size={14} /> {bookingForm.rideType === 'Round trip' ? 'Departure Time' : 'Pickup Time'}
          </label>
          <input
            id="booking-time"
            type="time"
            name="time"
            value={bookingForm.time}
            onChange={onChange}
            required
            className="booking-input"
          />
        </div>
      </div>

      {/* ── Return Schedule for Round Trip ── */}
      {bookingForm.rideType === 'Round trip' && (
        <div className="booking-form-row" style={{ marginBottom: '18px' }}>
          <div style={{ flex: 1 }}>
            <label htmlFor="booking-return-date" className="booking-label">
              <Calendar size={14} /> Return Date
            </label>
            <input
              id="booking-return-date"
              type="date"
              name="returnDate"
              value={bookingForm.returnDate || ''}
              onChange={onChange}
              required
              className="booking-input"
            />
          </div>
          <div style={{ flex: 1 }}>
            <label htmlFor="booking-return-time" className="booking-label">
              <Clock size={14} /> Return Time
            </label>
            <input
              id="booking-return-time"
              type="time"
              name="returnTime"
              value={bookingForm.returnTime || ''}
              onChange={onChange}
              required
              className="booking-input"
            />
          </div>
        </div>
      )}

      {/* ── Event Type & Custom Event Selection ── */}
      {bookingForm.rideType === 'Event' && (
        <div style={{ marginBottom: '18px' }}>
          <label htmlFor="booking-event-type" className="booking-label">
            Type of Event
          </label>
          <select
            id="booking-event-type"
            name="eventType"
            value={bookingForm.eventType || 'Wedding'}
            onChange={onChange}
            className="booking-input"
            style={{ marginBottom: bookingForm.eventType === 'Other' ? '10px' : 0 }}
          >
            <option value="Wedding">Wedding</option>
            <option value="Corporate Event / Gala">Corporate Event / Gala</option>
            <option value="Concert & Festival">Concert & Festival</option>
            <option value="Sporting Event">Sporting Event</option>
            <option value="Birthday / Anniversary">Birthday / Anniversary</option>
            <option value="Prom & Graduation">Prom & Graduation</option>
            <option value="VIP Night Out">VIP Night Out</option>
            <option value="Airport Delegation">Airport Delegation</option>
            <option value="Other">Other (Custom Event)</option>
          </select>
          {bookingForm.eventType === 'Other' && (
            <input
              type="text"
              name="customEventType"
              value={bookingForm.customEventType || ''}
              onChange={onChange}
              placeholder="Specify event type (e.g. Charity Gala, Film Premiere)..."
              className="booking-input"
              required
            />
          )}
        </div>
      )}

      {/* ── Out of State Notice ── */}
      {bookingForm.rideType === 'Out of state' && (
        <div style={{
          marginBottom: '18px',
          padding: '12px 14px',
          borderRadius: '12px',
          background: 'rgba(244, 197, 34, 0.08)',
          border: '1px solid rgba(244, 197, 34, 0.25)',
          fontSize: '0.8rem',
          color: '#e4e4e7',
          lineHeight: 1.4,
        }}>
          <strong>Interstate Chauffeur Service:</strong> Includes dedicated long-distance route preparation, driver rest pauses, and highway toll management.
        </div>
      )}

      {/* ── Executive Fleet Class Selection ── */}
      <div className="booking-fleet-section">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
          <label className="booking-label" style={{ margin: 0 }}>
            <Car size={14} /> Select Vehicle Tier
          </label>
          <span style={{ fontSize: '0.72rem', color: '#71717a' }}>All tiers include chauffeur</span>
        </div>

        <div className="booking-fleet-grid">
          {VEHICLES.map((v) => {
            const isSelected = bookingForm.vehicle === v.id || bookingForm.vehicle === v.name;
            return (
              <div
                key={v.id}
                className={`booking-fleet-card ${isSelected ? 'selected' : ''}`}
                onClick={() => handleSelectVehicle(v.id)}
              >
                <div className="booking-fleet-header">
                  <div>
                    <div className="booking-fleet-title">{v.name}</div>
                    <span className="booking-fleet-tag">{v.tag}</span>
                  </div>
                  {isSelected && (
                    <div style={{ width: 18, height: 18, borderRadius: '50%', background: '#F4C522', color: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                      <Check size={12} strokeWidth={3} />
                    </div>
                  )}
                </div>

                <div className="booking-fleet-meta">
                  <span><Users size={12} /> {v.passengers} Seats</span>
                  <span><Briefcase size={12} /> {v.luggage} Bags</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* ── Passengers Counter ── */}
      <div style={{ marginBottom: '18px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
          <label htmlFor="booking-passengers" className="booking-label" style={{ margin: 0 }}>
            <Users size={14} /> Passenger Count
          </label>
          <span style={{ fontSize: '0.72rem', color: '#71717a' }}>Max capacity depends on vehicle</span>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          {[1, 2, 3, 4, 5, 6, 7, 8].map((count) => {
            const isSelected = String(bookingForm.passengers) === String(count);
            return (
              <button
                key={count}
                type="button"
                onClick={() => {
                  const evt = { target: { name: 'passengers', value: String(count) } } as React.ChangeEvent<HTMLInputElement>;
                  onChange(evt);
                }}
                style={{
                  flex: 1,
                  padding: '9px 0',
                  borderRadius: '8px',
                  background: isSelected ? 'rgba(244, 197, 34, 0.18)' : '#18181c',
                  border: isSelected ? '1.5px solid #F4C522' : '1px solid rgba(255, 255, 255, 0.1)',
                  color: isSelected ? '#F4C522' : '#ffffff',
                  fontWeight: isSelected ? 700 : 500,
                  fontSize: '0.84rem',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                  fontFamily: 'inherit',
                }}
              >
                {count}
              </button>
            );
          })}
        </div>
      </div>

      {/* ── Passenger Contact Information ── */}
      <div style={{ background: '#18181c', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: '14px', padding: '16px', marginBottom: '22px' }}>
        <div style={{ fontSize: '0.76rem', fontWeight: 700, color: '#e4e4e7', textTransform: 'uppercase', letterSpacing: '0.06em', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: 6 }}>
          <User size={13} style={{ color: '#F4C522' }} />
          Passenger Identification & Contact
        </div>

        <div style={{ marginBottom: '12px' }}>
          <label htmlFor="booking-name" className="booking-label">
            Full Name
          </label>
          <input
            id="booking-name"
            type="text"
            name="name"
            value={bookingForm.name}
            onChange={onChange}
            placeholder="Legal name for chauffeur greeting"
            required
            className="booking-input"
          />
        </div>

        <div className="booking-form-row">
          <div style={{ flex: 1 }}>
            <label htmlFor="booking-email" className="booking-label">
              <Mail size={13} /> Email Confirmation
            </label>
            <input
              id="booking-email"
              type="email"
              name="email"
              value={bookingForm.email}
              onChange={onChange}
              placeholder="itinerary@domain.com"
              required
              className="booking-input"
            />
          </div>
          <div style={{ flex: 1 }}>
            <label htmlFor="booking-phone" className="booking-label">
              <Phone size={13} /> Mobile SMS
            </label>
            <input
              id="booking-phone"
              type="tel"
              name="phone"
              value={bookingForm.phone}
              onChange={onChange}
              placeholder="+1 (555) 000-0000"
              required
              className="booking-input"
            />
          </div>
        </div>
      </div>

      {/* ── Submit CTA ── */}
      <button
        onClick={onSubmit}
        disabled={isCalculating}
        className="booking-btn-primary"
      >
        {isCalculating ? (
          <>
            <RotateCw size={18} className="admin-spin" />
            <span>Estimating Chauffeur Tariff…</span>
          </>
        ) : (
          <>
            <span>Calculate Executive Tariff</span>
            <ArrowRight size={18} />
          </>
        )}
      </button>
    </div>
  );
}

