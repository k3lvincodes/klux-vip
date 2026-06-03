import { useState, useRef, useEffect } from 'react';
import { useTranslation } from 'react-i18next';

const FLAG_MAP: Record<string, string> = {
  'en-US': 'us',
  'en-GB': 'gb',
  'en-CA': 'ca',
  'en-AU': 'au',
  'en-NG': 'ng',
  'fr-CA': 'ca',
  'es-US': 'us',
  'pt-BR': 'br',
  'ar': 'sa',
  'pcm-NG': 'ng',
  'yo-NG': 'ng',
  'ig-NG': 'ng',
  'ha-NG': 'ng',
};

const LANGUAGES = [
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
];

function getFlag(locale: string): string {
  return FLAG_MAP[locale] || 'us';
}

function getShort(locale: string): string {
  return LANGUAGES.find((l) => l.code === locale)?.short ?? 'En';
}

export default function LanguageSwitcher() {
  const { i18n } = useTranslation();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const currentFlag = getFlag(i18n.language);
  const currentShort = getShort(i18n.language);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className={`nav-lang ${open ? 'open' : ''}`} ref={ref} onClick={() => setOpen((v) => !v)}>
      <img src={`https://flagcdn.com/w40/${currentFlag}.png`} alt={currentShort} />
      <span>{currentShort}</span>
      <svg width="10" height="6" viewBox="0 0 10 6" fill="none" style={{ marginLeft: '2px' }}>
        <path d="M1 1L5 5L9 1" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
      {open && (
        <ul className="lang-switcher-dropdown">
          {LANGUAGES.map((lang) => (
            <li key={lang.code}>
              <button
                className={`lang-option${i18n.language === lang.code ? ' active' : ''}`}
                onClick={(e) => {
                  e.stopPropagation();
                  i18n.changeLanguage(lang.code);
                  setOpen(false);
                }}
              >
                <img src={`https://flagcdn.com/w40/${getFlag(lang.code)}.png`} alt="" className="lang-option-flag" />
                <span className="lang-short">{lang.short}</span>
                <span className="lang-native">{lang.native}</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
