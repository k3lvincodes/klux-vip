import { useTranslation } from 'react-i18next';

const SERVICE_KEYS = [
  { titleKey: 'services.airport_transfers', descKey: 'services.airport_transfers_desc', img: '/airport image.webp' },
  { titleKey: 'services.corporate_travel', descKey: 'services.corporate_travel_desc', img: '/copoorate image.webp' },
  { titleKey: 'services.special_events', descKey: 'services.special_events_desc', img: '/event image.webp' },
  { titleKey: 'services.vip_service', descKey: 'services.vip_service_desc', img: '/group transport image.webp' },
];

export default function Services() {
  const { t } = useTranslation();

  return (
    <section className="services section-padding page-layout" id="services">
      <div className="services-bg-circle-1" />
      <div className="services-bg-circle-2" />
      <h2 className="section-title">{t('services.title')}</h2>
      <div className="container">
        <div className="services-grid">
          {SERVICE_KEYS.map((s) => (
            <div className="service-card" key={s.titleKey}>
              <div className="service-card-img"><img src={s.img} alt={t(s.titleKey)} loading="lazy" /></div>
              <div className="service-card-body">
                <h3>{t(s.titleKey)}</h3>
                <p>{t(s.descKey)}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="services-cta" style={{ textAlign: 'center', marginTop: '3rem' }}>
          <a href="/#contact" className="btn btn-dark services-learn-btn" style={{ display: 'inline-block', textDecoration: 'none' }}>{t('services.view_all_services')}</a>
        </div>
      </div>
    </section>
  );
}
