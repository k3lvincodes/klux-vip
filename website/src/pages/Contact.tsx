import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { CheckCircle2, Send, MapPin, Phone, Mail } from 'lucide-react';

export default function Contact() {
  const { t } = useTranslation();
  const [contactForm, setContactForm] = useState({ name: '', email: '', subject: '', message: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const handleContactChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setContactForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleContactSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    await new Promise(resolve => setTimeout(resolve, 1500));
    setIsSubmitting(false);
    setSubmitSuccess(true);
    setContactForm({ name: '', email: '', subject: '', message: '' });
    setTimeout(() => setSubmitSuccess(false), 4000);
  };

  return (
    <section className="contact-section section-padding page-layout" id="contact">
      <div className="container">
        <h2 className="section-title">{t('contact.get_in_touch')}</h2>
        <p className="contact-subtitle">{t('contact.subtitle')}</p>
        <div className="contact-layout">
          <div className="contact-info">
            <div className="contact-info-card">
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <MapPin size={24} />
                </div>
                <div>
                  <h4>{t('contact.our_address')}</h4>
                  <p dangerouslySetInnerHTML={{ __html: (t('contact.address') as string).replace(', ', '<br />') }} />
                </div>
              </div>
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <Phone size={24} />
                </div>
                <div>
                  <h4>{t('contact.call_us')}</h4>
                  <p>+1 260-210-3519</p>
                </div>
              </div>
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <Mail size={24} />
                </div>
                <div>
                  <h4>{t('contact.email_us')}</h4>
                  <p>booking@kenicktransportation.com</p>
                </div>
              </div>
            </div>
            <div className="contact-hours">
              <h4>{t('contact.title')}</h4>
              <p>Monday – Friday: 6:00 AM – 11:00 PM</p>
              <p>Saturday – Sunday: 7:00 AM – 10:00 PM</p>
            </div>
          </div>

          <form className="contact-form" onSubmit={handleContactSubmit}>
            {submitSuccess && (
              <div className="contact-success">
                <CheckCircle2 size={20} />
                {t('contact.message_sent')}
              </div>
            )}
            <div className="contact-form-row">
              <div className="contact-field">
                <label htmlFor="contact-name">{t('contact.name')}</label>
                <input
                  id="contact-name"
                  type="text"
                  name="name"
                  placeholder={t('contact.name')}
                  value={contactForm.name}
                  onChange={handleContactChange}
                  required
                />
              </div>
              <div className="contact-field">
                <label htmlFor="contact-email">{t('contact.email')}</label>
                <input
                  id="contact-email"
                  type="email"
                  name="email"
                  placeholder={t('contact.email')}
                  value={contactForm.email}
                  onChange={handleContactChange}
                  required
                />
              </div>
            </div>
            <div className="contact-field">
              <label htmlFor="contact-subject">{t('contact.name')}</label>
              <input
                id="contact-subject"
                type="text"
                name="subject"
                placeholder={t('contact.name')}
                value={contactForm.subject}
                onChange={handleContactChange}
                required
              />
            </div>
            <div className="contact-field">
              <label htmlFor="contact-message">{t('contact.message')}</label>
              <textarea
                id="contact-message"
                name="message"
                rows={5}
                placeholder={t('contact.message_placeholder')}
                value={contactForm.message}
                onChange={handleContactChange}
                required
              />
            </div>
            <button type="submit" className="contact-submit-btn" disabled={isSubmitting}>
              {isSubmitting ? (
                <span className="contact-spinner" />
              ) : (
                <>
                  {t('contact.send_message')}
                  <Send size={18} />
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </section>
  );
}
