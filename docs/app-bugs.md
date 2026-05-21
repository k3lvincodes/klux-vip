# Application Bug Report (Klux VIP)

A comprehensive audit of the Flutter application codebase (`app/lib`), performed via static analysis (`flutter analyze`), manual code review, and cross-referencing against the database migration files.

---

## [x] 1. COMPILE ERROR: Missing `sendVerificationFailedEmail` method
**File:** `lib/screens/driver_id_verification_screen.dart:100`  
**Severity:** 🔴 Critical (Build-breaking)  
**Description:** The screen calls `_emailService.sendVerificationFailedEmail(...)` on line 100, but the `EmailNotificationService` class only defines `sendVerificationSuccessEmail`. The "failed" variant was never implemented, causing a hard compile error.  
**Fix:** Add a `sendVerificationFailedEmail` method to `lib/services/email_notification_service.dart`.

---

## [x] 2. BUG: Biometric login does not actually re-authenticate the Supabase session
**File:** `lib/screens/sign_in_screen.dart:64-118`  
**Severity:** 🔴 Critical  
**Description:** When a user logs in via biometrics, the code successfully verifies their fingerprint/face locally and calls `DeviceBiometricsService.refreshSession(userId)`. However, it then tries to access `auth.currentUser` (line 88) to get the user's role, but it never actually creates or refreshes a Supabase Auth session. Since the user is logged out (that's why they're on the sign-in screen), `auth.currentUser` will be `null`, and the biometric login will always fail with "Session expired. Please log in with your password." at line 90-91.  
**Fix:** The biometric login flow needs to restore the Supabase session (e.g., using a stored refresh token or a server-side token exchange via the `check_device_biometric` RPC result).

---

## [x] 3. BUG: Splash screen race condition — navigation fires before route is determined
**File:** `lib/screens/splash_screen.dart:23-29`  
**Severity:** 🟠 High  
**Description:** In `initState`, `_determineNextRoute()` is called async, and a `Future.delayed(4000ms)` timer fires independently. If the network request in `_determineNextRoute` takes longer than 4 seconds (slow connection, cold Supabase start), the timer will fire while `_nextRoute` is still `null`, causing the user to be sent to `/onboarding` even if they are logged in.  
**Fix:** Use `await _determineNextRoute()` and only navigate after it completes, or use a `Completer` to synchronize the two.

---

## [x] 4. BUG: `ride_review_screen.dart` navigates to a non-existent `/home` route
**File:** `lib/screens/ride_review_screen.dart:61, 153`  
**Severity:** 🟠 High  
**Description:** After submitting a review or pressing "Skip", the screen calls `context.go('/home')`. But no `/home` route exists in your GoRouter configuration — the actual home routes are `/passenger-home` and `/driver-home`. This will result in a blank screen or a GoRouter error.  
**Fix:** Determine the user's role and navigate to the correct home route, or use `context.pop()` to go back.

---

## [x] 5. BUG: OTP screen uses `context.push` instead of `context.go` for post-auth navigation
**File:** `lib/screens/otp_screen.dart:92-126`  
**Severity:** 🟠 High  
**Description:** After successful OTP verification, the code uses `context.push('/passenger-home')` (line 103) and `context.push('/driver-home')` (line 122). Using `push` instead of `go` means the login/OTP screens remain in the navigation stack. The user can press the back button and return to the OTP screen or sign-up screen, which is a broken UX.  
**Fix:** Replace all post-authentication `context.push(...)` calls with `context.go(...)` to clear the auth stack.

---

## [x] 6. BUG: `_fetchPassengerNames` called on every StreamBuilder rebuild — infinite loop risk
**File:** `lib/screens/driver/driver_home_screen.dart:210-211`  
**Severity:** 🟠 High  
**Description:** Inside the `StreamBuilder` builder, `_fetchPassengerNames(rides)` is called on every rebuild. Each call triggers `setState`, which triggers another rebuild, which calls the function again. While the `_passengerNames` cache prevents infinite network requests, it still causes unnecessary rebuilds on the first load.  
**Fix:** Move passenger name fetching into a separate method triggered only when the ride list actually changes (e.g., compare ride IDs).

---

