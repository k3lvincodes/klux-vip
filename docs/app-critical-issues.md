# App — Critical Issues Report

**Project:** Kenick VIP (`klux-vip/app`)
**Platform:** Flutter/Dart + Supabase
**Date:** 2026-06-23

---

## 1. [CRITICAL] API Keys and Secrets Exposed in Client Bundle

**Files:** `.env` (lines 1-16), `pubspec.yaml` (line 70)

The `.env` file contains all production API keys in plaintext and is bundled into the app as an asset (`assets: - .env`). Anyone who decompiles the APK/IPA can extract:
- `SUPABASE_ANON_KEY` — anonymous DB access
- `CLOUDINARY_UPLOAD_PRESET` — arbitrary image uploads
- `MAPBOX_ACCESS_TOKEN` — map API abuse
- `DIDIT_API_KEY`, `DIDIT_WEBHOOK_SECRET` — identity verification secrets
- `RESEND_API_KEY` — email sending capability

**Fix:** Use a BFF (backend-for-frontend) pattern. Move Cloudinary, Didit, and Resend operations to Supabase Edge Functions. Never embed secrets in mobile apps.

---

## 2. [HIGH] Duplicated & Conflicting Auth Routing Logic

**Files:** `lib/main.dart` (lines 114-139), `lib/screens/splash_screen.dart` (102-139), `lib/screens/sign_in_screen.dart` (139-189)

Post-login routing logic is duplicated in three places with different conditions. GoRouter in `main.dart` only checks `userMetadata['role']`, while `splash_screen.dart` also checks for missing profile fields. A user can end up at different destinations depending on which path resolves first.

**Fix:** Extract into a single `AuthRoutingService` that all callers use.

---

## 3. [CRITICAL] Matchmaker Edge Function References Undefined Variable

**File:** `supabase/functions/matchmaker/index.ts` (line 40)

```typescript
if (ride.driver_id) {
```
`ride` is never defined — no DB query fetches it. This will always throw a `ReferenceError`. Additionally, lines 26-31 and 33-38 contain an exact duplicate validation block.

**Fix:** Fetch the ride record before the race check, remove duplicate validation.

---

## 4. [HIGH] No Domain Models — Raw `Map<String, dynamic>` Everywhere

**Files:** All repositories in `lib/repositories/*.dart`, all providers in `lib/providers/*.dart`, `lib/models/` is **empty**

The entire app uses `Map<String, dynamic>` instead of typed model classes. This causes runtime type casting errors, no compile-time safety, and brittle code that breaks silently when DB columns change.

**Fix:** Create typed models (`Ride`, `UserProfile`, `Vehicle`, `Transaction`, etc.) with `fromJson`/`toJson`.

---

## 5. [HIGH] Session Tokens Stored in Unencrypted SharedPreferences

**Files:** `lib/providers/auth_provider.dart` (lines 77-78, 194-196), `lib/screens/sign_in_screen.dart` (83-88)

Full Supabase session JSON and refresh tokens are stored in plain `SharedPreferences` (unencrypted XML file on Android). On rooted/jailbroken devices or with backups enabled, tokens can be exfiltrated, allowing permanent session hijacking.

