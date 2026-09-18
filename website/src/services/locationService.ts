export interface LocationSuggestion {
  id: string;
  placeName: string;
  mainText: string;
  secondaryText: string;
  lat: number;
  lng: number;
}

// In-memory cache for ultra-responsive keystroke predictions (e.g. W -> WA -> WAR)
const searchCache = new Map<string, LocationSuggestion[]>();
const reverseCache = new Map<string, LocationSuggestion>();
const inflight = new Map<string, Promise<LocationSuggestion[]>>();

// Prefix cache matching: if user types "WAR", filter existing cached results from "WA" or "W"
function filterFromPrefixCache(query: string): LocationSuggestion[] {
  const normalized = query.trim().toLowerCase();
  let longestPrefixKey = '';

  for (const key of searchCache.keys()) {
    if (normalized.startsWith(key) && key.length > longestPrefixKey.length) {
      longestPrefixKey = key;
    }
  }

  if (!longestPrefixKey) return [];

  const parentResults = searchCache.get(longestPrefixKey) || [];
  return parentResults.filter((r) =>
    r.placeName.toLowerCase().includes(normalized) ||
    r.mainText.toLowerCase().includes(normalized)
  );
}

/**
 * Searches places starting from 1 character query.
 * Uses Mapbox Geocoding API if token is configured, with OpenStreetMap Nominatim as fallback.
 */
export async function searchPlaces(
  query: string,
  countryCode?: string
): Promise<LocationSuggestion[]> {
  const trimmed = query.trim();
  if (trimmed.length < 1) return [];

  const cacheKey = `${trimmed.toLowerCase()}_${countryCode || 'all'}`;

  if (searchCache.has(cacheKey)) {
    return searchCache.get(cacheKey)!;
  }

  // If a request for this exact query is already inflight, reuse the promise
  if (inflight.has(cacheKey)) {
    return inflight.get(cacheKey)!;
  }

  // Instant prefix lookup while fresh fetch proceeds
  const prefixMatches = filterFromPrefixCache(trimmed);

  const fetchPromise = (async () => {
    try {
      const mapboxToken = import.meta.env.VITE_MAPBOX_TOKEN;

      if (mapboxToken && mapboxToken.startsWith('pk.')) {
        try {
          const countryParam = countryCode ? `&country=${encodeURIComponent(countryCode)}` : '';
          const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
            trimmed
          )}.json?access_token=${mapboxToken}&autocomplete=true&types=address,poi,place,neighborhood&limit=6${countryParam}`;

          const res = await fetch(url);
          if (res.ok) {
            const data = await res.json();
            if (data.features && Array.isArray(data.features) && data.features.length > 0) {
              const suggestions: LocationSuggestion[] = data.features.map(
                (f: {
                  id: string;
                  place_name: string;
                  text: string;
                  center: [number, number];
                  context?: Array<{ text: string }>;
                }) => {
                  const secondaryParts = f.context ? f.context.map((c) => c.text).join(', ') : '';
                  return {
                    id: f.id,
                    placeName: f.place_name,
                    mainText: f.text || f.place_name.split(',')[0],
                    secondaryText: secondaryParts || f.place_name.split(',').slice(1).join(',').trim(),
                    lng: f.center[0],
                    lat: f.center[1],
                  };
                }
              );

              searchCache.set(cacheKey, suggestions);
              return suggestions;
            }
          }
        } catch {
          // Fall through to Nominatim
        }
      }

      // Fallback: OpenStreetMap Nominatim
      const nominatimCodes = countryCode ? `&countrycodes=${encodeURIComponent(countryCode.toLowerCase())}` : '';
      const nominatimUrl = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(
        trimmed
      )}&format=json&addressdetails=1&limit=6${nominatimCodes}`;

      const res = await fetch(nominatimUrl, {
        headers: {
          Accept: 'application/json',
          'User-Agent': 'KenickChauffeur/1.0',
        },
      });

      if (!res.ok) return prefixMatches;

      const data = await res.json();
      if (!Array.isArray(data)) return prefixMatches;

      const suggestions: LocationSuggestion[] = data.map((item: {
        place_id: number;
        display_name: string;
        lat: string;
        lon: string;
        address?: Record<string, string>;
      }) => {
        const parts = item.display_name.split(',').map((s) => s.trim());
        const mainText = parts[0] || 'Location';
        const secondaryText = parts.slice(1, 4).join(', ');

        return {
          id: String(item.place_id),
          placeName: item.display_name,
          mainText,
          secondaryText,
          lat: parseFloat(item.lat),
          lng: parseFloat(item.lon),
        };
      });

      searchCache.set(cacheKey, suggestions);
      return suggestions;
    } catch {
      return prefixMatches;
    } finally {
      inflight.delete(cacheKey);
    }
  })();

  inflight.set(cacheKey, fetchPromise);
  return fetchPromise;
}

