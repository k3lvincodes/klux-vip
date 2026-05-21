import { Shield } from 'lucide-react';

export default function PrivacyPolicy() {
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
              <Shield size={32} />
            </div>
            <h1 className="section-title" style={{ fontSize: '2.5rem', marginBottom: '0.5rem', color: '#000' }}>Privacy Policy</h1>
            <p style={{ color: '#666', fontSize: '0.95rem' }}>Last updated: May 21, 2026</p>
          </div>

          <div className="policy-content" style={{ fontSize: '1rem', lineHeight: '1.8', color: '#333' }}>
            <p style={{ marginBottom: '1.5rem' }}>
              At Kenick, we are dedicated to protecting your privacy and ensuring the security of your personal data. 
              This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you 
              use our website, mobile application, and luxury chauffeur services.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              1. Information We Collect
            </h3>
            <p style={{ marginBottom: '1rem' }}>
              We collect personal information that you voluntarily provide to us when you register on our platform, 
              request or book a ride, or communicate with us. This includes:
            </p>
            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
              <li><strong>Contact Information:</strong> Your name, email address, phone number, and physical address.</li>
              <li><strong>Ride Details:</strong> Pickup and drop-off locations, date and time, and vehicle preference.</li>
              <li><strong>Payment Information:</strong> Credit card details, billing address, and transaction history (processed securely via encrypted payment gateways).</li>
              <li><strong>Location Data:</strong> With your permission, we collect precise location data from your device to facilitate pickups.</li>
            </ul>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              2. How We Use Your Information
            </h3>
            <p style={{ marginBottom: '1rem' }}>
              We use the collected information for various purposes to deliver a premium and reliable ride experience, including:
            </p>
            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
              <li>Processing bookings, scheduling rides, and dispatching professional chauffeurs.</li>
              <li>Processing payments and preventing fraudulent transactions.</li>
              <li>Providing real-time updates and notifications regarding your ride status.</li>
              <li>Improving our services, mobile app functionality, and user experience.</li>
              <li>Responding to customer support requests and communication.</li>
            </ul>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              3. Sharing and Disclosure
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              We do not sell or trade your personal information to third parties. We may share necessary details with 
              trusted service providers (e.g., payment processors, map API providers, and your assigned chauffeur) 
              solely to execute and complete your booking. We may also disclose information if required by law to 
              comply with legal processes or protect our rights and safety.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              4. Data Security
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              We implement industry-standard administrative, technical, and physical security measures to safeguard 
              your personal data. However, please be aware that no transmission over the internet or method of electronic 
              storage can be guaranteed 100% secure.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              5. Your Rights and Choices
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Depending on your location, you may have rights to access, correct, delete, or limit the use of your 
              personal data. You can manage your notification preferences and location permissions directly through 
              your device settings or your account profile.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              6. Contact Us
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              If you have any questions or concerns regarding this Privacy Policy or our data practices, please contact 
              us at:
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
