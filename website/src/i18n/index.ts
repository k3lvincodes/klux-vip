import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import enUS from './locales/en-US';
import enGB from './locales/en-GB';
import enCA from './locales/en-CA';
import enAU from './locales/en-AU';
import enNG from './locales/en-NG';
import frCA from './locales/fr-CA';
import esUS from './locales/es-US';
import ar from './locales/ar';
import ptBR from './locales/pt-BR';
import pcmNG from './locales/pcm-NG';
import yoNG from './locales/yo-NG';
import igNG from './locales/ig-NG';
import haNG from './locales/ha-NG';

function extendBase(overrides: Record<string, any>): Record<string, any> {
  const merged: Record<string, any> = {};
  for (const section of Object.keys(enUS)) {
    merged[section] = { ...(enUS as any)[section], ...(overrides as any)[section] };
  }
  for (const section of Object.keys(overrides)) {
    if (!(section in enUS)) {
      merged[section] = (overrides as any)[section];
    }
  }
  return merged;
}

const LOCALE_CONFIG = {
  'en-US': { dir: 'ltr' },
  'en-GB': { dir: 'ltr' },
  'en-CA': { dir: 'ltr' },
  'en-AU': { dir: 'ltr' },
  'en-NG': { dir: 'ltr' },
  'fr-CA': { dir: 'ltr' },
  'es-US': { dir: 'ltr' },
  'ar': { dir: 'rtl' },
  'pt-BR': { dir: 'ltr' },
  'pcm-NG': { dir: 'ltr' },
  'yo-NG': { dir: 'ltr' },
  'ig-NG': { dir: 'ltr' },
  'ha-NG': { dir: 'ltr' },
} as const;

export type LocaleCode = keyof typeof LOCALE_CONFIG;

export function getLocaleDir(locale: string): 'ltr' | 'rtl' {
  return (LOCALE_CONFIG as Record<string, { dir: string }>)[locale]?.dir as 'ltr' | 'rtl' || 'ltr';
}

export function applyLocaleDirection(locale: string): void {
  const dir = getLocaleDir(locale);
  document.documentElement.dir = dir;
  document.documentElement.lang = locale;
  document.documentElement.classList.toggle('rtl', dir === 'rtl');
}

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      'en-US': { translation: enUS },
      'en-GB': { translation: extendBase(enGB) },
      'en-CA': { translation: extendBase(enCA) },
      'en-AU': { translation: extendBase(enAU) },
      'en-NG': { translation: extendBase(enNG) },
      'fr-CA': { translation: frCA },
      'es-US': { translation: esUS },
      'ar': { translation: ar },
      'pt-BR': { translation: ptBR },
      'pcm-NG': { translation: pcmNG },
      'yo-NG': { translation: yoNG },
      'ig-NG': { translation: igNG },
      'ha-NG': { translation: haNG },
    },
    fallbackLng: {
      'ar': ['en-US'],
      'yo-NG': ['en-NG', 'en-US'],
      'ig-NG': ['en-NG', 'en-US'],
      'ha-NG': ['en-NG', 'en-US'],
      'pcm-NG': ['en-NG', 'en-US'],
      'default': ['en-US'],
    },
    load: 'currentOnly',
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: 'i18nextLng',
    },
    returnObjects: true,
    returnNull: false,
  });

i18n.on('languageChanged', (lng) => {
  applyLocaleDirection(lng);
});

applyLocaleDirection(i18n.language || 'en-US');

export default i18n;