/**
 * Reverse geocodes coordinates into an address suggestion.
 */
export async function reverseGeocode(lat: number, lng: number): Promise<LocationSuggestion | null> {
  const cacheKey = `${lat.toFixed(4)},${lng.toFixed(4)}`;
  if (reverseCache.has(cacheKey)) {
    return reverseCache.get(cacheKey)!;
  }

  const mapboxToken = import.meta.env.VITE_MAPBOX_TOKEN;

  if (mapboxToken && mapboxToken.startsWith('pk.')) {
    try {
      const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${mapboxToken}&types=address,poi,place&limit=1`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        if (data.features && data.features.length > 0) {
          const f = data.features[0];
          const result: LocationSuggestion = {
            id: f.id,
            placeName: f.place_name,
            mainText: f.text || f.place_name.split(',')[0],
            secondaryText: f.place_name.split(',').slice(1).join(',').trim(),
            lat,
            lng,
          };
          reverseCache.set(cacheKey, result);
          return result;
        }
      }
    } catch {
      // Fall through to Nominatim
    }
  }

  // Fallback to Nominatim Reverse Geocoding
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`;
    const res = await fetch(url, {
      headers: {
        Accept: 'application/json',
        'User-Agent': 'KenickChauffeur/1.0',
      },
    });

    if (res.ok) {
      const data = await res.json();
      if (data && data.display_name) {
        const parts = data.display_name.split(',').map((s: string) => s.trim());
        const result: LocationSuggestion = {
          id: String(data.place_id || Date.now()),
          placeName: data.display_name,
          mainText: parts[0] || 'Current Location',
          secondaryText: parts.slice(1, 4).join(', '),
          lat,
          lng,
        };
        reverseCache.set(cacheKey, result);
        return result;
      }
    }
  } catch {
    // Return coordinate fallback
  }

  const fallback: LocationSuggestion = {
    id: `gps-${Date.now()}`,
    placeName: `Current Location (${lat.toFixed(4)}, ${lng.toFixed(4)})`,
    mainText: 'Current Location',
    secondaryText: `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
    lat,
    lng,
  };
  return fallback;
}

/**
 * Gets user's current GPS location via browser Geolocation API
 * and reverse geocodes to an address suggestion.
 */
export async function getCurrentUserLocation(): Promise<LocationSuggestion> {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation is not supported by your browser'));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      async (position) => {
        const { latitude, longitude } = position.coords;
        try {
          const result = await reverseGeocode(latitude, longitude);
          if (result) {
            resolve(result);
          } else {
            resolve({
              id: 'current-loc',
              placeName: `Current Location (${latitude.toFixed(4)}, ${longitude.toFixed(4)})`,
              mainText: 'Current Location',
              secondaryText: `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
              lat: latitude,
              lng: longitude,
            });
          }
        } catch {
          resolve({
            id: 'current-loc',
            placeName: 'Current Location',
            mainText: 'Current Location',
            secondaryText: `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
            lat: latitude,
            lng: longitude,
          });
        }
      },
      (error) => {
        let msg = 'Unable to retrieve location';
        if (error.code === error.PERMISSION_DENIED) {
          msg = 'Location permission was denied. Please allow location access.';
        } else if (error.code === error.POSITION_UNAVAILABLE) {
          msg = 'Location information is unavailable.';
        } else if (error.code === error.TIMEOUT) {
          msg = 'Location request timed out.';
        }
        reject(new Error(msg));
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 30000,
      }
    );
  });
}
