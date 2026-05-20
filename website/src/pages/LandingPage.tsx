import { useRef, useState, useEffect } from 'react';
import {
  ChevronRight, AlignRight, CheckCircle2,
  ChevronLeft, Star, User, X,
  Send, MapPin, Phone, Mail
} from 'lucide-react';
import '../App.css';

export default function LandingPage() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const testCarouselRef = useRef<HTMLDivElement>(null);
  const [contactForm, setContactForm] = useState({ name: '', email: '', subject: '', message: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

  useEffect(() => {
    if (isMenuOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isMenuOpen]);

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

  const handleContactChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setContactForm(prev => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleContactSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    // Simulate sending
    await new Promise(resolve => setTimeout(resolve, 1500));
    setIsSubmitting(false);
    setSubmitSuccess(true);
    setContactForm({ name: '', email: '', subject: '', message: '' });
    setTimeout(() => setSubmitSuccess(false), 4000);
  };

  return (
    <>
      {/* ====== FULLSCREEN MENU ====== */}
      <div className={`fullscreen-menu ${isMenuOpen ? 'open' : ''}`}>
        <button className="close-menu-btn" onClick={() => setIsMenuOpen(false)}>
          <X size={40} />
        </button>
        <div className="menu-content">
          <ul className="menu-links">
            {['Home', 'How it works', 'Fleets', 'Services', 'About us', 'Testimonials', 'Contact'].map((item) => (
              <li key={item}>
                <a href={`#${item.toLowerCase().replace(/ /g, '-')}`} onClick={() => setIsMenuOpen(false)}>
                  {item}
                </a>
              </li>
            ))}
          </ul>
          <div className="menu-footer">
            <button className="nav-cta menu-cta">Get the app</button>
          </div>
        </div>
      </div>

      {/* ====== SECTION 1: HERO ====== */}
      <section className="hero-wrapper" id="home">
        {/* Navbar */}
        <nav className="navbar">
          <div className="navbar-inner">
            <div className="nav-logo">
              <div className="nav-logo-icon">
                <img src="/Kenick-logo-favicon.png" alt="Kenick Logo" style={{ width: '100%', height: '100%', objectFit: 'contain', borderRadius: '10px' }} />
              </div>
              Kenick
            </div>
            <div className="nav-right">
              <div className="nav-lang">
                <img src="https://flagcdn.com/w40/us.png" alt="US" />
                <span>En</span>
              </div>
              <button className="nav-cta">Get the app</button>
              <button className="nav-menu-btn" onClick={() => setIsMenuOpen(true)}>
                <AlignRight size={26} />
              </button>
            </div>
          </div>
        </nav>

        {/* Hero Content */}
        <div className="hero-content">
          <div className="hero-text">
            <h1 className="hero-headline">
              <span className="hero-headline-highlight">Your Premium Black Car</span>
              <span style={{ display: 'block', marginTop: '20px' }}>
                Experience On
                <br />
                Demand
              </span>
            </h1>
            <button className="hero-book-btn">Book a ride</button>
            <div className="hero-badges">
              <button className="store-badge">
                <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" />
              </button>
              <button className="store-badge">
                <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Google Play" />
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ====== SECTION 2: HOW IT WORKS ====== */}
      <section className="how-it-works section-padding" id="how-it-works">
        <div className="container">
          <div className="hiw-layout">
            {/* Left: Tree diagram */}
            <div className="hiw-tree">
              {/* SVG connector lines */}
              <svg className="hiw-lines" viewBox="0 0 600 680" fill="none" xmlns="http://www.w3.org/2000/svg">
                {/* Vertical trunk (placed at x=120, exact horizontal center of the big circle) */}
                <line x1="120" y1="70" x2="120" y2="560" stroke="#222" strokeWidth="2.5" />
                {/* Branch to step 1 */}
                <line x1="120" y1="70" x2="370" y2="70" stroke="#222" strokeWidth="2.5" />
                {/* Branch to step 2 (longest) */}
                <line x1="120" y1="340" x2="460" y2="340" stroke="#222" strokeWidth="2.5" />
                {/* Branch to step 3 */}
                <line x1="120" y1="560" x2="370" y2="560" stroke="#222" strokeWidth="2.5" />
              </svg>

              {/* Big circle */}
              <div className="hiw-big-circle">
                <h2>How it<br />works</h2>
              </div>

              {/* Step 1 - top */}
              <div className="hiw-step hiw-step-1">
                <div className="hiw-step-icon">
                  <img src="/ride choose.png" alt="Choose ride type" />
                </div>
                <p className="hiw-step-label">1. Choose ride type</p>
              </div>

              {/* Step 2 - middle */}
              <div className="hiw-step hiw-step-2">
                <div className="hiw-step-icon">
                  <img src="/location search.png" alt="Set pick up" />
                </div>
                <p className="hiw-step-label">2. Set pick up and<br />drop off details</p>
              </div>

              {/* Step 3 - bottom */}
              <div className="hiw-step hiw-step-3">
                <div className="hiw-step-icon">
                  <img src="/confirm.png" alt="Confirm booking" />
                </div>
                <p className="hiw-step-label">3. Confirm booking</p>
              </div>
            </div>

            {/* Right: Phone mockup */}
            <div className="hiw-phone">
              <img src="/Payment successful Mockup.png" alt="Payment successful phone mockup" className="hiw-phone-img" />
            </div>
          </div>
        </div>
      </section>

      {/* ====== SECTION 3: FLEETS ====== */}
      <section className="fleets section-padding" id="fleets">
        <div className="container" style={{ position: 'relative' }}>
          <h2 className="section-title">Fleets</h2>
          <p className="fleets-subtitle">Our latest premium black cars and features</p>
        </div>
          
        <div className="fleets-carousel-wrapper">
            <div className="fleets-carousel">
              {[
                {
                  name: 'GMC Yukon',
                  img: '/GMC.png',
                  features: ['Three row SUV', '16-way power front seats with massage', 'Air ride adaptive suspension', '18-speaker performance series']
                },
                {
                  name: 'Cadillac Escalade',
                  img: '/cadillac.png',
                  features: ['55 inch curved oled dashboard', 'High-end audio system', 'Semi-aniline leather, wood accents', '16-way power adjustable massaging seats']
                },
                {
                  name: 'Ford Expedition',
                  img: '/ford.png',
                  features: ['24-inch panoramic display', 'Cargo tailgate manager', 'Accommodates 7 to 8 passenger', '3.5L Ecoboost, Twin-turbo v6']
                },
                // Duplicate for carousel effect
                {
                  name: 'GMC Yukon VIP',
                  img: '/GMC.png',
                  features: ['Three row SUV', '16-way power front seats with massage', 'Air ride adaptive suspension', '18-speaker performance series']
                },
                {
                  name: 'Cadillac Escalade Platinum',
                  img: '/cadillac.png',
                  features: ['55 inch curved oled dashboard', 'High-end audio system', 'Semi-aniline leather, wood accents', '16-way power adjustable massaging seats']
                },
                {
                  name: 'Ford Expedition Max',
                  img: '/ford.png',
                  features: ['24-inch panoramic display', 'Cargo tailgate manager', 'Accommodates 7 to 8 passenger', '3.5L Ecoboost, Twin-turbo v6']
                }
              ].map((car, idx) => (
                <div className="fleet-card" key={`${car.name}-${idx}`}>
                  <div className="fleet-card-img">
                    <img src={car.img} alt={car.name} />
                  </div>
                  <h3>{car.name}</h3>
                  <div className="fleet-features">
                    <h4>Features:</h4>
                    <ul>
                      {car.features.map((f, i) => (
                        <li key={i}><CheckCircle2 size={16} fill="#F4C522" color="#000" /> {f}</li>
                      ))}
                    </ul>
                  </div>
                  <button className="fleet-book-btn">Book now</button>
                </div>
              ))}
            </div>
          </div>
      </section>

      {/* ====== SECTION 4: SERVICES ====== */}
      <section className="services section-padding" id="services">
        <div className="services-bg-circle-1" />
        <div className="services-bg-circle-2" />
        <div className="container">
          <h2 className="section-title">Our services</h2>
          <div className="services-grid">
            {[
              { title: 'Airport transfers', desc: 'Enjoy a seamless transition from the tarmac to your final destination.', img: '/airport image.png' },
              { title: 'Corporate travel', desc: 'Designed for business professionals. Our corporate travel service offers reliability, comfort, and privacy.', img: '/copoorate image.png' },
              { title: 'Wedding & events', desc: 'Make your special day unforgettable with our luxury SUV transportation.', img: '/event image.png' },
              { title: 'Group & VIP transport', desc: "Streamline your team's travel with our executive group transfer services.", img: '/group transport image.png' },
            ].map((s) => (
              <div className="service-card" key={s.title}>
                <div className="service-card-img"><img src={s.img} alt={s.title} /></div>
                <div className="service-card-body">
                  <h3>{s.title}</h3>
                  <p>{s.desc}</p>
                </div>
              </div>
            ))}
          </div>
          <div className="services-cta">
            <button className="btn btn-dark services-learn-btn">Learn more</button>
          </div>
        </div>
      </section>

      {/* ====== SECTION 4.5: ABOUT US ====== */}
      <section className="about-us section-padding" id="about-us">
        <div className="container">
          <div className="about-text" style={{ textAlign: 'center', maxWidth: '800px', margin: '0 auto' }}>
            <h2 className="section-title" style={{ marginBottom: '1.5rem' }}>About us</h2>
            <p>
              Experience the pinnacle of luxury and reliability with Kenick. 
              We are dedicated to providing premium black car services for your 
              most important journeys, ensuring comfort, safety, and punctuality 
              every step of the way.
            </p>
          </div>
        </div>
      </section>

      {/* ====== SECTION 5: WHY CHOOSE US ====== */}
      <section className="why-choose section-padding" id="why-choose-us">
        <div className="container">
          <h2 className="section-title" style={{ color: '#fff' }}>Why choose us</h2>
          <div className="wcu-card">
            <div className="wcu-grid">
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> Professional chauffeurs</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> Real-time and scheduled books</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> Premium vehicle only</div>
              <div className="wcu-item"><CheckCircle2 size={24} strokeWidth={1.5} /> 24/7 customer service</div>
              <div className="wcu-item wcu-item-full"><CheckCircle2 size={24} strokeWidth={1.5} /> Secure and transparent pricing</div>
            </div>
          </div>
        </div>
      </section>

      {/* ====== SECTION 6: TESTIMONIALS ====== */}
      <section className="testimonials" id="testimonials">
        <div className="testimonials-header">
          <h2 className="section-title">Testimonials</h2>
        </div>
        <div className="testimonials-content">
          <div className="test-cards" ref={testCarouselRef}>
            {[
              { name: 'DAVID JOE', text: "Such a lovely ride! I wouldn't use any other service for my executive travel", stars: 5 },
              { name: 'SARAH JENKINS', text: 'We hire a limo to our wedding, and it was the highlights of the day. The driver was punctual and incredibly polite.', stars: 5 },
              { name: 'MICHAEL T.', text: "Such a lovely ride! I wouldn't use any other service for my executive travel", stars: 5 },
              { name: 'EMILY R.', text: 'The absolute best car service in the city. Always on time and the vehicles are spotless.', stars: 5 },
              { name: 'JOHN D.', text: 'Booked them for an airport transfer. Seamless experience from start to finish.', stars: 5 },
              { name: 'AMANDA W.', text: 'Their corporate travel package makes organizing team events a breeze. Highly recommended.', stars: 5 },
            ].map((t, i) => (
              <div className="test-card" key={i}>
                <div className="test-card-avatar">
                   <User size={60} color="#1c1c1c" fill="#1c1c1c" />
                </div>
                <h4>{t.name}</h4>
                <p>{t.text}</p>
                <div className="test-stars">
                  {[...Array(t.stars)].map((_, idx) => (
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

      {/* ====== SECTION 7: DOWNLOAD APP ====== */}
      <section className="download-section">
        <div className="container">
          <div className="download-header">
            <h2>Download our apps</h2>
            <p>Available for iOS and Android devices</p>
          </div>
          <div className="download-layout">
            <div className="download-img-col">
              <img src="/kenick phone mockup.png" alt="App Preview" />
            </div>
            <div className="download-text-col">
              <h2>Your premium ride<br />awaits!</h2>
              <p>Available for iOS and Android devices</p>
              <div className="hero-badges" style={{ marginTop: 0 }}>
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="App Store" />
                </button>
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Google Play" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ====== SECTION 8: CONTACT US ====== */}
      <section className="contact-section section-padding" id="contact">
        <div className="container">
          <h2 className="section-title">Get in touch</h2>
          <p className="contact-subtitle">Have a question or want to book a premium ride? Send us a message and we'll get back to you shortly.</p>
          <div className="contact-layout">
            {/* Left: Contact info */}
            <div className="contact-info">
              <div className="contact-info-card">
                <div className="contact-info-item">
                  <div className="contact-info-icon">
                    <MapPin size={24} />
                  </div>
                  <div>
                    <h4>Our Office</h4>
                    <p>123 Premium Drive, Suite 100<br />New York, NY 10001</p>
                  </div>
                </div>
                <div className="contact-info-item">
                  <div className="contact-info-icon">
                    <Phone size={24} />
                  </div>
                  <div>
                    <h4>Phone</h4>
                    <p>+1 (555) 123-4567</p>
                  </div>
                </div>
                <div className="contact-info-item">
                  <div className="contact-info-icon">
                    <Mail size={24} />
                  </div>
                  <div>
                    <h4>Email</h4>
                    <p>info@kenick.com</p>
                  </div>
                </div>
              </div>
              <div className="contact-hours">
                <h4>Business Hours</h4>
                <p>Monday – Friday: 6:00 AM – 11:00 PM</p>
                <p>Saturday – Sunday: 7:00 AM – 10:00 PM</p>
              </div>
            </div>

            {/* Right: Contact form */}
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

      {/* ====== SECTION 9: FOOTER ====== */}
      <footer className="footer">
        <div className="container">
          <div className="footer-top">
            <div className="footer-left">
              <div className="footer-brand">
                 <img src="/Kenick-logo-favicon.png" alt="Kenick Logo" />
                 <h2>Kenick</h2>
              </div>
              <div className="footer-links-grid">
                <a href="#" className="footer-link-main">About</a>
                <a href="#" className="footer-link-main">FAQs</a>
                <a href="#" className="footer-link-main">Policies</a>
                <div className="footer-contact">
                  <a href="#" className="footer-link-main">Contact Us</a>
                  <p>Kenick.com</p>
                  <p>xxxx xxxxx xxxx</p>
                  <div className="footer-social">
                    <a href="#" className="social-icon">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"></path></svg>
                    </a>
                    <a href="#" className="social-icon">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z"/>
                      </svg>
                    </a>
                    <a href="#" className="social-icon">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line></svg>
                    </a>
                    <a href="#" className="social-icon">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 4s-.7 2.1-2 3.4c1.6 10-9.4 17.3-18 11.6 2.2.1 4.4-.6 6-2C3 15.5.5 9.6 3 5c2.2 2.6 5.6 4.1 9 4-.9-4.2 4-6.6 7-3.8 1.1 0 3-1.2 3-1.2z"></path></svg>
                    </a>
                  </div>
                </div>
              </div>
            </div>
            <div className="footer-right">
              <h4>Get the latest news from us</h4>
              <div className="footer-subscribe">
                <input type="email" placeholder="Your email address" />
                <button className="footer-subscribe-btn">Subscribe</button>
              </div>
              <div className="footer-app-badges">
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/3/3c/Download_on_the_App_Store_Badge.svg" alt="Download on the App Store" />
                </button>
                <button className="store-badge">
                  <img src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg" alt="Get it on Google Play" />
                </button>
              </div>
            </div>
          </div>
          <div className="footer-bottom">
            <div className="footer-bottom-links">
              <a href="#">Privacy Policy</a>
              <a href="#">Terms & Conditions</a>
              <a href="#">Cookies</a>
              <a href="#">Legal</a>
              <a href="/admin/login" style={{ color: '#F4C522', marginLeft: 'auto' }}>Admin Portal</a>
            </div>
            <div className="footer-copyright">
              2026 Copyright: Kenick.com
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}
