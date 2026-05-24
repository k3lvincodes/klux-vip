
export default function Services() {
  return (
    <section className="services section-padding page-layout" id="services">
      <div className="services-bg-circle-1" />
      <div className="services-bg-circle-2" />
      <h2 className="section-title">Our services</h2>
      <div className="container">
        <div className="services-grid">
          {[
            { title: 'Airport transfers', desc: 'Enjoy a seamless transition from the tarmac to your final destination.', img: '/airport image.png' },
            { title: 'Corporate travel', desc: 'Designed for business professionals. Our corporate travel service offers reliability, comfort, and privacy.', img: '/copoorate image.png' },
            { title: 'Wedding & events', desc: 'Make your special day unforgettable with our luxury SUV transportation.', img: '/event image.png' },
            { title: 'Group & VIP transport', desc: "Streamline your team's travel with our executive group transfer services.", img: '/group transport image.png' },
          ].map((s) => (
            <div className="service-card" key={s.title}>
              <div className="service-card-img"><img src={s.img} alt={s.title} /></div>
              <div className="service-card-body">
                <h3>{s.title}</h3>
                <p>{s.desc}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="services-cta" style={{ textAlign: 'center', marginTop: '3rem' }}>
          <a href="/#contact" className="btn btn-dark services-learn-btn" style={{ display: 'inline-block', textDecoration: 'none' }}>Contact Us to Learn More</a>
        </div>
      </div>
    </section>
  );
}
