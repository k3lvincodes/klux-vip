import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

export default function HowItWorks() {
  const { t } = useTranslation();

  return (
    <section className="how-it-works section-padding" id="how-it-works">
      <div className="container">
        <div className="hiw-layout">
          {/* Left column: text content */}
          <div className="hiw-left">
            <h2 className="hiw-headline">{t('how_it_works.title')}</h2>
            <p className="hiw-subtitle">{t('how_it_works.subtitle')}</p>
            <Link to="/book" className="hiw-cta">
              {t('how_it_works.book_a_ride_now')}
            </Link>
          </div>

          {/* Right column: vertical step timeline */}
          <div className="hiw-timeline">
            {/* Step 1 */}
            <div className="hiw-step-group">
              <div className="hiw-badge">1</div>
              <div className="hiw-card">
                <div className="hiw-card-header">
                  <h3>{t('how_it_works.step1_title')}</h3>
                  <div className="hiw-card-icon">
                    <img src="/ride choose.png" alt={t('how_it_works.step1_title')} loading="lazy" />
                  </div>
                </div>
                <p>{t('how_it_works.step1_desc')}</p>
              </div>
            </div>

            {/* Step 2 */}
            <div className="hiw-step-group">
              <div className="hiw-badge">2</div>
              <div className="hiw-card">
                <div className="hiw-card-header">
                  <h3>{t('how_it_works.step2_title')}</h3>
                  <div className="hiw-card-icon">
                    <img src="/location search.png" alt={t('how_it_works.step2_title')} loading="lazy" />
                  </div>
                </div>
                <p>{t('how_it_works.step2_desc')}</p>
              </div>
            </div>

            {/* Step 3 */}
            <div className="hiw-step-group">
              <div className="hiw-badge">3</div>
              <div className="hiw-card">
                <div className="hiw-card-header">
                  <h3>{t('how_it_works.step3_title')}</h3>
                  <div className="hiw-card-icon">
                    <img src="/confirm.png" alt={t('how_it_works.step3_title')} loading="lazy" />
                  </div>
                </div>
                <p>{t('how_it_works.step3_desc')}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
