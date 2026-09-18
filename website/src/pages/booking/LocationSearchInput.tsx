import { useState, useEffect, useRef } from 'react';
import { MapPin, Navigation, Loader2, X } from 'lucide-react';
import { searchPlaces, getCurrentUserLocation, type LocationSuggestion } from '../../services/locationService';

interface Props {
  id: string;
  name: string;
  label: string;
  value: string;
  placeholder?: string;
  required?: boolean;
  isPickup?: boolean;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onSelectLocation?: (location: LocationSuggestion) => void;
}

export default function LocationSearchInput({
  id,
  name,
  label,
  value,
  placeholder,
  required,
  isPickup = false,
  onChange,
  onSelectLocation,
}: Props) {
  const [isOpen, setIsOpen] = useState(false);
  const [suggestions, setSuggestions] = useState<LocationSuggestion[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [isLocating, setIsLocating] = useState(false);
  const [locationError, setLocationError] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const debounceTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Close dropdown on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  // Debounced search starting immediately at 1 character (150ms debounce)
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange(e);
    const query = e.target.value;

    if (debounceTimerRef.current) {
      clearTimeout(debounceTimerRef.current);
    }

    if (!query || query.trim().length === 0) {
      setSuggestions([]);
      setIsSearching(false);
      return;
    }

    setIsOpen(true);
    setIsSearching(true);
    setLocationError(null);

    debounceTimerRef.current = setTimeout(async () => {
      try {
        const results = await searchPlaces(query);
        setSuggestions(results);
      } catch {
        setSuggestions([]);
      } finally {
        setIsSearching(false);
      }
    }, 150);
  };

  // Select suggestion
  const handleSelectSuggestion = (suggestion: LocationSuggestion) => {
    const syntheticEvent = {
      target: {
        name,
        value: suggestion.placeName,
      },
    } as React.ChangeEvent<HTMLInputElement>;

    onChange(syntheticEvent);
    if (onSelectLocation) {
      onSelectLocation(suggestion);
    }

    setIsOpen(false);
    setSuggestions([]);
  };

  // Get current GPS location
  const handleCurrentLocation = async (e: React.MouseEvent) => {
    e.stopPropagation();
    setIsLocating(true);
    setLocationError(null);

    try {
      const loc = await getCurrentUserLocation();
      const syntheticEvent = {
        target: {
          name,
          value: loc.placeName,
        },
      } as React.ChangeEvent<HTMLInputElement>;

      onChange(syntheticEvent);
      if (onSelectLocation) {
        onSelectLocation(loc);
      }

      setIsOpen(false);
      setSuggestions([]);
    } catch (err: unknown) {
      setLocationError(err instanceof Error ? err.message : 'Could not fetch current location');
      setTimeout(() => setLocationError(null), 4000);
    } finally {
      setIsLocating(false);
    }
  };

  const handleClear = (e: React.MouseEvent) => {
    e.stopPropagation();
    const syntheticEvent = {
      target: {
        name,
        value: '',
      },
    } as React.ChangeEvent<HTMLInputElement>;
    onChange(syntheticEvent);
    setSuggestions([]);
    if (inputRef.current) {
      inputRef.current.focus();
    }
  };

  return (
    <div ref={containerRef} className="location-search-wrapper" style={{ position: 'relative', width: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
        <label htmlFor={id} className="booking-label" style={{ margin: 0 }}>
          {label}
        </label>
        {isPickup && (
          <button
            type="button"
            onClick={handleCurrentLocation}
            disabled={isLocating}
            className="location-quick-gps-btn"
            title="Use current GPS location"
          >
            {isLocating ? (
              <>
                <Loader2 size={12} className="spin" />
                <span>Locating...</span>
              </>
            ) : (
              <>
                <Navigation size={12} style={{ transform: 'rotate(45deg)' }} />
                <span>Current Location</span>
              </>
            )}
          </button>
        )}
      </div>

      <div className="location-input-container">
        <input
          ref={inputRef}
          id={id}
          type="text"
          name={name}
          value={value}
          onChange={handleInputChange}
          onFocus={() => setIsOpen(true)}
          placeholder={placeholder}
          required={required}
          autoComplete="off"
          className="booking-input location-text-input"
        />

        <div className="location-input-actions">
          {isSearching && <Loader2 size={15} className="spin location-icon-action" />}
          {!isSearching && value && (
            <button
              type="button"
              onClick={handleClear}
              className="location-clear-btn"
              title="Clear input"
            >
              <X size={14} />
            </button>
          )}
        </div>
      </div>

      {locationError && (
        <div className="location-error-msg">
          {locationError}
        </div>
      )}

      {/* ── Dropdown Panel ── */}
      {isOpen && (
        <div className="location-dropdown-panel no-scrollbar">
          {/* 1. Current Location Option */}
          <div
            className={`location-item location-current-option ${isLocating ? 'loading' : ''}`}
            onClick={handleCurrentLocation}
          >
            <div className="location-item-icon current-gps-icon">
              {isLocating ? (
                <Loader2 size={16} className="spin" />
              ) : (
                <Navigation size={16} style={{ transform: 'rotate(45deg)', color: '#F4C522' }} />
              )}
            </div>
            <div className="location-item-text">
              <div className="location-item-main">
                {isLocating ? 'Acquiring GPS location...' : 'Current Location'}
              </div>
              <div className="location-item-sub">
                Use your device's live satellite position
              </div>
            </div>
          </div>

          {/* 2. Loading state while searching */}
          {isSearching && suggestions.length === 0 && (
            <div className="location-dropdown-status">
              <Loader2 size={15} className="spin" />
              <span>Searching addresses...</span>
            </div>
          )}

          {/* 3. Suggestions List */}
          {suggestions.length > 0 && (
            <div className="location-suggestions-group">
              <div className="location-dropdown-divider" />
              <div className="location-group-title">Suggestions</div>
              {suggestions.map((item) => (
                <div
                  key={item.id}
                  className="location-item location-suggestion-option"
                  onClick={() => handleSelectSuggestion(item)}
                >
                  <div className="location-item-icon pin-icon">
                    <MapPin size={15} />
                  </div>
                  <div className="location-item-text">
                    <div className="location-item-main">{item.mainText}</div>
                    {item.secondaryText && (
                      <div className="location-item-sub">{item.secondaryText}</div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* 4. No suggestions state */}
          {!isSearching && value.trim().length >= 1 && suggestions.length === 0 && (
            <div className="location-dropdown-status no-results">
              No matching addresses found for "{value}"
            </div>
          )}
        </div>
      )}
    </div>
  );
}
