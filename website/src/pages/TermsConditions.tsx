import { FileText } from 'lucide-react';

export default function TermsConditions() {
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
              <FileText size={32} />
            </div>
            <h1 className="section-title" style={{ fontSize: '2.5rem', marginBottom: '0.5rem', color: '#000' }}>Terms & Conditions</h1>
            <p style={{ color: '#666', fontSize: '0.95rem' }}>Last updated: May 21, 2026</p>
          </div>

          <div className="policy-content" style={{ fontSize: '1rem', lineHeight: '1.8', color: '#333' }}>
            <p style={{ marginBottom: '1.5rem' }}>
              Welcome to Kenick. These Terms and Conditions ("Terms") govern your access to and use of our website, 
              mobile application, and high-end chauffeur booking services. By accessing or using our platform, 
              you agree to be bound by these Terms.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              1. Acceptance of Terms
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              By creating an account, booking a ride, or using any part of our service, you agree to these Terms 
              in full. If you do not agree to these Terms, you may not access or use the services provided by Kenick.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              2. User Accounts and Booking
            </h3>
            <p style={{ marginBottom: '1rem' }}>
              To book luxury transportation, you may be required to register for an account or provide accurate, current 
              information during checkout. You agree to:
            </p>
            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
              <li>Provide accurate pickup, drop-off, date, and contact details for all bookings.</li>
              <li>Maintain the confidentiality of your account credentials if registered.</li>
              <li>Accept responsibility for all activities that occur under your account or ride requests.</li>
            </ul>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              3. Service Quality and Chauffeur Conduct
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Kenick is committed to maintaining the highest standard of luxury transportation. All independent 
              professional chauffeurs affiliated with our platform are fully licensed, vetted, and operate premium, late-model 
              vehicles. While we strive to guarantee exact vehicle availability, we reserve the right to substitute 
              comparable or higher-class vehicles if unexpected operational constraints arise.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              4. Pricing, Payments, and Billing
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Pricing is calculated based on distance, duration, scheduled time, and chosen vehicle category. All 
              transactions are processed securely. You agree to pay the flat-rate fee displayed during booking, plus 
              any applicable tolls, additional stops requested en route, or cleaning/damage fees incurred due to 
              client negligence.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              5. Cancellation and No-Show Policy
            </h3>
            <p style={{ marginBottom: '1rem' }}>
              To respect our chauffeurs' schedules, the following cancellation policy applies:
            </p>
            <ul style={{ listStyleType: 'disc', paddingLeft: '1.5rem', marginBottom: '1.5rem' }}>
              <li><strong>Free Cancellation:</strong> Permitted up to 2 hours before the scheduled pickup time.</li>
              <li><strong>Late Cancellation:</strong> Cancellations made within 2 hours of the pickup time will be charged 50% of the flat ride fee.</li>
              <li><strong>No-Show:</strong> If you are not present at the pickup location within 30 minutes of the scheduled time without contact, the ride is marked as a no-show, and the full ride fee will be charged.</li>
            </ul>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              6. Limitation of Liability
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              Kenick, its affiliates, and chauffeurs shall not be liable for any indirect, incidental, special, or 
              consequential damages arising from delays caused by extreme traffic, severe weather, mechanical failure, 
              or force majeure events beyond our reasonable control.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              7. Governing Law
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              These Terms shall be governed by and construed in accordance with the laws of the State of Indiana, 
              without regard to conflict of law principles. Any dispute arising under these Terms shall be resolved 
              exclusively in the state or federal courts located in Indianapolis, IN.
            </p>

            <h3 style={{ fontSize: '1.3rem', fontWeight: 600, marginTop: '2rem', marginBottom: '0.75rem', color: '#000' }}>
              8. Contact Information
            </h3>
            <p style={{ marginBottom: '1.5rem' }}>
              For questions or clarifications regarding these Terms & Conditions, please contact us at:
            </p>
            <div style={{ 
              backgroundColor: '#f9f9f9', 
              padding: '1.25rem', 
              borderRadius: '10px', 
              borderLeft: '4px solid var(--yellow)',
              marginBottom: '2rem'
            }}>
              <strong>Kenick Legal & Compliance</strong><br />
              Email: booking@kenicktransportation.com<br />
              Phone: +1260-210-3519
            </div>
          </div>

        </div>
      </section>
    </div>
  );
}
