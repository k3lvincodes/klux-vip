import { Link } from 'react-router-dom';
import HowItWorks from './HowItWorks';
import FAQ from '../components/FAQ';
import '../App.css';

export default function LandingPage() {
  return (
    <>
      {/* ====== SECTION 1: HERO ====== */}
      <section className="hero-wrapper" id="home">
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
            <Link to="/book" style={{ textDecoration: 'none' }}>
              <button className="hero-book-btn">Book a ride</button>
            </Link>
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

      <HowItWorks />

      <FAQ />

      {/* ====== SECTION 7: DOWNLOAD APP ====== */}
      <section className="download-section">
        <div className="container">
          <div className="download-header">
            <h2>Download App</h2>
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
    </>
  );
}