## [x] 7. BUG: `_saveDocuments` silently swallows all errors
**File:** `lib/screens/driver_id_verification_screen.dart:104-120`  
**Severity:** 🟡 Medium  
**Description:** The `_saveDocuments` method wraps the entire body in `try/catch (_) {}`, meaning if the document upload to the database fails, the driver will see "Identity verified successfully!" but their documents won't actually be saved. The driver will be stuck: verified by Didit but unable to proceed because the database has no record of it.  
**Fix:** At minimum, log the error. Ideally, show the user a warning or retry the save.

---

## [x] 8. BUG: `driver_id_verification_screen` updates a non-existent column `verification_status`
**File:** `lib/screens/driver_id_verification_screen.dart:122-130`  
**Severity:** 🔴 Critical  
**Description:** The `_updateVerificationStatus` method updates `{'verification_status': status}` on the `driver_profiles` table. However, the database schema for `driver_profiles` does not have a `verification_status` column — it only has `status` (which is the `profile_status` enum: pending/approved/suspended). This update will silently fail or throw an error.  
**Fix:** Either add a `verification_status` column to `driver_profiles` via a new migration, or update the correct `status` column using valid enum values.

---

## [x] 9. BUG: Resend API will reject emails — wrong sender domain
**File:** `lib/services/email_notification_service.dart:23`  
**Severity:** 🟡 Medium  
**Description:** The `from` address is set to `'Kenick Transportation LLC <onboarding@resend.dev>'`. The Resend API only allows sending from `@resend.dev` on the free tier for testing, but it will only deliver to the account owner's email. In production, this sender address will fail for all other users.  
**Fix:** Configure a custom verified domain in Resend and update the `from` address.

---

## [x] 10. BUG: Completed rides tab never fetches actual data
**File:** `lib/screens/driver/driver_home_screen.dart:166-183`  
**Severity:** 🟡 Medium  
**Description:** The "Completed" tab in the driver home screen is hardcoded to show a static "No completed rides yet" message. It never calls `RideRepository().getDriverCompletedRides(driverId)`, which exists and is functional. Drivers with completed rides will never see them.  
**Fix:** Wire up the `_buildCompletedTab` to call `getDriverCompletedRides` and display actual ride history data.

---

## [x] 11. BUG: Decline button on ride cards does nothing
**File:** `lib/screens/driver/driver_home_screen.dart:346`  
**Severity:** 🟡 Medium  
**Description:** The "Decline" button on ride request cards has `onPressed: () {}` — an empty callback. It provides no way for a driver to dismiss a ride they don't want to accept, and it gives the user the impression of a broken app.  
**Fix:** Implement ride decline logic (e.g., hide the card locally, or call an RPC to record the decline).

---

## [x] 12. BUG: Social login buttons are non-functional
**File:** `lib/screens/sign_in_screen.dart:374-424`  
**Severity:** 🟡 Medium  
**Description:** The Google, Facebook, and Apple social login buttons are rendered in the UI but have no `onTap` or `onPressed` handlers. They are purely visual. Users will tap them expecting to sign in and nothing will happen.  
**Fix:** Either implement OAuth via Supabase for each provider, or remove the buttons to avoid confusing users.

---

## [x] 13. INFO: `print()` statements left in production code
**File:** `lib/services/firebase_service.dart` (7 instances)  
**Severity:** 🔵 Low  
**Description:** The `FirebaseService` uses `print()` for logging FCM tokens and errors. While most are wrapped in `kDebugMode`, raw `print` calls in production can leak sensitive data (like FCM tokens) to the console.  
**Fix:** Ensure all logging uses `debugPrint` or a proper logging package, and is gated behind `kDebugMode`.

---

## [x] 14. BUG: OTP Resend doesn't actually resend the OTP
**File:** `lib/screens/otp_screen.dart:236-241`  
**Severity:** 🟡 Medium  
**Description:** When the user taps "Resend code", the timer restarts and a success toast is shown, but no actual API call is made to Supabase to resend the OTP email. The user will wait indefinitely for an OTP that was never sent.  
**Fix:** Call `auth.resendOtp(widget.email!)` or the equivalent Supabase method before showing the toast.
