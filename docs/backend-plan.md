# Kenick - Functional Backend Plan

Based on a comprehensive analysis of the existing project structure, Dart repositories, and Supabase SQL migrations, here is the proposed backend architecture and implementation plan for the Kenick platform.

## 1. Current State Assessment
- **Infrastructure:** Supabase (PostgreSQL, Auth, Storage, Realtime).
- **Existing Schema:** Tables for `users`, `driver_profiles`, `passenger_profiles`, `rides`, `payment_methods`, and `transactions` are established with basic PostGIS `geography` support.
- **Client Repositories:** Dart repositories expect direct database interactions for profile updates, ride requests, and basic transaction logging.
- **Realtime:** Subscriptions are enabled for `rides` and `driver_profiles`.

## 2. Critical Schema Additions & Modifications ✅ [COMPLETED]
To support a production-ready ride-hailing app, the schema needs the following enhancements:

- **`vehicles` Table:** 
  - *Why:* Drivers must register specific vehicles (Make, Model, Year, Color, License Plate). Passengers need this to identify their ride.
  - *Relation:* 1-to-many or 1-to-1 with `driver_profiles`.
- **`reviews` Table:**
  - *Why:* The current schema has a hardcoded `rating` on driver profiles. We need to track individual ride reviews (stars, comments, reviewer_id, reviewee_id) and use triggers to calculate the aggregate driver profile rating.
- **`support_tickets` Table:**
  - *Why:* For users to report issues with rides, payments, or safety concerns.
- **Documents Storage:**
  - *Why:* Drivers require background checks (License, Insurance, Registration). These should go into Supabase Storage buckets with strict RLS policies, linked via a `driver_documents` table tracking approval status.

## 3. Advanced PostGIS & Database Functions ✅ [COMPLETED]
Client-side apps should not handle complex spatial querying or fare calculations.

- **`find_nearby_drivers(lat, lng, radius_meters)`:** 
  - A PostgreSQL function utilizing PostGIS `ST_DWithin` to find online drivers near a requested pickup location.
- **`calculate_fare(distance, duration, booking_type)`:** 
  - Move fare calculation to the database/backend to prevent client-side spoofing. It should factor in base fare, per-km rate, per-minute rate, and potential surge multipliers.

## 4. Supabase Edge Functions (Deno / TypeScript) ✅ [COMPLETED]
Direct database inserts from Flutter for payments and matchmaking are a security risk. We must implement the following Edge Functions:

### A. Matchmaking Engine (`/functions/matchmaker`)
- *Trigger:* Called when a passenger requests a ride.
- *Logic:* 
  1. Finds the closest online driver using `find_nearby_drivers`.
  2. Sends a Push Notification (via FCM/APNs) to that driver.
  3. Sets a timeout (e.g., 15 seconds). If unaccepted, pings the next closest driver.

### B. Payment Gateway (`/functions/payments`)
- *Integration:* Stripe or similar processor.
- *Endpoints:*
  - `create-setup-intent`: Securely adds a new card to a passenger's profile.
  - `process-ride-payment`: Triggered when a ride is completed. Charges the passenger's saved card and records the transaction.
  - `payout-driver`: Handles transferring earnings to the driver's bank account via Stripe Connect.

### C. Notifications (`/functions/notifications`)
- *Integration:* Firebase Cloud Messaging (FCM).
- *Triggers:* Webhooks fired by database triggers (e.g., `rides` table updates to `arriving` or `accepted`) to push alerts to the respective user's device.

## 5. Security & RLS Hardening ✅ [COMPLETED]
Current RLS policies are too permissive for a production financial environment.

- **Rides Table Hardening:** Passengers should only be able to `INSERT` a ride request. They should **not** have `UPDATE` permissions to modify `fare_amount` or `status` to `completed`. Status updates must be restricted to drivers and backend functions.
- **Transactions Hardening:** The `transactions` table must be strictly controlled. Only the `payment` Edge Function (using the Supabase Service Role Key) should be allowed to `INSERT` or `UPDATE` transactions. Client apps should be strictly read-only for their own transaction history.

## 6. Proposed Implementation Phases

1. **Phase 1: Schema & Data Layer** `[COMPLETED]`
   - Execute SQL migrations for `vehicles`, `reviews`, and spatial functions.
   - Restrict existing RLS policies.
2. **Phase 2: Edge Functions (Payments & Notifications)** `[COMPLETED]`
   - Scaffold Supabase Edge Functions.
   - Integrate Stripe SDK and Firebase Admin SDK.
3. **Phase 3: Matchmaking Logic** `[COMPLETED]`
   - Implement the `matchmaker` Edge function to handle driver pinging and timeouts.
4. **Phase 4: Client Refactoring** `[COMPLETED]`
   - Update `ride_repository.dart` and `payment_repository.dart` in the Flutter app to call Edge Functions via `Supabase.instance.client.functions.invoke()` instead of direct database mutations.

## 7. Next-Generation Highly Functional Features

### A. Intelligent Batch Dispatching ✅ [COMPLETED]
- **Concept:** Upgrade matchmaking from a greedy "closest driver" ping to a batched bipartite matching system (using the Hungarian algorithm).
- **Functionality:** Accumulate ride requests every 10 seconds and match them to the available driver pool globally to reduce overall ETA across the system, rather than just optimizing for a single user.

### B. Real-Time Dynamic Surge Engine ✅ [COMPLETED]
- **Concept:** Replace the static fare multipliers with a live supply-and-demand elasticity model.
- **Functionality:** Use PostGIS and H3 Hexagonal spatial indexing to group users and drivers. Calculate regional heatmaps and apply granular surge pricing (e.g., 1.2x on 5th Avenue, 1.0x on 6th Avenue) based on real-time driver density.

### C. Immutable Double-Entry Ledger (Wallet System) ✅ [COMPLETED]
- **Concept:** Replace basic balance tracking with an ACID-compliant ledger.
- **Functionality:** Every ride payment, driver payout, and promo code usage writes debit/credit rows to a locked `ledger` table. This prevents race conditions and balance manipulation, ensuring enterprise-grade financial security.

### D. High-Frequency Telemetry Data Lake ✅ [COMPLETED]
- **Concept:** Separate live-tracking from the primary transactional database.
- **Functionality:** Stream high-frequency driver GPS coordinates through Edge Functions into a time-series optimized storage or append-only table. This builds precise route traces to prevent GPS spoofing and handle passenger fare disputes.
