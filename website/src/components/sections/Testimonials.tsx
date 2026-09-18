import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { ChevronLeft, ChevronRight, User, Star, PenLine, Sparkles } from 'lucide-react';
import LeaveReviewModal, { type UserReview } from './LeaveReviewModal';
import { supabase } from '../../lib/supabase';

export default function Testimonials() {
  const { t } = useTranslation();
  const [page, setPage] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [userReviews, setUserReviews] = useState<UserReview[]>([]);
  const [cardsPerPage, setCardsPerPage] = useState(3);

  // Responsive cards per page calculation
  useEffect(() => {
    const handleResize = () => {
      if (window.innerWidth < 768) {
        setCardsPerPage(1);
      } else if (window.innerWidth < 1024) {
        setCardsPerPage(2);
      } else {
        setCardsPerPage(3);
      }
    };
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  // Load approved reviews from Supabase
  useEffect(() => {
    const fetchReviews = async () => {
      try {
        const { data, error } = await supabase
          .from('client_reviews')
          .select('id, name, rating, service_type, review_text, created_at')
          .eq('status', 'approved')
          .order('created_at', { ascending: false })
          .limit(50);

        if (error || !data) return;

        const mapped: UserReview[] = data.map((row) => ({
          id: row.id,
          name: row.name.toUpperCase(),
          text: row.review_text,
          rating: row.rating,
          service: row.service_type ?? undefined,
          date: new Date(row.created_at).toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
          isUserSubmitted: true,
        }));

        setUserReviews(mapped);
      } catch {
        // silently ignore network errors — default testimonials still show
      }
    };

    fetchReviews();
  }, []);

  // Built-in default testimonials from translations
  const defaultTestimonials: UserReview[] = [];
  for (let i = 1; i <= 20; i++) {
    const name = t(`testimonials.t${i}_name`);
    if (name && !name.startsWith('testimonials.t')) {
      defaultTestimonials.push({
        id: `default-${i}`,
        name,
        text: t(`testimonials.t${i}_text`),
        rating: 5,
        service: i % 2 === 0 ? 'Airport Transfer' : 'Executive Chauffeur',
        date: 'Verified Client',
        isUserSubmitted: false,
      });
    } else break;
  }

  // Combine user-submitted reviews first, then default testimonials
  const allTestimonials: UserReview[] = [...userReviews, ...defaultTestimonials];

  const maxPage = Math.max(0, allTestimonials.length - cardsPerPage);
  const visible = allTestimonials.slice(page, page + cardsPerPage);

  const prev = () => setPage((p) => Math.max(0, p - 1));
  const next = () => setPage((p) => Math.min(maxPage, p + 1));

  const handleNewReview = (newReview: UserReview) => {
    setUserReviews((prev) => [newReview, ...prev]);
    setPage(0); // Immediately jump to page 0 to see the newly submitted review!
  };

  const getInitials = (fullName: string) => {
    const parts = fullName.trim().split(/\s+/);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  };

  return (
    <section className="testimonials page-layout" id="testimonials">
      <div className="testimonials-overlay" />
      <div className="container">
        {/* Testimonials Section Header */}
        <div className="testimonials-header">
          <div className="testimonials-rating-pill">
            <Sparkles size={14} color="#F4C522" />
            <span>4.9 / 5 Rating • 250+ Verified Client Reviews</span>
          </div>

          <h2 className="testimonials-title">{t('testimonials.title')}</h2>
          <p className="testimonials-subtitle">{t('testimonials.subtitle')}</p>

          <div className="testimonials-action-wrap">
            <button
              className="leave-review-btn"
              onClick={() => setIsModalOpen(true)}
              aria-label="Write a review"
            >
              <PenLine size={16} />
              <span>{t('testimonials.leave_review_btn', 'Leave a Review')}</span>
            </button>
          </div>
        </div>

        {/* Testimonials Cards Grid */}
        <div className="testimonials-cards">
          {visible.map((item, idx) => {
            const isCenterActive = cardsPerPage === 3 ? idx === 1 : idx === 0;
            const initials = getInitials(item.name);

            return (
              <div
                className={`test-card${isCenterActive ? ' test-card--active' : ''}${
                  item.isUserSubmitted ? ' test-card--user' : ''
                }`}
                key={item.id || `${page}-${idx}`}
              >
                {item.service && (
                  <span className="test-card-service-badge">{item.service}</span>
                )}

                <div className="test-card-avatar">
                  {item.isUserSubmitted ? (
                    <span className="test-avatar-initials">{initials}</span>
                  ) : (
                    <User size={44} color="#888" />
                  )}
                </div>

                <h4 className="test-card-name">{item.name}</h4>

                {item.isUserSubmitted && (
                  <span className="test-verified-pill">
                    <Star size={11} fill="#F4C522" stroke="none" />
                    Verified Reviewer
                  </span>
                )}

                <p className="test-card-text">{item.text}</p>

                <div className="test-card-stars">
                  {[...Array(5)].map((_, i) => {
                    const filled = i < (item.rating || 5);
                    return (
                      <Star
                        key={i}
                        size={18}
                        fill={filled ? '#F4C522' : '#e0e0e0'}
                        stroke="none"
                      />
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        {/* Carousel Navigation & Counter */}
        <div className="testimonials-nav-container">
          <button
            className="test-nav-btn"
            onClick={prev}
            disabled={page === 0}
            aria-label="Previous testimonial"
          >
            <ChevronLeft size={22} />
          </button>

          <div className="testimonials-page-indicator">
            <span>
              {page + 1} / {Math.max(1, maxPage + 1)}
            </span>
          </div>

          <button
            className="test-nav-btn"
            onClick={next}
            disabled={page >= maxPage}
            aria-label="Next testimonial"
          >
            <ChevronRight size={22} />
          </button>
        </div>

        {/* Bottom invitation card */}
        <div className="testimonials-invite-banner">
          <div className="invite-banner-text">
            <h4>{t('testimonials.invite_title', 'Have you traveled with Kenick VIP?')}</h4>
            <p>
              {t(
                'testimonials.invite_subtitle',
                'Your luxury experience and impressions matter to us. Share your thoughts with future clients.'
              )}
            </p>
          </div>
          <button
            className="invite-banner-btn"
            onClick={() => setIsModalOpen(true)}
          >
            <PenLine size={15} />
            <span>{t('testimonials.leave_review_btn', 'Write a Review')}</span>
          </button>
        </div>
      </div>

      {/* Review Modal Form */}
      <LeaveReviewModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onSubmit={handleNewReview}
      />
    </section>
  );
}
