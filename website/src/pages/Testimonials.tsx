import { useRef } from 'react';
import { ChevronRight, ChevronLeft, Star, User } from 'lucide-react';

export default function Testimonials() {
  const testCarouselRef = useRef<HTMLDivElement>(null);

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

  return (
    <section className="testimonials section-padding page-layout" id="testimonials">
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
  );
}
