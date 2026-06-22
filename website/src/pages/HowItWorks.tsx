import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

export default function HowItWorks() {
  const { t } = useTranslation();

  return (
    <section className="how-it-works section-padding" id="how-it-works">
      <div className="container">
        <div className="hiw-layout">
          {/* Left: Tree diagram */}
          <div className="hiw-tree">
            {/* SVG connector lines */}
            <svg className="hiw-lines" viewBox="0 0 600 680" fill="none" xmlns="http://www.w3.org/2000/svg">
              {/* Vertical trunk */}
              <line x1="120" y1="70" x2="120" y2="560" stroke="#222" strokeWidth="2.5" />
              {/* Branch to step 1 */}
              <line x1="120" y1="70" x2="370" y2="70" stroke="#222" strokeWidth="2.5" />
              {/* Branch to step 2 (longest) */}
              <line x1="120" y1="340" x2="460" y2="340" stroke="#222" strokeWidth="2.5" />
              {/* Branch to step 3 */}
              <line x1="120" y1="560" x2="370" y2="560" stroke="#222" strokeWidth="2.5" />
            </svg>

            {/* Big circle */}
            <div className="hiw-big-circle">
              <h2 dangerouslySetInnerHTML={{ __html: String(t('how_it_works.title')).replace(' ', '<br />') }} />
            </div>

            {/* Step 1 - top */}
            <div className="hiw-step hiw-step-1">
              <div className="hiw-step-icon">
                <img src="/ride choose.png" alt={t('how_it_works.step1_title')} />
              </div>
              <p className="hiw-step-label">1. {t('how_it_works.step1_title')}</p>
            </div>

            {/* Step 2 - middle */}
            <div className="hiw-step hiw-step-2">
              <div className="hiw-step-icon">
                <img src="/location search.png" alt={t('how_it_works.step2_title')} />
              </div>
              <p className="hiw-step-label">2. {t('how_it_works.step2_title')}</p>
            </div>

            {/* Step 3 - bottom */}
            <div className="hiw-step hiw-step-3">
              <div className="hiw-step-icon">
                <img src="/confirm.png" alt={t('how_it_works.step3_title')} />
              </div>
              <p className="hiw-step-label">3. {t('how_it_works.step3_title')}</p>
            </div>
          </div>

          {/* Right: Phone mockup */}
          <div className="hiw-phone">
            <img src="/Payment successful Mockup.png" alt={t('how_it_works.step3_title')} className="hiw-phone-img" />
          </div>
        </div>
        
        <div style={{ textAlign: 'center', marginTop: '3rem' }}>
          <Link to="/book" className="nav-cta" style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', textDecoration: 'none', width: '209px', height: '59px', fontSize: '1.05rem' }}>
            {t('how_it_works.book_a_ride_now')}
          </Link>
        </div>
      </div>
    </section>
  );
}
