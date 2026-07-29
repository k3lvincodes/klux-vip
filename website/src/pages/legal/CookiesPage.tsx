import { Cookie } from 'lucide-react';

export default function CookiesPage() {
  return (
    <div className="page-layout" style={{ backgroundColor: '#fff', color: '#000' }}>
      <section className="section-padding" style={{ paddingTop: '2rem' }}>
        <div className="container" style={{ maxWidth: '800px', margin: '0 auto' }}>
          
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <div style={{ 
              display: 'inline-flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              width: '60px', 
              height: '60px', 
              borderRadius: '50%', 
              backgroundColor: 'rgba(244, 197, 34, 0.1)', 
              color: 'var(--yellow)',
              marginBottom: '1rem'
            }}>
              <Cookie size={32} />
            </div>
            <h1 className="section-title" style={{ fontSize: '2.5rem', marginBottom: '0.5rem', color: '#000' }}>Cookies Policy</h1>
            <p style={{ color: '#666', fontSize: '0.95rem' }}>Last updated: May 25, 2026</p>
          </div>

          <div className="policy-content" style={{ fontSize: '1rem', lineHeight: '1.8', color: '#333' }}>
            <p style={{ marginBottom: '1.5rem' }}>
              At Kenick Transportation LLC, we use cookies and similar tracking technologies to enhance your 
              browsing experience, analyze site traffic, and deliver personalized content. This Cookies Policy 
              explains what cookies are, how we use them, and your choices regarding their use.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              1. What Are Cookies
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Cookies are small text files stored on your device (computer, tablet, or mobile) when you visit a 
              website. They allow the website to remember your actions and preferences (such as login, language, 
              and display settings) over a period of time, so you don't have to re-enter them each time you return.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              2. How We Use Cookies
            </h3>
            <p style={{ marginBottom: '1rem' }}>
              We use cookies for the following purposes:
            </p>
            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
              <li><strong>Essential Cookies:</strong> Required for the core functionality of our website, including secure login and session management.</li>
              <li><strong>Functional Cookies:</strong> Remember your preferences and settings to provide a tailored experience.</li>
              <li><strong>Analytics Cookies:</strong> Help us understand how visitors interact with our site, allowing us to improve performance and usability.</li>
              <li><strong>Advertising Cookies:</strong> Used to deliver relevant advertisements and measure the effectiveness of our marketing campaigns.</li>
            </ul>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              3. Third-Party Cookies
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              We may allow third-party service providers (such as Google Analytics, Mapbox, and payment processors) 
              to place cookies on your device for analytics, mapping, and transaction processing purposes. These 
              third parties have their own privacy and cookie policies governing the use of your data.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              4. Your Choices
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Most web browsers allow you to control cookies through their settings. You can choose to block or 
              delete cookies, but please note that disabling certain cookies may affect the functionality and 
              performance of our website. To manage your preferences, adjust your browser settings or use our 
              cookie consent tool available on your first visit.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              5. Updates to This Policy
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              We may update this Cookies Policy from time to time to reflect changes in technology, regulation, 
              or our business practices. When we make changes, we will revise the "Last updated" date at the top 
              of this page. We encourage you to review this policy periodically.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              6. Contact Us
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              If you have any questions about our use of cookies or this policy, please contact us at:
            </p>
            <div style={{ 
              backgroundColor: '#f9f9f9', 
              padding: '1.25rem', 
              borderRadius: '10px', 
              borderLeft: '4px solid var(--yellow)',
              marginBottom: '2rem'
            }}>
              <strong>Kenick Privacy Team</strong><br />
              Email: booking@kenicktransportation.com<br />
              Address: 125 W South St, Indianapolis, Indiana, 46206
            </div>
          </div>

        </div>
      </section>
    </div>
  );
}
