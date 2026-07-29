# TODO — Project Audit Issues

> Full codebase audit findings — 43 issues across security, bugs, accessibility, and code quality.

---

## 🔴 CRITICAL (Fix Immediately)

- [x] **`invoiceNumber` Used Before Declaration — Booking Function Crashes Every Time**
  - File: `app/supabase/functions/create-booking/index.ts:237`
  - `invoiceNumber` is referenced in `paymentIntentData.metadata` but not declared until line 272. This will throw a `ReferenceError` on every booking creation. This is the most critical bug — website bookings are completely broken.

- [x] **Payment Operations Accessible Without Authentication**
  - File: `app/supabase/functions/payments/index.ts:61, 98, 263`
  - Auth checks use `if (callerId && callerId !== user_id)` — when `callerId` is null (no auth header), the check is skipped entirely. Unauthenticated callers can process payments and initiate payouts to any driver.

- [x] **SQL Injection Risk in Booking Creation**
  - File: `app/supabase/functions/create-booking/index.ts:200, 203`
  - User-controlled coordinates are string-interpolated directly into PostGIS geography literals: `` `ST_SetSRID(ST_MakePoint(${pickup_lng}, ${pickup_lat}), 4326)::geography` ``. Values are not validated as finite numbers before interpolation.

- [x] **CORS Wildcard Default on All 8 Edge Functions**
  - Files: All `app/supabase/functions/*/index.ts`
  - Default to `'*'` if `ALLOWED_ORIGIN` is unset. Any origin can invoke these functions.

- [x] **Stripe Webhook Secret Falls Back to Empty String**
  - File: `app/supabase/functions/stripe-webhook/index.ts:14`
  - `const whSecret = webhookSecret || ''` silently disables webhook signature verification when the env var is missing.

- [x] **API Secrets in `.env` Files on Disk**
  - File: `app/.env` — Contains Supabase anon key, Cloudinary credentials, Mapbox token, Didit API key, Didit webhook secret, Resend API key in plaintext.
  - File: `website/.env` — Contains Supabase URL, anon key, Mapbox token.
  - `.gitignore` has rules but files exist on disk and may have been committed previously. **Note: This is a deployment/config issue, not a code fix. Ensure .env files are in .gitignore and rotate any exposed secrets.**

---

## 🟠 HIGH (Fix Soon)

- [x] **No React `<ErrorBoundary>` — White Screen on Any Render Crash**
  - File: `website/src/App.tsx`
  - No error boundary wraps the app. Any unhandled rendering error gives a white screen.

- [x] **`dangerouslySetInnerHTML` XSS Vectors (3 locations)**
  - `website/src/pages/LandingPage.tsx:58, 90`
  - `website/src/pages/Contact.tsx:53`
  - i18n translation strings injected as raw HTML. If translations are ever user-controlled, these become XSS vectors.

- [x] **`innerHTML` XSS in Admin Pages (3 locations)**
  - `website/src/pages/admin/AdminLayout.tsx:117` — Imperative DOM creation with innerHTML
  - `website/src/pages/admin/SupportPage.tsx:200` — Interpolates `t.subject`, `t.user_name`, `t.description` directly
  - `website/src/pages/admin/DocumentsPage.tsx:611`

- [x] **Tailwind CSS Used But Not Installed**
  - File: `website/src/components/ProtectedRoute.tsx:10-27` — Loading spinner, access-denied screen render as unstyled plain text.
  - File: `website/src/pages/admin/AdminLayout.tsx:51` — Sidebar overlay classes are dead.
  - No `tailwind.config.js`, no `tailwindcss` in `package.json`, no Tailwind import anywhere.

- [x] **12 Swallowed Errors via `.then().catch(() => {})`**
  - All notification/email/SMS sub-calls in `create-booking/index.ts:307, 326, 350, 366, 397-398, 426` and `matchmaker/index.ts:153, 175, 190` silently discard errors. Zero observability on notification delivery failures.

- [x] **`listenToRide` Crashes on Empty Stream Events**
  - File: `app/lib/repositories/ride_repository.dart:96`
  - `events.first` throws `StateError: No element` if Supabase emits an empty array (e.g., during ride deletion).

- [x] **No Rate Limiting on Matchmaker**
  - File: `app/supabase/functions/matchmaker/index.ts`
  - No auth check, no rate limiting. Any caller can invoke it to rapidly match all available drivers, causing denial-of-service.

- [x] **Deprecated FCM HTTP API Usage**
  - File: `app/supabase/functions/notifications/index.ts:31`
  - Uses legacy `https://fcm.googleapis.com/fcm/send`. Should migrate to FCM HTTP v1 API.

---

## 🟡 MEDIUM (Should Fix)

- [x] **73 `console.log/warn/error` Statements in Production Code**
  - 26 in frontend (`website/`), 47 in backend (`app/supabase/functions/`).
  - Key locations: `BookingPage.tsx` (11), `stripe-webhook/index.ts` (16), `didit-webhook/index.ts` (14), all 9 admin pages.

- [x] **14 `any` Type Usages Breaking Type Safety**
  - `BookingPage.tsx:100, 172, 239, 299, 559` — prop types, catch blocks, Leaflet map, window access.
  - `DocumentsPage.tsx:29, 406, 552, 565` — useState, catch blocks, iterator params.
  - `i18n/index.ts:19-22` — Record types and casts.
  - `stripe-webhook/index.ts:60, 88, 114, 193, 211` — Stripe event objects.

