import { CheckCircle2 } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function Fleets() {
  return (
    <section className="fleets section-padding page-layout" id="fleets">
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
                <Link to={`/book?vehicle=${car.name}`} className="fleet-book-btn" style={{ textDecoration: 'none', display: 'block', textAlign: 'center' }}>Book now</Link>
              </div>
            ))}
          </div>
        </div>
    </section>
  );
}
