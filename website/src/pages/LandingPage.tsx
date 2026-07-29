import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Download } from 'lucide-react';
import HowItWorks from '../components/sections/HowItWorks';
import Fleets from '../components/sections/Fleets';
import Services from '../components/sections/Services';
import AboutUs from '../components/sections/AboutUs';
import Testimonials from '../components/sections/Testimonials';
import Contact from '../components/sections/Contact';
import FAQ from '../components/ui/FAQ';
const HERO_IMAGES = ['/1.webp', '/2.webp', '/3.webp', '/4.webp'];

export default function LandingPage() {
  const { t } = useTranslation();
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % HERO_IMAGES.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

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
        {HERO_IMAGES.map((img, i) => (
          <div
            key={img}
            className="hero-bg-layer"
            style={{
              backgroundImage: `linear-gradient(rgba(0,0,0,0.6), rgba(0,0,0,0.6)), url(${img})`,
              opacity: i === currentIndex ? 1 : 0,
            }}
          />
        ))}
        <div className="hero-nav-overlay" />
        <div className="hero-content">
          <div className="hero-text">
            <h1 className="hero-headline">
              <span className="hero-headline-yellow">{t('hero.premium_black_car')}</span>
              <span className="hero-headline-white">{t('hero.experience_on_demand')}</span>
            </h1>
            <p className="hero-subheading">{t('hero.subheading')}</p>
            <Link to="/book" style={{ textDecoration: 'none' }}>
              <button className="hero-cta-btn">
                {t('hero.get_the_app')}
                <Download size={20} />
              </button>
            </Link>
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
              <img src="/ken_mockup_1.webp" alt={t('common.download_app')} loading="lazy" />
            </div>
            <div className="download-text-col">
              <h2>{t('common.your_premium_ride_awaits')}</h2>
              <p>{t('common.available_ios_android')}</p>
              <div className="hero-badges" style={{ marginTop: 0 }}>
                <a href="https://apps.apple.com/app/kenick-transportation" target="_blank" rel="noopener noreferrer" className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt={t('common.app_store')} />
                </a>
                <a href="https://play.google.com/store/apps/details?id=com.kenickvip.app" target="_blank" rel="noopener noreferrer" className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt={t('common.google_play')} />
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
