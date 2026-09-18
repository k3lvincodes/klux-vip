import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Star, X, CheckCircle2, Sparkles, Send } from 'lucide-react';
import { supabase } from '../../lib/supabase';

export interface UserReview {
  id: string;
  name: string;
  text: string;
  rating: number;
  service?: string;
  date: string;
  isUserSubmitted: boolean;
}

interface LeaveReviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (review: UserReview) => void;
}

const SERVICE_OPTIONS = [
  'Executive Chauffeur',
  'Airport Transfer',
  'VIP & Gala Event',
  'Wedding Transport',
  'Corporate Travel',
  'Hourly Luxury Charter',
];

const RATING_LABELS: Record<number, string> = {
  1: 'Poor Experience',
  2: 'Fair Experience',
  3: 'Good Experience',
  4: 'Very Good Service',
  5: 'Exceptional Luxury Experience',
};

export default function LeaveReviewModal({ isOpen, onClose, onSubmit }: LeaveReviewModalProps) {
  const { t } = useTranslation();
  const [rating, setRating] = useState<number>(5);
  const [hoverRating, setHoverRating] = useState<number | null>(null);
  const [name, setName] = useState('');
  const [service, setService] = useState('Executive Chauffeur');
  const [text, setText] = useState('');
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);

  if (!isOpen) return null;

  const currentDisplayRating = hoverRating !== null ? hoverRating : rating;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    const trimmedName = name.trim();
    const trimmedText = text.trim();

    if (!trimmedName || trimmedName.length < 2) {
      setError(t('testimonials.error_name', 'Please provide your name (at least 2 characters).'));
      return;
    }

    if (!trimmedText || trimmedText.length < 10) {
      setError(t('testimonials.error_text', 'Please write a review with at least 10 characters.'));
      return;
    }

    setIsSubmitting(true);

    const newReview: UserReview = {
      id: `rev-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      name: trimmedName.toUpperCase(),
      text: trimmedText,
      rating,
      service,
      date: new Date().toLocaleDateString('en-US', { month: 'short', year: 'numeric' }),
      isUserSubmitted: true,
    };

    // Save locally
    try {
      const stored = localStorage.getItem('kenick_user_reviews');
      const existingReviews: UserReview[] = stored ? JSON.parse(stored) : [];
      localStorage.setItem('kenick_user_reviews', JSON.stringify([newReview, ...existingReviews]));
    } catch {
      // localStorage fallback ignore
    }

    // Attempt optional Supabase persist in client_reviews or contact_submissions
    try {
      await supabase.from('client_reviews').insert({
        name: trimmedName,
        rating,
        service_type: service,
        review_text: trimmedText,
        email: email.trim() || null,
        created_at: new Date().toISOString(),
      });
    } catch {
      // Ignore if table or policy does not exist, local copy is already saved
    }

    setIsSubmitting(false);
    setIsSubmitted(true);
    onSubmit(newReview);
  };

  const handleResetAndClose = () => {
    setName('');
    setText('');
    setEmail('');
    setRating(5);
    setError('');
    setIsSubmitted(false);
    onClose();
  };

  return (
    <div className="review-modal-backdrop" onClick={handleResetAndClose}>
      <div
        className="review-modal-container"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-labelledby="review-modal-title"
      >
        <button
          className="review-modal-close-btn"
          onClick={handleResetAndClose}
          aria-label="Close modal"
        >
          <X size={20} />
        </button>

        {!isSubmitted ? (
          <div>
            <div className="review-modal-header">
              <div className="review-modal-badge">
                <Sparkles size={14} />
                <span>{t('testimonials.badge_share', 'Client Review')}</span>
              </div>
              <h3 id="review-modal-title" className="review-modal-title">
                {t('testimonials.modal_title', 'Share Your Experience')}
              </h3>
              <p className="review-modal-subtitle">
                {t(
                  'testimonials.modal_subtitle',
                  'Tell us about your ride with Kenick VIP. Your feedback helps us maintain the highest standard of luxury.'
                )}
              </p>
            </div>

            <form onSubmit={handleSubmit} className="review-modal-form">
              {error && <div className="review-form-error">{error}</div>}

              {/* Interactive Star Rating */}
              <div className="review-rating-group">
                <label className="review-field-label">
                  {t('testimonials.rating_label', 'Your Rating')}
                </label>
                <div
                  className="review-star-selector"
                  onMouseLeave={() => setHoverRating(null)}
                >
                  {[1, 2, 3, 4, 5].map((starVal) => {
                    const isFilled = starVal <= currentDisplayRating;
                    return (
                      <button
                        type="button"
                        key={starVal}
                        className={`star-select-btn ${isFilled ? 'star-select-btn--active' : ''}`}
                        onClick={() => setRating(starVal)}
                        onMouseEnter={() => setHoverRating(starVal)}
                        aria-label={`${starVal} Star${starVal > 1 ? 's' : ''}`}
                      >
                        <Star
                          size={28}
                          fill={isFilled ? '#F4C522' : 'transparent'}
                          stroke={isFilled ? '#F4C522' : '#888'}
                          strokeWidth={1.5}
                        />
                      </button>
                    );
                  })}
                </div>
                <div className="rating-descriptor">
                  {RATING_LABELS[currentDisplayRating] || `${currentDisplayRating} / 5`}
                </div>
              </div>

              {/* Name & Email Row */}
              <div className="review-form-row">
                <div className="review-field">
                  <label htmlFor="review-name" className="review-field-label">
                    {t('testimonials.name_label', 'Your Name')} <span className="req">*</span>
                  </label>
                  <input
                    id="review-name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="e.g. David Joe"
                    maxLength={60}
                    className="review-input"
                    required
                  />
                </div>

                <div className="review-field">
                  <label htmlFor="review-email" className="review-field-label">
                    {t('testimonials.email_label', 'Email (Optional)')}
                  </label>
                  <input
                    id="review-email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="name@example.com"
                    className="review-input"
                  />
                </div>
              </div>

              {/* Service Selection */}
              <div className="review-field">
                <label className="review-field-label">
                  {t('testimonials.service_label', 'Service Experience')}
                </label>
                <div className="review-service-chips">
                  {SERVICE_OPTIONS.map((opt) => (
                    <button
                      type="button"
                      key={opt}
                      className={`service-chip ${service === opt ? 'service-chip--active' : ''}`}
                      onClick={() => setService(opt)}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              </div>

              {/* Review Text */}
              <div className="review-field">
                <div className="review-field-header">
                  <label htmlFor="review-text" className="review-field-label">
                    {t('testimonials.review_label', 'Your Review')} <span className="req">*</span>
                  </label>
                  <span className="char-count">{text.length} / 500</span>
                </div>
                <textarea
                  id="review-text"
                  rows={4}
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  placeholder={t(
                    'testimonials.review_placeholder',
                    'How was the comfort, chauffeur punctuality, and overall VIP journey?'
                  )}
                  maxLength={500}
                  className="review-textarea"
                  required
                />
              </div>

              {/* Submit Buttons */}
              <div className="review-modal-actions">
                <button
                  type="button"
                  onClick={handleResetAndClose}
                  className="review-btn-cancel"
                  disabled={isSubmitting}
                >
                  {t('common.cancel', 'Cancel')}
                </button>
                <button
                  type="submit"
                  className="review-btn-submit"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? (
                    <span className="spinner-inline" />
                  ) : (
                    <>
                      <Send size={16} />
                      <span>{t('testimonials.submit_btn', 'Post Review')}</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        ) : (
          <div className="review-success-state">
            <div className="success-icon-wrap">
              <CheckCircle2 size={54} color="#F4C522" />
            </div>
            <h3 className="success-title">
              {t('testimonials.success_title', 'Thank You for Your Review!')}
            </h3>
            <p className="success-text">
              {t(
                'testimonials.success_desc',
                'Your feedback has been added to our client experiences. We appreciate you choosing Kenick VIP.'
              )}
            </p>
            <button className="review-btn-submit success-btn" onClick={handleResetAndClose}>
              {t('testimonials.view_review', 'View in Testimonials')}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
