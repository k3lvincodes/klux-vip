import { useState } from 'react';
import { CheckCircle2, Send, MapPin, Phone, Mail } from 'lucide-react';

export default function Contact() {
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
        <h2 className="section-title">Get in touch</h2>
        <p className="contact-subtitle">Have a question or want to book a premium ride? Send us a message and we'll get back to you shortly.</p>
        <div className="contact-layout">
          <div className="contact-info">
            <div className="contact-info-card">
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <MapPin size={24} />
                </div>
                <div>
                  <h4>Our Office</h4>
                  <p>125 W South St<br />Indianapolis, Indiana, 46206</p>
                </div>
              </div>
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <Phone size={24} />
                </div>
                <div>
                  <h4>Phone</h4>
                  <p>+1260-210-3519</p>
                </div>
              </div>
              <div className="contact-info-item">
                <div className="contact-info-icon">
                  <Mail size={24} />
                </div>
                <div>
                  <h4>Email</h4>
                  <p>booking@kenicktransportation.com</p>
                </div>
              </div>
            </div>
            <div className="contact-hours">
              <h4>Business Hours</h4>
              <p>Monday – Friday: 6:00 AM – 11:00 PM</p>
              <p>Saturday – Sunday: 7:00 AM – 10:00 PM</p>
            </div>
          </div>

          <form className="contact-form" onSubmit={handleContactSubmit}>
            {submitSuccess && (
              <div className="contact-success">
                <CheckCircle2 size={20} />
                Message sent successfully! We'll be in touch soon.
              </div>
            )}
            <div className="contact-form-row">
              <div className="contact-field">
                <label htmlFor="contact-name">Full Name</label>
                <input
                  id="contact-name"
                  type="text"
                  name="name"
                  placeholder="John Doe"
                  value={contactForm.name}
                  onChange={handleContactChange}
                  required
                />
              </div>
              <div className="contact-field">
                <label htmlFor="contact-email">Email</label>
                <input
                  id="contact-email"
                  type="email"
                  name="email"
                  placeholder="john@example.com"
                  value={contactForm.email}
                  onChange={handleContactChange}
                  required
                />
              </div>
            </div>
            <div className="contact-field">
              <label htmlFor="contact-subject">Subject</label>
              <input
                id="contact-subject"
                type="text"
                name="subject"
                placeholder="How can we help?"
                value={contactForm.subject}
                onChange={handleContactChange}
                required
              />
            </div>
            <div className="contact-field">
              <label htmlFor="contact-message">Message</label>
              <textarea
                id="contact-message"
                name="message"
                rows={5}
                placeholder="Tell us more about your inquiry..."
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
                  Send Message
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
