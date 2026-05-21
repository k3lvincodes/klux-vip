import { useState } from 'react';
import { ChevronDown } from 'lucide-react';

interface FAQItem {
  question: string;
  answer: string;
}

export default function FAQ() {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const toggleFAQ = (index: number) => {
    setActiveIndex(activeIndex === index ? null : index);
  };

  const faqData: FAQItem[] = [
    {
      question: "How do I book a premium ride with Kenick?",
      answer: "You can book a ride instantly by clicking the \"Book a ride\" button on our website, or by using our mobile application on iOS and Android. Simply enter your pickup and drop-off locations, choose your vehicle class, and select your preferred schedule."
    },
    {
      question: "What vehicle classes are available in your fleet?",
      answer: "We offer a premium, late-model fleet of luxury vehicles including Business Sedans, Business SUVs, and First Class Luxury Sedans. Every vehicle is thoroughly inspected, meticulously detailed, and equipped with premium amenities."
    },
    {
      question: "Are your chauffeurs trained and licensed?",
      answer: "Yes, absolutely. All Kenick chauffeurs undergo rigorous background checks, professional driving assessments, and extensive hospitality training. They are fully licensed, insured, and committed to providing the highest standard of service."
    },
    {
      question: "Can I schedule a ride in advance?",
      answer: "Yes. You can schedule rides up to 30 days in advance or request an on-demand ride immediately. Scheduled rides are backed by our on-time guarantee."
    },
    {
      question: "How is pricing calculated?",
      answer: "We provide fully transparent, flat-rate pricing based on your distance, vehicle type, and scheduled time. There are no hidden fees or surprise surcharges—the price you see when booking is the price you pay."
    },
    {
      question: "What is your cancellation policy?",
      answer: "We offer free cancellation for most rides up to 2 hours before the scheduled pickup time. Cancellations made within 2 hours of the pickup time may be subject to a late cancellation fee."
    }
  ];

  return (
    <section className="faq-section section-padding" id="faq">
      <div className="container">
        <h2 className="section-title">Frequently Asked <span style={{ color: 'var(--yellow)' }}>Questions</span></h2>
        <p className="faq-subtitle">Everything you need to know about our premium chauffeur and ride services</p>
        
        <div className="faq-list">
          {faqData.map((item, index) => {
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
                  <span>{item.question}</span>
                  <div className="faq-icon">
                    <ChevronDown size={20} strokeWidth={2.5} />
                  </div>
                </button>
                
                <div className="faq-answer-wrapper">
                  <div className="faq-answer">
                    <div className="faq-answer-content">
                      {item.answer}
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