- [x] **`Math.random()` Used for Booking Confirmations**
  - `create-booking/index.ts:34, 44` and `BookingPage.tsx:157`
  - Should use `crypto.getRandomValues()` for unpredictability.

- [x] **Fixed Hero Height — No Responsive Override**
  - File: `website/src/index.css:311`
  - `.hero-wrapper { height: 1024px }` with no media query. Breaks on mobile devices.

- [x] **Missing Form Labels (Accessibility)**
  - `BookingPage.tsx` — All 10+ inputs have no `htmlFor`/`id` pairing.
  - `Footer.tsx:47` — Email subscription input has no label or `aria-label`.

- [x] **Booking Form Lacks Client-Side Validation**
  - `BookingPage.tsx:594-740`
  - No email/phone format validation, allows past dates, no guard on empty pickup/dropoff fields. Fare calculation runs with empty values.

- [x] **Contact Form `setTimeout` Not Cleaned Up**
  - `website/src/pages/Contact.tsx:31`
  - `setTimeout(() => setSubmitSuccess(false), 4000)` never cleared on unmount. Memory leak and potential state-update-after-unmount.

- [x] **Admin Document Approve/Reject Has No Loading State**
  - `DocumentsPage.tsx:104-152`
  - Users can double-click approve/reject while request is in flight, leading to duplicate DB updates.

- [x] **AuthContext `checkSuperAdmin` Race Condition**
  - `AuthContext.tsx:26-56`
  - Rapid auth state changes (e.g., token refresh) can trigger concurrent `checkSuperAdmin` calls. Last one to resolve wins regardless of actual session.

- [x] **Firebase Stream Subscriptions Never Cancelled**
  - `app/lib/services/firebase_service.dart:21, 88, 92`
  - `onTokenRefresh.listen()`, `onMessage.listen()`, `onMessageOpenedApp.listen()` — StreamSubscription objects never stored or cancelled.

- [x] **Leaflet CSS Not Removed on BookingPage Cleanup**
  - `BookingPage.tsx:283-289`
  - Script element is removed in cleanup but the CSS `<link id="leaflet-css">` is orphaned in `<head>`.

- [x] **Mixed Styling Approaches Reduce Maintainability**
  - CSS classes in `index.css` (public), CSS in `admin.css`/`admin-login.css` (admin), inline styles extensively in BookingPage, and non-functional Tailwind classes in ProtectedRoute/AdminLayout.

- [x] **40+ Hardcoded Colors Bypassing CSS Custom Properties**
  - `index.css` — Colors like `#F4F5F7`, `#4A4A4A`, `#555`, `#333`, `#bbb` repeated across 15+ selectors without design tokens.

- [x] **Multiple Z-Index Conflicts**
  - 5 elements at z-index 9999, sidebar overlay matching topbar at z-index 40.

- [x] **`overflow-x: hidden` on Body Masks Real Overflow**
  - `index.css:105` — Hides horizontal scrollbars instead of fixing overflow issues.

- [x] **Unchecked `.message` Access on Unknown Error Types**
  - 8 catch blocks across edge functions access `error.message` without type narrowing. Returns `undefined` if caught value is not an Error.

- [x] **Placeholder Supabase URL Instead of Throwing**
  - `website/src/lib/supabase.ts:11`
  - `'https://placeholder.supabase.co'` fallback silently creates a client that fails on every request.

---

## 🟢 LOW (Nice to Fix)

- [x] **Unused Import `useNavigate`**
  - File: `website/src/components/ProtectedRoute.tsx:1`

- [x] **Unused Variable `country`**
  - File: `website/src/pages/admin/PricingPage.tsx:290`

- [x] **Duplicate `@keyframes spin` Definitions**
  - `index.css:1728` and `admin.css:7`

- [x] **Duplicate Google Fonts Import**
  - `admin.css:5` and `admin-login.css:5`

- [x] **Duplicate `.service-card-img` CSS Rule**
  - `index.css:1060-1061` — Two consecutive declarations for same selector.

- [x] **Empty `App.css` Import**
  - `LandingPage.tsx:12` — `import '../App.css'` contains only a comment.

- [x] **Image Filename Typo**
  - `copoorate image.webp` should be `corporate`. Works because file exists, but creates confusion.

- [x] **Non-Descriptive Alt Text on Language Flags**
  - `LanguageSwitcher.tsx:63, 80` — Displays "En", "Fr" instead of descriptive text.

- [x] **Deno Standard Library Pinned to Old Version**
  - `didit-webhook/index.ts:2` — Pinned to `std@0.208.0`.

- [x] **FAQ Answer Max-Height May Clip Content**
  - `index.css:1522` — 500px limit clips long answers.

- [x] **Session Stored Without Expiry in FlutterSecureStorage**
  - `app/lib/providers/auth_provider.dart:78-90` — No TTL or expiry check on `bio_session`.

- [x] **`sharp` in devDependencies**
  - `website/package.json` — Unusual for Vite project; verify if actually needed.

---

## Summary

| Severity | Count | Description |
|----------|-------|-------------|
| 🔴 Critical | 6 | Security vulnerabilities, crashes, broken bookings |
| 🟠 High | 8 | Missing error boundaries, XSS, unstyled components, silent failures |
| 🟡 Medium | 17 | Type safety, console logs, validation, accessibility, styling |
| 🟢 Low | 12 | Unused imports, typos, duplicate CSS, minor polish |
| **Total** | **43** | **All issues resolved ✓** |
