const CURRENCY_MAP: Record<string, string> = {
  'en-US': 'USD',
  'en-GB': 'GBP',
  'en-CA': 'CAD',
  'en-AU': 'AUD',
  'en-NG': 'NGN',
  'fr-CA': 'CAD',
  'es-US': 'USD',
  'ar': 'USD',
  'pt-BR': 'BRL',
  'pcm-NG': 'NGN',
  'yo-NG': 'NGN',
  'ig-NG': 'NGN',
  'ha-NG': 'NGN',
};

export function getCurrencyCode(locale: string): string {
  return CURRENCY_MAP[locale] || 'USD';
}

export function formatCurrency(amount: number, locale: string): string {
  const currency = getCurrencyCode(locale);
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  } catch {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(amount);
  }
}

export function formatDate(date: string | Date, locale: string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  try {
    return new Intl.DateTimeFormat(locale, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    }).format(d);
  } catch {
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    }).format(d);
  }
}

export function formatTime(date: string | Date, locale: string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  try {
    return new Intl.DateTimeFormat(locale, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }).format(d);
  } catch {
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    }).format(d);
  }
}

export function formatNumber(num: number, locale: string): string {
  try {
    return new Intl.NumberFormat(locale).format(num);
  } catch {
    return new Intl.NumberFormat('en-US').format(num);
  }
}

export function formatPhone(phone: string, locale: string): string {
  const digits = phone.replace(/\D/g, '');
  if (locale.startsWith('en-US') || locale.startsWith('es-US')) {
    if (digits.length === 10) return `+1 (${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
    if (digits.length === 11 && digits[0] === '1') return `+1 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
  }
  if (locale.startsWith('en-GB')) {
    if (digits.length === 10) return `+44 ${digits.slice(1, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  }
  if (locale.startsWith('en-NG') || locale === 'pcm-NG' || locale === 'yo-NG' || locale === 'ig-NG' || locale === 'ha-NG') {
    if (digits.length === 10) return `+234 ${digits.slice(1, 4)} ${digits.slice(4, 7)} ${digits.slice(7)}`;
  }
  return `+${digits}`;
}
