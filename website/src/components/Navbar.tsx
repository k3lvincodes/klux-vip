import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { AlignRight, X } from 'lucide-react';

export default function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

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

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Fleets', path: '/fleets' },
    { name: 'Services', path: '/services' },
    { name: 'About us', path: '/about' },
    { name: 'Testimonials', path: '/testimonials' },
    { name: 'Contact', path: '/contact' }
  ];

  return (
    <>
      <div className={`fullscreen-menu ${isMenuOpen ? 'open' : ''}`}>
        <button className="close-menu-btn" onClick={() => setIsMenuOpen(false)}>
          <X size={40} />
        </button>
        <div className="menu-content">
          <ul className="menu-links">
            {navLinks.map((item) => (
              <li key={item.name}>
                <Link to={item.path} onClick={() => setIsMenuOpen(false)}>
                  {item.name}
                </Link>
              </li>
            ))}
          </ul>
          <div className="menu-footer">
            <Link to="/" className="nav-cta menu-cta" onClick={() => setIsMenuOpen(false)}>
              Ride
            </Link>
          </div>
        </div>
      </div>

      <nav className="navbar">
        <div className="navbar-inner">
          <Link to="/" className="nav-logo" style={{ textDecoration: 'none', color: 'inherit' }}>
            <div className="nav-logo-icon">
              <img src="/Kenick-logo-favicon.png" alt="Kenick Logo" style={{ width: '100%', height: '100%', objectFit: 'contain', borderRadius: '10px' }} />
            </div>
            Kenick
          </Link>
          <div className="nav-right">
            <div className="nav-lang">
              <img src="https://flagcdn.com/w40/us.png" alt="US" />
              <span>En</span>
            </div>
            <Link to="/" className="nav-cta" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
              Ride
            </Link>
            <button className="nav-menu-btn" onClick={() => setIsMenuOpen(true)}>
              <AlignRight size={26} />
            </button>
          </div>
        </div>
      </nav>
    </>
  );
}
