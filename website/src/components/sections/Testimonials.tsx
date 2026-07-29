import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ChevronLeft, ChevronRight, User, Star } from 'lucide-react';

export default function Testimonials() {
  const { t } = useTranslation();
  const [page, setPage] = useState(0);

  const allTestimonials: { name: string; text: string }[] = [];
  for (let i = 1; i <= 20; i++) {
    const name = t(`testimonials.t${i}_name`);
    if (name && !name.startsWith('testimonials.t')) {
      allTestimonials.push({ name, text: t(`testimonials.t${i}_text`) });
    } else break;
  }

  const maxPage = Math.max(0, allTestimonials.length - 3);
  const visible = allTestimonials.slice(page, page + 3);

  const prev = () => setPage((p) => Math.max(0, p - 1));
  const next = () => setPage((p) => Math.min(maxPage, p + 1));

  return (
    <section className="testimonials page-layout" id="testimonials">
      <div className="testimonials-overlay" />
      <div className="container">
        <div className="testimonials-header">
          <h2 className="testimonials-title">{t('testimonials.title')}</h2>
          <p className="testimonials-subtitle">{t('testimonials.subtitle')}</p>
        </div>
        <div className="testimonials-cards">
          {visible.map((item, idx) => (
            <div className={`test-card${idx === 1 ? ' test-card--active' : ''}`} key={page + idx}>
              <div className="test-card-avatar">
                <User size={48} color="#aaa" />
              </div>
              <h4 className="test-card-name">{item.name}</h4>
              <p className="test-card-text">{item.text}</p>
              <div className="test-card-stars">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} size={20} fill="#F4C522" stroke="none" />
                ))}
              </div>
            </div>
          ))}
        </div>
        <div className="testimonials-nav">
          <button className="test-nav-btn" onClick={prev} disabled={page === 0}>
            <ChevronLeft size={22} />
          </button>
          <button className="test-nav-btn" onClick={next} disabled={page >= maxPage}>
            <ChevronRight size={22} />
          </button>
        </div>
      </div>
    </section>
  );
}
