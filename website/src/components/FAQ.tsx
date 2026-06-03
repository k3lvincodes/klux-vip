import { useState } from 'react';
import { useTranslation, Trans } from 'react-i18next';
import { ChevronDown } from 'lucide-react';

export default function FAQ() {
  const { t } = useTranslation();
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const toggleFAQ = (index: number) => {
    setActiveIndex(activeIndex === index ? null : index);
  };

  const faqKeys = [
    { q: 'faq.q1', a: 'faq.a1' },
    { q: 'faq.q2', a: 'faq.a2' },
    { q: 'faq.q3', a: 'faq.a3' },
    { q: 'faq.q4', a: 'faq.a4' },
    { q: 'faq.q5', a: 'faq.a5' },
    { q: 'faq.q6', a: 'faq.a6' },
  ];

  return (
    <section className="faq-section section-padding" id="faq">
      <div className="container">
        <h2 className="section-title">
          <Trans i18nKey="faq.title" components={{ 1: <span style={{ color: 'var(--yellow)' }} /> }} />
        </h2>
        <p className="faq-subtitle">{t('faq.subtitle')}</p>
        
        <div className="faq-list">
          {faqKeys.map((item, index) => {
            const isActive = activeIndex === index;
            return (
              <div 
                key={index} 
                className={`faq-item ${isActive ? 'active' : ''}`}
              >
                <button 
                  className="faq-question" 
                  onClick={() => toggleFAQ(index)}
                  aria-expanded={isActive}
                >
                  <span>{t(item.q)}</span>
                  <div className="faq-icon">
                    <ChevronDown size={20} strokeWidth={2.5} />
                  </div>
                </button>
                
                <div className="faq-answer-wrapper">
                  <div className="faq-answer">
                    <div className="faq-answer-content">
                      {t(item.a)}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
