import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

function stripeCheckoutPlugin() {
  return {
    name: 'stripe-checkout-plugin',
    configureServer(server: any) {
      server.middlewares.use('/api/create-checkout-session', (req: any, res: any) => {
        if (req.method !== 'POST') {
          res.statusCode = 405;
          res.end('Method Not Allowed');
          return;
        }

        let body = '';
        req.on('data', (chunk: any) => {
          body += chunk;
        });

        req.on('end', async () => {
          try {
            const data = JSON.parse(body || '{}');
            const stripeSecretKey = process.env.STRIPE_SECRET_KEY || '';

            const invoiceNumber = `INV-${Date.now().toString(36).toUpperCase()}`;
            const bookingConfirmation = `BK-${Date.now().toString(36).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
            const amountInCents = Math.round(Number(data.total_amount || data.total || data.amount || 100) * 100);

            const origin = req.headers.origin || 'http://localhost:5173';
            const vehicle = data.vehicle_type || data.vehicle || 'Standard SUV';
            const pickup = data.pickup_address || data.pickup || 'Pickup Location';
            const dropoff = data.dropoff_address || data.dropoff || 'Destination';
            const tripDate = data.date || new Date().toISOString().split('T')[0];
            const tripTime = data.time || '12:00';
            const totalFormatted = (amountInCents / 100).toFixed(2);

            const successUrl = `${origin}/book?confirmed=true&session_id={CHECKOUT_SESSION_ID}&invoice=${invoiceNumber}&booking=${bookingConfirmation}&vehicle=${encodeURIComponent(vehicle)}&pickup=${encodeURIComponent(pickup)}&dropoff=${encodeURIComponent(dropoff)}&date=${tripDate}&time=${tripTime}&total=${totalFormatted}`;
            const cancelUrl = `${origin}/book?canceled=true`;

            const params = new URLSearchParams();
            params.append('payment_method_types[0]', 'card');
            params.append('mode', 'payment');
            if (data.contact_email || data.email) {
              params.append('customer_email', data.contact_email || data.email);
            }
            params.append('line_items[0][price_data][currency]', 'usd');
            params.append('line_items[0][price_data][product_data][name]', `${vehicle} - Executive Chauffeur Reservation`);
            params.append('line_items[0][price_data][product_data][description]', `From: ${pickup} to ${dropoff} on ${tripDate} at ${tripTime}`);
            params.append('line_items[0][price_data][unit_amount]', String(amountInCents));
            params.append('line_items[0][quantity]', '1');
            params.append('success_url', successUrl);
            params.append('cancel_url', cancelUrl);
            params.append('metadata[invoice_number]', invoiceNumber);
            params.append('metadata[booking_confirmation]', bookingConfirmation);
            params.append('metadata[vehicle]', vehicle);
            params.append('metadata[pickup]', pickup);
            params.append('metadata[dropoff]', dropoff);

            const stripeRes = await fetch('https://api.stripe.com/v1/checkout/sessions', {
              method: 'POST',
              headers: {
                Authorization: `Bearer ${stripeSecretKey}`,
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: params.toString(),
            });

            const stripeData = (await stripeRes.json()) as any;
            if (!stripeRes.ok) {
              res.statusCode = stripeRes.status;
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ error: stripeData.error?.message || 'Stripe error' }));
              return;
            }

            res.statusCode = 200;
            res.setHeader('Content-Type', 'application/json');
            res.end(
              JSON.stringify({
                checkout_url: stripeData.url,
                session_id: stripeData.id,
                invoice_number: invoiceNumber,
                booking_confirmation: bookingConfirmation,
              })
            );
          } catch (err: any) {
            res.statusCode = 500;
            res.setHeader('Content-Type', 'application/json');
            res.end(JSON.stringify({ error: err.message || 'Internal error' }));
          }
        });
      });
    },
  };
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), stripeCheckoutPlugin()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    host: 'localhost',
    hmr: {
      overlay: false,
      host: 'localhost',
      protocol: 'ws',
    },
    proxy: {
      '/api/didit': {
        target: 'https://verification.didit.me/v3/session',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/didit/, ''),
        headers: {
          'x-api-key': 'Ljgu4XQ0a_Ux3yMkPi6nLSGijRHOuUmTeBXyzPVVsjA',
        },
      },
    },
  },
})

