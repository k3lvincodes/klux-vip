import { useEffect, useRef, useState } from 'react';
import { CheckCircle2, ChevronLeft, ChevronRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const FEATURE_KEYS: Record<string, string> = {
  'Three row SUV': 'fleet.feat_three_row_suv',
  '16-way power front seats with massage': 'fleet.feat_power_front_seats',
  'Air ride adaptive suspension': 'fleet.feat_air_ride_suspension',
  '18-speaker performance series': 'fleet.feat_18_speaker',
  '55 inch curved oled dashboard': 'fleet.feat_oled_dashboard',
  'High-end audio system': 'fleet.feat_audio_system',
  'Semi-aniline leather, wood accents': 'fleet.feat_leather_accents',
  '16-way power adjustable massaging seats': 'fleet.feat_massaging_seats',
  '24-inch panoramic display': 'fleet.feat_panoramic_display',
  'Cargo tailgate manager': 'fleet.feat_cargo_manager',
  'Accommodates 7 to 8 passenger': 'fleet.feat_7_8_passenger',
  '3.5L Ecoboost, Twin-turbo v6': 'fleet.feat_ecoboost',
};

const VEHICLE_NAMES: Record<string, string> = {
  'GMC Yukon': 'fleet.gmc_yukon',
  'Cadillac Escalade': 'fleet.cadillac_escalade',
  'Ford Expedition': 'fleet.ford_expedition',
  'GMC Yukon VIP': 'fleet.gmc_yukon',
  'Cadillac Escalade Platinum': 'fleet.cadillac_escalade',
  'Ford Expedition Max': 'fleet.ford_expedition',
};

export default function Fleets() {
  const { t } = useTranslation();
  const carouselRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);

  const updateScrollButtons = () => {
    const el = carouselRef.current;
    if (!el) return;
    const tolerance = 2;
    setCanScrollLeft(el.scrollLeft > tolerance);
    setCanScrollRight(el.scrollLeft + el.clientWidth < el.scrollWidth - tolerance);
  };

  useEffect(() => {
    const el = carouselRef.current;
    if (!el) return;
    updateScrollButtons();
    el.addEventListener('scroll', updateScrollButtons);
    const observer = new ResizeObserver(updateScrollButtons);
    observer.observe(el);
    return () => {
      el.removeEventListener('scroll', updateScrollButtons);
      observer.disconnect();
    };
  }, []);

  const scrollBy = (direction: 'left' | 'right') => {
    if (!carouselRef.current) return;
    const card = carouselRef.current.querySelector<HTMLElement>('.fleet-card');
    if (!card) return;
    const scrollAmount = card.offsetWidth + 16;
    carouselRef.current.scrollBy({ left: direction === 'right' ? scrollAmount : -scrollAmount, behavior: 'smooth' });
  };

  return (
    <section className="fleets section-padding page-layout" id="fleets">
      <div className="container" style={{ position: 'relative' }}>
        <h2 className="section-title">{t('fleet.title')}</h2>
        <p className="fleets-subtitle">{t('fleet.subtitle')}</p>
      </div>
        
      <div className="fleets-carousel-wrapper">
          <div className="fleets-carousel" ref={carouselRef}>
            {[
              {
                name: 'GMC Yukon',
                img: '/GMC.webp',
                features: ['Three row SUV', '16-way power front seats with massage', 'Air ride adaptive suspension', '18-speaker performance series']
              },
              {
                name: 'Cadillac Escalade',
                img: '/cadillac.webp',
                features: ['55 inch curved oled dashboard', 'High-end audio system', 'Semi-aniline leather, wood accents', '16-way power adjustable massaging seats']
              },
              {
                name: 'Ford Expedition',
                img: '/ford.webp',
                features: ['24-inch panoramic display', 'Cargo tailgate manager', 'Accommodates 7 to 8 passenger', '3.5L Ecoboost, Twin-turbo v6']
              },
              {
                name: 'GMC Yukon VIP',
                img: '/GMC.webp',
                features: ['Three row SUV', '16-way power front seats with massage', 'Air ride adaptive suspension', '18-speaker performance series']
              },
              {
                name: 'Cadillac Escalade Platinum',
                img: '/cadillac.webp',
                features: ['55 inch curved oled dashboard', 'High-end audio system', 'Semi-aniline leather, wood accents', '16-way power adjustable massaging seats']
              },
              {
                name: 'Ford Expedition Max',
                img: '/ford.webp',
                features: ['24-inch panoramic display', 'Cargo tailgate manager', 'Accommodates 7 to 8 passenger', '3.5L Ecoboost, Twin-turbo v6']
              }
            ].map((car, idx) => (
              <div className="fleet-card" key={`${car.name}-${idx}`}>
                <div className="fleet-card-img">
                  <img src={car.img} alt={car.name} loading="lazy" />
                </div>
                <h3>{t(VEHICLE_NAMES[car.name] || car.name)}</h3>
                <div className="fleet-features">
                  <h4>{t('fleet.features')}:</h4>
                  <ul>
                    {car.features.map((f, i) => (
                      <li key={i}><CheckCircle2 size={16} fill="#F4C522" color="#000" /> {t(FEATURE_KEYS[f] || f)}</li>
                    ))}
                  </ul>
                </div>
                <Link to={`/book?vehicle=${car.name}`} className="fleet-book-btn" style={{ textDecoration: 'none', display: 'block', textAlign: 'center' }}>{t('fleet.book_now')}</Link>
              </div>
            ))}
          </div>
          {canScrollLeft && (
            <button className="fleet-scroll-btn fleet-scroll-btn--left" onClick={() => scrollBy('left')} aria-label="Scroll fleet left">
              <ChevronLeft size={28} />
            </button>
          )}
          {canScrollRight && (
            <button className="fleet-scroll-btn fleet-scroll-btn--right" onClick={() => scrollBy('right')} aria-label="Scroll fleet right">
              <ChevronRight size={28} />
            </button>
          )}
        </div>
    </section>
  );
}
