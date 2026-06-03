import { CheckCircle2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export default function AboutUs() {
  const { t } = useTranslation();

  return (
    <div className="page-layout" style={{ backgroundColor: '#fff', color: '#000' }}>
      <section className="about-us section-padding" id="about-us" style={{ paddingTop: '2rem' }}>
        <div className="container">
          <div className="about-text" style={{ textAlign: 'center', maxWidth: '800px', margin: '0 auto' }}>
            <h2 className="section-title" style={{ marginBottom: '1.5rem' }}>{t('about.title')}</h2>
            <p>{t('about.description')}</p>
          </div>
        </div>
      </section>

      <section className="why-choose section-padding" id="why-choose-us" style={{ marginTop: '40px' }}>
        <div className="container">
          <h2 className="section-title" style={{ color: '#fff' }}>{t('about.why_choose_us')}</h2>
          <div className="wcu-card">
            <div className="wcu-grid">
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> {t('about.professional_chauffeurs')}</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> {t('about.real_time_tracking')}</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> {t('about.premium_fleet')}</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> {t('about.247_support')}</div>
              <div className="wcu-item wcu-item-full"><CheckCircle2 size={24} strokeWidth={1.5} /> {t('about.mission_title')}</div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
