import { CheckCircle2 } from 'lucide-react';

export default function AboutUs() {
  return (
    <div className="page-layout" style={{ backgroundColor: '#fff', color: '#000' }}>
      <section className="about-us section-padding" id="about-us" style={{ paddingTop: '2rem' }}>
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

      <section className="why-choose section-padding" id="why-choose-us" style={{ marginTop: '40px' }}>
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
    </div>
  );
}
