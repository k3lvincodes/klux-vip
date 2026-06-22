import { useRef, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ChevronRight, ChevronLeft, Star, User } from 'lucide-react';

export default function Testimonials() {
  const { t } = useTranslation();
  const testCarouselRef = useRef<HTMLDivElement>(null);

  const testimonialCount = useMemo(() => {
    let count = 0;
    for (let i = 1; i <= 20; i++) {
      const name = t(`testimonials.t${i}_name`);
      if (name && !name.startsWith('testimonials.t')) count++;
      else break;
    }
    return Math.max(count, 1);
  }, [t]);

  const scrollTestLeft = () => {
    if (testCarouselRef.current) {
      testCarouselRef.current.scrollBy({ left: -420, behavior: 'smooth' });
    }
  };

  const scrollTestRight = () => {
    if (testCarouselRef.current) {
      testCarouselRef.current.scrollBy({ left: 420, behavior: 'smooth' });
    }
  };

  return (
    <section className="testimonials section-padding page-layout" id="testimonials">
      <div className="testimonials-header">
        <h2 className="section-title">{t('testimonials.title')}</h2>
      </div>
      <div className="testimonials-content">
        <div className="test-cards" ref={testCarouselRef}>
          {Array.from({ length: testimonialCount }, (_, i) => i + 1).map((i) => (
            <div className="test-card" key={i}>
              <div className="test-card-avatar">
                 <User size={60} color="#1c1c1c" fill="#1c1c1c" />
              </div>
              <h4>{t(`testimonials.t${i}_name`)}</h4>
              <p>{t(`testimonials.t${i}_text`)}</p>
              <div className="test-stars">
                {[...Array(5)].map((_, idx) => (
                  <Star key={idx} fill="#F4C522" stroke="none" size={26} />
                ))}
              </div>
            </div>
          ))}
        </div>
        <div className="container">
          <div className="test-nav">
            <button className="test-nav-btn" onClick={scrollTestLeft}><ChevronLeft size={24} color="#000" /></button>
            <button className="test-nav-btn" onClick={scrollTestRight}><ChevronRight size={24} color="#000" /></button>
          </div>
        </div>
      </div>
    </section>
  );
}
