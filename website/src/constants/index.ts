export const VEHICLES = [
  { value: 'GMC Yukon', labelKey: 'fleet.gmc_yukon' },
  { value: 'Cadillac Escalade', labelKey: 'fleet.cadillac_escalade' },
  { value: 'Ford Expedition', labelKey: 'fleet.ford_expedition' },
  { value: 'Standard SUV', labelKey: 'fleet.standard_suv' },
] as const;

export const HERO_IMAGES = ['/1.webp', '/2.webp', '/3.webp', '/4.webp'] as const;

export const NAV_LINKS = [
  { key: 'home', hash: '' },
  { key: 'fleets', hash: 'fleets' },
  { key: 'services', hash: 'services' },
  { key: 'about_us', hash: 'about-us' },
] as const;

export const LOCALES = [
  { code: 'en-US', short: 'En', native: 'English (US)' },
  { code: 'en-GB', short: 'En', native: 'English (UK)' },
  { code: 'en-CA', short: 'En', native: 'English (CA)' },
  { code: 'en-AU', short: 'En', native: 'English (AU)' },
  { code: 'en-NG', short: 'En', native: 'English (NG)' },
  { code: 'fr-CA', short: 'Fr', native: 'Français (CA)' },
  { code: 'es-US', short: 'Es', native: 'Español (US)' },
  { code: 'pt-BR', short: 'Pt', native: 'Português (BR)' },
  { code: 'ar', short: 'ع', native: 'العربية' },
  { code: 'pcm-NG', short: 'Pcm', native: 'Pidgin (NG)' },
  { code: 'yo-NG', short: 'Yor', native: 'Yorùbá' },
  { code: 'ig-NG', short: 'Igb', native: 'Igbo' },
  { code: 'ha-NG', short: 'Hau', native: 'Hausa' },
] as const;
