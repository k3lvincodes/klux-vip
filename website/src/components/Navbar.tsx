import { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { AlignRight, X } from 'lucide-react';
import LanguageSwitcher from './LanguageSwitcher';

export default function Navbar() {
  const { t } = useTranslation();
  const location = useLocation();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isSolid, setIsSolid] = useState(false);

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

  useEffect(() => {
    const hero = document.getElementById('home');
    if (!hero) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsSolid(!entry.isIntersecting);
      },
      { threshold: 0 }
    );
    observer.observe(hero);
    return () => observer.disconnect();
  }, []);

  const navLinks = [
    { key: 'home', hash: '' },
    { key: 'fleets', hash: 'fleets' },
    { key: 'services', hash: 'services' },
    { key: 'about_us', hash: 'about-us' },
  ];

  function getActiveKey(): string {
    const hash = location.hash.replace('#', '');
    if (!hash) return 'home';
    const match = navLinks.find((l) => l.hash === hash);
    return match ? match.key : 'home';
  }

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
            <Link to="/book" className="nav-cta menu-cta" onClick={() => setIsMenuOpen(false)}>
              {t('common.book_btn')}
            </Link>
          </div>
        </div>
      </div>

      <nav className={`navbar ${isSolid ? 'navbar--solid' : 'navbar--transparent'}`}>
        <div className="navbar-inner">
          <Link to="/" className="nav-logo" style={{ textDecoration: 'none', color: 'inherit' }}>
            <img src="/Kenick-logo-favicon.png" alt="Kenick" className="nav-logo-img" />
            {t('common.app_name')}
          </Link>

          <div className="nav-center">
            {navLinks.map((item) => (
              <a
                key={item.key}
                href={item.hash ? `/#${item.hash}` : '/'}
                className={`nav-link ${getActiveKey() === item.key ? 'nav-link--active' : ''}`}
              >
                {getActiveKey() === item.key && <span className="nav-link-dot" />}
                {t(`nav.${item.key}`)}
              </a>
            ))}
          </div>

          <div className="nav-right">
            <LanguageSwitcher />
            <Link to="/book" className="nav-cta" style={{ textDecoration: 'none', display: 'flex', alignItems: 'center' }}>
              {t('common.book_btn')}
            </Link>
            <button className="nav-menu-btn" onClick={() => setIsMenuOpen(true)} aria-label={t('common.menu')}>
              <AlignRight size={26} />
            </button>
          </div>
        </div>
      </nav>
    </>
  );
}
