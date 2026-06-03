import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { AlignRight, X } from 'lucide-react';
import LanguageSwitcher from './LanguageSwitcher';

export default function Navbar() {
  const { t } = useTranslation();
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
    { key: 'home', hash: '' },
    { key: 'fleets', hash: 'fleets' },
    { key: 'services', hash: 'services' },
    { key: 'about_us', hash: 'about-us' },
    { key: 'testimonials', hash: 'testimonials' },
    { key: 'contact', hash: 'contact' }
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
              <li key={item.key}>
                <a href={item.hash ? `/#${item.hash}` : '/'} onClick={() => setIsMenuOpen(false)}>
                  {t(`nav.${item.key}`)}
                </a>
              </li>
            ))}
          </ul>
          <div className="menu-footer">
            <Link to="/" className="nav-cta menu-cta" onClick={() => setIsMenuOpen(false)}>
              {t('common.book_btn')}
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
            {t('common.app_name')}
          </Link>
          <div className="nav-right">
            <LanguageSwitcher />
            <Link to="/book" className="nav-cta" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
              {t('common.book_btn')}
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
