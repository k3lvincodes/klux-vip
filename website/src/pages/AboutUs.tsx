import { useTranslation } from 'react-i18next';

const features = [
  {
    num: '01',
    key: 'professional_chauffeurs',
    descKey: 'professional_chauffeurs_desc',
    highlight: false,
  },
  {
    num: '02',
    key: 'premium_fleet',
    descKey: 'premium_fleet_desc',
    highlight: false,
  },
  {
    num: '03',
    key: 'real_time_tracking',
    descKey: 'real_time_tracking_desc',
    highlight: true,
  },
  {
    num: '04',
    key: 'safe_secure',
    descKey: 'safe_secure_desc',
    highlight: true,
  },
  {
    num: '05',
    key: '247_support',
    descKey: '247_support_desc',
    highlight: true,
  },
];

export default function AboutUs() {
  const { t } = useTranslation();

  return (
    <>
      <section className="about-us-section" id="about-us">
        <div className="container about-us-container">
          <h2 className="about-us-heading">{t('about.title')}</h2>
          <p className="about-us-text">{t('about.description')}</p>
        </div>
      </section>
      <section className="why-choose section-padding" id="why-choose-us">
      <div className="container">
        <div className="wcu-layout">
          <div className="wcu-left">
            <h2 className="wcu-headline">
              <span>{t('about.why_choose_us_line1')}</span>
              <span>{t('about.why_choose_us_line2')}</span>
            </h2>
            <p className="wcu-tagline">{t('about.why_choose_tagline')}</p>
            <div className="wcu-photo">
              <img
                src="/Mask group.png"
                alt="Professional chauffeur"
                loading="lazy"
              />
            </div>
          </div>
          <div className="wcu-right">
            {features.map((f) => (
              <div className={`wcu-feature${f.highlight ? ' wcu-feature--active' : ''}`} key={f.num}>
                <span className="wcu-feature-num">{f.num}</span>
                <div className="wcu-feature-text">
                  <h3>{t(`about.${f.key}`)}</h3>
                  <p>{t(`about.${f.descKey}`)}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
    </>
  );
}
