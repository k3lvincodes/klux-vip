import { useState, useEffect, useCallback } from 'react';

interface GeolocationState {
  latitude: number | null;
  longitude: number | null;
  error: string | null;
  loading: boolean;
}

export function useGeolocation(enableHighAccuracy = true): GeolocationState {
  const [state, setState] = useState<GeolocationState>({
    latitude: null,
    longitude: null,
    error: null,
    loading: true,
  });

  const onSuccess = useCallback((pos: GeolocationPosition) => {
    setState({
      latitude: pos.coords.latitude,
      longitude: pos.coords.longitude,
      error: null,
      loading: false,
    });
  }, []);

  const onError = useCallback((err: GeolocationPositionError) => {
    setState(prev => ({
      ...prev,
      error: err.message,
      loading: false,
    }));
  }, []);

  useEffect(() => {
    if (!navigator.geolocation) {
      setState(prev => ({ ...prev, error: 'Geolocation not supported', loading: false }));
      return;
    }

    navigator.geolocation.getCurrentPosition(onSuccess, onError, {
      enableHighAccuracy,
      timeout: 10000,
      maximumAge: 300000,
    });
  }, [enableHighAccuracy, onSuccess, onError]);

  return state;
}
