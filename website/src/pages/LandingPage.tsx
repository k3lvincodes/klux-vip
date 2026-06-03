import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import HowItWorks from './HowItWorks';
import Fleets from './Fleets';
import Services from './Services';
import AboutUs from './AboutUs';
import Testimonials from './Testimonials';
import Contact from './Contact';
import FAQ from '../components/FAQ';
import '../App.css';

export default function LandingPage() {
  const { t } = useTranslation();

  useEffect(() => {
    const hash = window.location.hash;
    if (hash) {
      const id = hash.replace('#', '');
      setTimeout(() => {
        document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    }
  }, []);

  return (
    <>
      {/* ====== SECTION 1: HERO ====== */}
      <section className="hero-wrapper" id="home">
        <div className="hero-content">
          <div className="hero-text">
            <h1 className="hero-headline">
              <span className="hero-headline-highlight">{t('hero.premium_black_car')}</span>
              <span style={{ display: 'block', marginTop: '20px' }} dangerouslySetInnerHTML={{ __html: t('hero.experience_on_demand') }} />
            </h1>
            <Link to="/book" style={{ textDecoration: 'none' }}>
              <button className="hero-book-btn">{t('hero.book_a_ride')}</button>
            </Link>
            <div className="hero-badges">
              <button className="store-badge">
                <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt={t('common.app_store')} />
              </button>
              <button className="store-badge">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt={t('common.google_play')} />
              </button>
            </div>
          </div>
        </div>
      </section>

      <HowItWorks />
      <Fleets />
      <Services />
      <AboutUs />
      <Testimonials />
      <Contact />

      <FAQ />

      {/* ====== DOWNLOAD APP ====== */}
      <section className="download-section">
        <div className="container">
          <div className="download-header">
            <h2>{t('common.download_app')}</h2>
            <p>{t('common.available_ios_android')}</p>
          </div>
          <div className="download-layout">
            <div className="download-img-col">
              <img src="/kenick phone mockup.png" alt={t('common.download_app')} />
            </div>
            <div className="download-text-col">
              <h2 dangerouslySetInnerHTML={{ __html: t('common.your_premium_ride_awaits') }} />
              <p>{t('common.available_ios_android')}</p>
              <div className="hero-badges" style={{ marginTop: 0 }}>
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt={t('common.app_store')} />
                </button>
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt={t('common.google_play')} />
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
