import { Link } from 'react-router-dom';

export default function HowItWorks() {
  return (
    <section className="how-it-works section-padding" id="how-it-works">
      <div className="container">
        <div className="hiw-layout">
          {/* Left: Tree diagram */}
          <div className="hiw-tree">
            {/* SVG connector lines */}
            <svg className="hiw-lines" viewBox="0 0 600 680" fill="none" xmlns="http://www.w3.org/2000/svg">
              {/* Vertical trunk */}
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
        
        <div style={{ textAlign: 'center', marginTop: '3rem' }}>
          <Link to="/book" className="nav-cta" style={{ display: 'inline-block', textDecoration: 'none' }}>
            Book a ride now
          </Link>
        </div>
      </div>
    </section>
  );
}
