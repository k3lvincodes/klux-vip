import { useEffect, useRef, useState } from 'react';
import { CheckCircle2, ChevronLeft, ChevronRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';

interface FleetCar {
  id: string;
  make: string;
  model: string;
  year: number;
  image_url: string | null;
  features: string | null;
}

export default function Fleets() {
  const { t } = useTranslation();
  const carouselRef = useRef<HTMLDivElement>(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(true);
  const [fleetCars, setFleetCars] = useState<FleetCar[]>([]);

  useEffect(() => {
    const fetchFeatured = async () => {
      const { data } = await supabase
        .from('fleet_cars')
        .select('id, make, model, year, image_url, features')
        .eq('is_featured', true)
        .is('deleted_at', null)
        .order('created_at', { ascending: false });

      if (data && data.length > 0) {
        setFleetCars(data);
      }
    };
    fetchFeatured();
  }, []);

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
  }, [fleetCars]);

  const scrollBy = (direction: 'left' | 'right') => {
    if (!carouselRef.current) return;
    const card = carouselRef.current.querySelector<HTMLElement>('.fleet-card');
    if (!card) return;
    const scrollAmount = card.offsetWidth + 16;
    carouselRef.current.scrollBy({ left: direction === 'right' ? scrollAmount : -scrollAmount, behavior: 'smooth' });
  };

  if (fleetCars.length === 0) return null;

  return (
    <section className="fleets section-padding page-layout" id="fleets">
      <div className="container" style={{ position: 'relative' }}>
        <h2 className="section-title">{t('fleet.title')}</h2>
        <p className="fleets-subtitle">{t('fleet.subtitle')}</p>
      </div>
        
      <div className="fleets-carousel-wrapper">
          <div className="fleets-carousel" ref={carouselRef}>
            {fleetCars.map((car) => {
              const featureLines = car.features
                ? car.features.split('\n').filter((f) => f.trim())
                : [];
              return (
                <div className="fleet-card" key={car.id}>
                  <div className="fleet-card-img">
                    {car.image_url ? (
                      <img src={car.image_url} alt={`${car.year} ${car.make} ${car.model}`} loading="lazy" />
                    ) : (
                      <div style={{ width: '100%', height: '100%', background: '#27272a', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#71717a', fontSize: '14px' }}>
                        {car.make} {car.model}
                      </div>
                    )}
                  </div>
                  <h3>{car.make} {car.model}</h3>
                  {featureLines.length > 0 && (
                    <div className="fleet-features">
                      <h4>{t('fleet.features')}:</h4>
                      <ul>
                        {featureLines.map((f, i) => (
                          <li key={i}><CheckCircle2 size={16} fill="#F4C522" color="#000" /> {f}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  <Link to={`/book?vehicle=${car.make} ${car.model}`} className="fleet-book-btn" style={{ textDecoration: 'none', display: 'block', textAlign: 'center' }}>{t('fleet.book_now')}</Link>
                </div>
              );
            })}
          </div>
          {fleetCars.length > 1 && canScrollLeft && (
            <button className="fleet-scroll-btn fleet-scroll-btn--left" onClick={() => scrollBy('left')} aria-label="Scroll fleet left">
              <ChevronLeft size={28} />
            </button>
          )}
          {fleetCars.length > 1 && canScrollRight && (
            <button className="fleet-scroll-btn fleet-scroll-btn--right" onClick={() => scrollBy('right')} aria-label="Scroll fleet right">
              <ChevronRight size={28} />
            </button>
          )}
        </div>
    </section>
  );
}