**Fix:** Use `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android).

---

## 6. [HIGH] Hardcoded Fallback Coordinates & Fare in RideProvider

**File:** `lib/providers/ride_provider.dart` (lines 71-78)

```dart
pickupLat: pickupLat ?? 37.42796133580664,  // Google HQ
pickupLng: pickupLng ?? -122.085749655962,
fareAmount: fareAmount ?? 200.0,
```

If coordinates or fare are null, the app silently defaults to Google HQ and $200. This is leftover test data that could silently create rides at wrong locations with arbitrary charges.

**Fix:** Make parameters non-nullable and throw a clear exception if values are missing.

---

## 7. [HIGH] Race Condition — Ride Can Be Accepted by Multiple Drivers

**Files:** `lib/repositories/ride_repository.dart` (61-69), `supabase/functions/matchmaker/index.ts` (110-118)

Ride assignment has no database-level unique constraint on `driver_id` per ride. The matchmaker's `.is('driver_id', null)` guard and the `accept_ride` RPC can both succeed simultaneously, assigning two drivers to the same ride.

**Fix:** Use `SELECT ... FOR UPDATE` locking or SERIALIZABLE transaction isolation for ride assignment.

---

## 8. [HIGH] N+1 Database Queries in DriverHomeScreen

**File:** `lib/screens/driver/driver_home_screen.dart` (lines 87-100)

```dart
for (final ride in rides) {
  final profile = await supabase.from('profiles')
      .select('first_name, last_name')
      .eq('id', passengerId).maybeSingle();
}
```

Issues one DB query per passenger. With 50 completed rides, that's 50 sequential queries. Also, `getDriverCompletedRides` has no pagination (returns ALL rides).

**Fix:** Batch with `.in_()` filter. Add `limit`/`offset` pagination.

---

## 9. [MEDIUM] Overly Permissive CORS on All Supabase Functions

**Files:** `supabase/functions/matchmaker/index.ts` (line 15), `payments/index.ts` (17), `didit-webhook/index.ts` (139), `notifications/index.ts` (50)

All Edge Functions use `'Access-Control-Allow-Origin': '*'`. For the payments function that processes Stripe transactions, this unnecessarily widens the attack surface for CSRF-like attacks.

**Fix:** Restrict to the actual app domain, or remove CORS headers entirely.

---

## 10. [MEDIUM] No Linter Rules & Near-Zero Test Coverage

**Files:** `analysis_options.yaml` (22-25), `test/widget_test.dart`

All additional linter rules are commented out — only base Flutter rules active. The single widget test creates the app without initializing Supabase/Firebase/dotenv, so it always crashes. No unit tests exist.

**Also:** Files are oversized (passenger_home_screen.dart: 892 lines, driver_home_screen.dart: 680 lines), `_buildInput` is duplicated identically in sign_in and sign_up screens.

**Fix:** Enable strict lint rules, add `mockito`/`supabase_mocks`, write unit tests for providers/repositories, break down large files.

---

# Payment System Issues

---

## P1. [CRITICAL] No Stripe Webhook Endpoint — Zero Reconciliation

**File:** `supabase/functions/payments/index.ts` (entire file)

The payments edge function handles only direct HTTP actions (`create-setup-intent`, `process-ride-payment`, `payout-driver`). There is **no Stripe webhook handler** anywhere in the project. This means:

- No `payment_intent.succeeded` handling — async payment confirmations are invisible
- No `payment_intent.payment_failed` / `charge.disputed` / `charge.refunded` handling
- No `payout.failed` / `payout.paid` handling for driver payouts
- No `stripe_events` table for idempotent webhook event processing

**Fix:** Create a Supabase Edge Function for Stripe webhooks with signature verification and a `stripe_events` deduplication table.

---

## P2. [CRITICAL] PCI DSS Violation — Raw Card Data Collected in Flutter Form

**File:** `lib/screens/passenger/payment_method_screen.dart` (lines 408-575)

The `_showAddCardModal` method collects full raw credit card data in plain Flutter text fields:
- Full PAN (card number) via `cardNumberController`
- Expiry (MM/YY) via `expiryController`
- CVV via `cvvController`
- Cardholder name via `nameController`

None of these use Stripe Elements, Stripe.js, or any PCI-compliant tokenization. Raw card data exists in application memory. This is a **major PCI DSS compliance violation** (SAQ A-EP / SAQ D requirements unmet).

**Fix:** Use Stripe's official SDK (e.g. `flutter_stripe`) which tokenizes card data via PCI-compliant webviews/iframes — the app never touches raw PAN/CVV.

---

## P3. [CRITICAL] Fake Mock PaymentMethod ID — Payments Will Always Fail

**File:** `lib/screens/passenger/payment_method_screen.dart` (line 551)

```dart
paymentMethodId: 'pm_mock_${DateTime.now().millisecondsSinceEpoch}',
```

The "Add Card" flow generates a **fake mock Stripe PaymentMethod ID** instead of creating a real one via the Stripe API. When `process-ride-payment` tries to use this ID to create a PaymentIntent (payments/index.ts line 99), Stripe will reject it. **The entire payment flow is broken — no real payment method can be saved, no real charge can be made.**

**Fix:** Use `flutter_stripe` to collect card details and create a real Stripe PaymentMethod via `Stripe.instance.createPaymentMethod()`.

---

## P4. [CRITICAL] No Idempotency Key on PaymentIntent — Double Charge Risk

**File:** `supabase/functions/payments/index.ts` (line 96)

```typescript
const paymentIntent = await stripe.paymentIntents.create({
  amount: Math.round(amount * 100),
  currency: 'usd',
  payment_method: paymentMethod.stripe_pm_id || paymentMethod.provider_token,
  confirm: true,
  metadata: { ride_id, user_id },
})
```

There is **no `idempotency_key`** parameter. If the request times out and the client retries, or the function encounters a transient error after the Stripe API call succeeds but before responding, the passenger will be **charged multiple times** for the same ride. Same issue applies to `stripe.transfers.create()` at line 149.

**Fix:** Use a unique idempotency key (e.g. `ride_id + '_payment'`) for every Stripe write operation.

---

## P5. [CRITICAL] `stripe_payment_intent_id` Never Stored in DB — Zero Stripe Reconciliation

**File:** `supabase/functions/payments/index.ts` (lines 105-127)

The `transactions` table schema defines a `stripe_payment_intent_id` column, but `process-ride-payment` never stores it. Neither `stripe_transfer_id` nor `client_secret` are saved. The system has **zero ability to reconcile** internal transaction records with the Stripe dashboard, making refunds, disputes, and payout tracing impossible.

**Fix:** Store `stripe_payment_intent_id` on every transaction insert, and `stripe_transfer_id` on every payout.

---

## P6. [CRITICAL] No Authentication on Payments Edge Function

**File:** `supabase/functions/payments/index.ts` (line 26)

The function uses the Supabase Service Role Key (full admin DB access) but performs **no verification** that the caller is authenticated or that the requested `user_id`/`driver_id` matches the caller. Any authenticated user can charge any other user's payment method or trigger payouts to any Stripe Connect account.

**Fix:** Verify `auth.uid()` matches the user being charged/paid. Use RLS + the Supabase client's authenticated context instead of the service role key where possible.

---

## P7. [CRITICAL] No 3D Secure / SCA Authentication Handling

**File:** `supabase/functions/payments/index.ts` (lines 96-104)

PaymentIntents are created with `confirm: true`, but only `status === 'succeeded'` is checked. Intents requiring strong customer authentication (status `requires_action`) are recorded as `pending` and never completed — the user has no way to complete 3DS authentication, and the payment will **never finish**.

**Fix:** Use `flutter_stripe`'s `handleNextAction()` to present the 3DS authentication UI to the user when `requires_action` is returned.

---

## P8. [CRITICAL] Amount Validation Bypass — Negative/Zero Charges Possible

**File:** `supabase/functions/payments/index.ts` (lines 72-78, 96-97)

The validation only checks `!amount` (truthiness). An amount of `0`, `-1`, or `NaN` passes. `Math.round(amount * 100)` with a negative value produces a **negative Stripe charge** (effectively a credit to the passenger). There is no `amount > 0` check, no upper bound, and no decimal precision validation.

**Fix:** Add strict validation: `if (!amount || amount <= 0 || !Number.isFinite(amount))`.

---

## P9. [HIGH] Payment Captured Before Ride — No Refund Mechanism Exists

**Flow:** `payment_method_screen.dart` → `processRidePayment` → Stripe charge → `/payment-successful`

Payment is captured **before the ride even starts**. If the rider cancels, the driver cancels, or the ride never completes, there is **no refund mechanism anywhere in the codebase** — no `stripe.refunds.create()`, no cancellation endpoint, no webhook handler for chargebacks or refunds.

**Also:** `payment_method_screen.dart` ignores which payment method the user visually selected — it always charges the most recently saved one (payments/index.ts lines 81-87).

**Fix:** Defer payment capture to ride completion. Add a refund endpoint. Pass the selected payment method ID to the edge function.

---

## P10. [HIGH] Fake Payment UI & Hardcoded Amounts

**Files:** `lib/screens/passenger/trip_summary_screen.dart` (lines 238-274), `lib/screens/driver/ride_payment_received_screen.dart` (line 219)

**Trip summary:** When ride status changes to `completed`, a "Processing VIP Ride Payment" spinner shows for 2.5 seconds then switches to "Payment Successful" — **no actual payment processing occurs**, it is a purely cosmetic animation.

**Driver screen:** The payout amount is **hardcoded as `$140`** regardless of the actual ride fare. The "View payment details" button has an **empty `onTap`** that does nothing.

**Fix:** Wire real payment processing to ride completion. Display actual amounts from the transaction record. Remove fake loading animations.

---

## Payment Summary Table

| # | Issue | Severity | Category |
|---|-------|----------|----------|
| P1 | No Stripe webhook endpoint | CRITICAL | Missing Feature |
| P2 | PCI DSS violation — raw card data collected | CRITICAL | Security/Compliance |
| P3 | Fake mock PaymentMethod ID | CRITICAL | Bug |
| P4 | No idempotency key — double charge risk | CRITICAL | Reliability |
| P5 | `stripe_payment_intent_id` never stored | CRITICAL | Data Loss |
| P6 | No auth on payments edge function | CRITICAL | Security |
| P7 | No 3D Secure / SCA handling | CRITICAL | Bug |
| P8 | Negative/zero amount passes validation | CRITICAL | Security |
| P9 | Payment captured before ride, no refunds | HIGH | Bug |
| P10 | Fake payment UI, hardcoded $140 | HIGH | Deceptive UI |

---

## Combined Summary Table

| # | Issue | Severity | Category |
|---|-------|----------|----------|
| 1 | API keys exposed in client bundle | CRITICAL | Security |
| 2 | Matchmaker references undefined variable | CRITICAL | Bug |
| 3 | No Stripe webhook endpoint | CRITICAL | Missing Feature |
| 4 | PCI DSS violation — raw card data | CRITICAL | Security/Compliance |
| 5 | Fake mock PaymentMethod ID | CRITICAL | Bug |
| 6 | No idempotency key — double charge risk | CRITICAL | Reliability |
| 7 | `stripe_payment_intent_id` never stored | CRITICAL | Data Loss |
| 8 | No auth on payments edge function | CRITICAL | Security |
| 9 | No 3D Secure / SCA handling | CRITICAL | Bug |
| 10 | Negative/zero amount passes validation | CRITICAL | Security |
| 11 | Duplicated auth routing logic | HIGH | Architecture |
| 12 | No domain models, raw Maps everywhere | HIGH | Architecture |
| 13 | Session tokens in unencrypted storage | HIGH | Security |
| 14 | Hardcoded test fallback values | HIGH | Bug |
| 15 | Race condition in ride assignment | HIGH | Bug |
| 16 | N+1 queries in DriverHomeScreen | HIGH | Performance |
| 17 | Payment captured before ride, no refunds | HIGH | Bug |
| 18 | Fake payment UI, hardcoded $140 | HIGH | Deceptive UI |
| 19 | Open CORS on all Edge Functions | MEDIUM | Security |
| 20 | No linter rules, near-zero test coverage | MEDIUM | Quality |
