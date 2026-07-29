# Klux VIP — App Structure

> **Package:** `kenick_vip` | **Display name:** Kenick | **Platform:** Flutter  
> **Entry:** `app/lib/main.dart` | **Total:** 80 Dart files (1 main + 4 providers + 8 repos + 7 services + 1 theme + 2 utils + 19 widgets + 38 screens)

---

## Tech Stack

| Layer | Choice |
|---|---|
| State | `Provider` + `ChangeNotifier` |
| Backend | Supabase (auth, DB, edge functions) |
| Routing | `go_router` (46 routes) |
| Maps | `flutter_map` + Mapbox tiles |
| Geocoding | Mapbox Geocoding API |
| KYC | Didit SDK |
| Push | Firebase Cloud Messaging |
| Images | `image_picker` → Cloudinary → `cached_network_image` |
| Biometrics | `local_auth` |
| Toast | `toastification` |
| Animations | Custom (`FadeSlideIn`, `PressScale`) + `flutter_animate` |
| Fonts | Google Fonts (Poppins) |
| Coords | `latlong2` |
| Env | `flutter_dotenv` |

---

## Directory Tree

```
lib/
  main.dart
  models/                              (empty — no typed models)
  providers/
  repositories/
  services/
  theme/
  utils/
  widgets/
    map/
  screens/
    passenger/
    driver/
```

---

## 1. Entry Point — `main.dart` (638 lines)

- **`main()`** — initializes `WidgetsFlutterBinding`, `FirebaseService`, runs app with `MultiProvider` wrapping `MaterialApp.router`
- **Providers registered:**
  - `ChangeNotifierProvider<ThemeProvider>`
  - `ChangeNotifierProvider<AuthProvider>`
  - `ChangeNotifierProvider<RideProvider>`
  - `ChangeNotifierProvider<PaymentProvider>`
- **`MaterialApp.router`** — uses `GoRouter` with `_SmoothPageTransitionBuilder` (slide + fade + scale, easeOutCubic)
- **`MyHomePage`** — checks biometric lock, then delegates to `RouterListener` for GoRouter
- **`BiometricLockScreen`** overlay — wraps entire app, auto-locks on app lifecycle pause
- **Page transition** — `_SmoothPageTransitionBuilder` (custom `PageTransitionsTheme` with `slide + fade + scale(0.98→1.0)`, 280ms, `easeOutCubic`)

---

## 2. Providers (state management)

### `auth_provider.dart`
- **State:** `currentUser` (Supabase `User?`), `isLoading`, `errorMessage`
- **Methods:** `signUp(email, password, name, role)`, `signIn(email, password)`, `sendOtp(email)`, `verifyOtp(email, token)`, `sendPasswordResetOtp(email)`, `updatePassword(newPassword)`, `updateUserRole(role)`, `signOut()`, `clearError()`

### `ride_provider.dart`
- **State:** `currentRideId`, `currentRideDetails` (`Map<String, dynamic>?`), `isLoading`, `errorMessage`
- **Methods:** `requestInstantRide(...)`, `acceptRide(rideId, driverId)`, `updateRideStatus(status)`, `clearRide()`
- **Realtime:** `_listenToCurrentRide()` — Supabase stream subscription on `rides` table

### `payment_provider.dart`
- **State:** `paymentMethods`, `transactions`, `totalEarnings`, `isLoading`
- **Methods:** `fetchPaymentMethods()`, `addPaymentMethod(card)`, `removePaymentMethod(id)`, `fetchTransactions()`, `fetchDriverEarnings()`, `processPayment(rideId, methodId)`

### `theme_provider.dart`
- **State:** `themeMode` (light / dark / system)
- **Persistence:** `SharedPreferences` key `theme_mode`

---

## 3. Repositories (data access)

| File | Key operations |
|---|---|
| `ride_repository.dart` | `requestRide()` (insert + call `matchmaker` edge fn), `acceptRide()` (RPC), `updateRideStatus()`, `getDriverCompletedRides()`, `listenToRequestedRides()` (stream) |
| `profile_repository.dart` | `getDriverProfile()`, `getPassengerProfile()`, `createOrUpdateDriverProfile()`, `updatePassengerProfile()` |
| `payment_repository.dart` | CRUD payment methods, transactions, driver earnings, `processPayment()` (calls `payments` edge fn) |
| `vehicle_repository.dart` | `registerVehicle()`, `getDriverVehicles()`, `getActiveVehicle()`, `setActiveVehicle()`, `deleteVehicle()` |
| `document_repository.dart` | `getDocuments()`, `uploadDocument()`, `updateDocumentStatus()` |
| `review_repository.dart` | `getReviewsForUser()`, `submitReview()` |
| `notification_repository.dart` | `getNotifications()`, `markAsRead()`, `registerDeviceForNotifications()` |
| `support_repository.dart` | `createTicket()` |

---

## 4. Services (external integrations)

| File | Role |
|---|---|
| `cloudinary_service.dart` | `uploadImage(File)` → Cloudinary URL |
| `device_biometrics_service.dart` | Device UUID → Supabase RPC `register_device_biometric` |
| `didit_verification_service.dart` | Create Didit session → launch `DiditSdk.startVerification()` |
| `email_notification_service.dart` | Resend transactional emails |
| `firebase_service.dart` | Singleton: init FCM, token management, message/refresh handlers |
| `location_search_service.dart` | Mapbox Geocoding: `searchLocation(query)` + `reverseGeocode(lat, lng)` |
| `register_fcm_token.dart` | Standalone fn: register FCM token with Supabase `devices` table |

---

## 5. Theme

### `app_colors.dart`
```
primary      = #EAB308 (gold/yellow)
background   = #EBE5E4 (light warm)
bgGradient   = #FFFBEB (cream)
text         = #111827 (dark gray)
white, black = standard
secondary    = #F5F5F5
softYellow   = #FEF08A
darkBg       = #08060D (dark mode background)
darkSurface  = #1E1E1E (dark mode surface)
darkText     = #F9FAFB
```

---

## 6. Utils

### `app_animations.dart`
- **`AppDurations`** — `fast` (180ms), `normal` (250ms), `slow` (320ms), `page` (280ms), `press` (80ms), `staggerGap` (60ms), `shimmer` (1200ms), `shake` (400ms)
- **`AppCurves`** — `easeOut`, `easeOutCubic`, `easeOutQuint`, `easeInOut`
- **`FadeSlideIn`** — fade + slide-up entry widget, configurable `duration`/`delay`/`slideOffset`
- **`PressScale`** — tap-down scale effect (default 0.97), uses `GestureDetector` + `AnimationController`
- **`StaggeredList`** — `Column` of `FadeSlideIn` children with staggered `staggerDelay`

### `custom_toast.dart`
- Wraps `toastification`: `showSuccess()`, `showError()`, `showInfo()`, `showWarning()`
- Unified `_show()` with configurable `title`, `description`, `duration`, `icon`

---

## 7. Widgets

### `custom_button.dart`
- **Variants:** `ButtonVariant.primary` (gold bg), `.secondary`, `.outline`
- **Status:** `ButtonStatus.normal`, `.loading` (spinner), `.success` (checkmark via Lottie), `.error`
- **Props:** `title`, `onPress`, `isDisabled`, `width`, `height`, `fontSize`
- **Animations:** `AnimatedSwitcher` for content swap, `AnimatedContainer` for color/border, `AnimatedScale` for press

### `shimmer_loading.dart`
- `ShimmerLoading` — base shimmer wrapper
- `ShimmerText`, `ShimmerCircle`, `ShimmerCard`, `ShimmerListItem`, `ShimmerList`
- Uses `flutter_animate` `.shimmer()` effect

### `animated_card.dart`
- `FadeSlideIn` entrance + `PressScale` feedback + `AnimatedContainer` shadow elevation on press

### `animated_list_item.dart`
- `FadeSlideIn` entrance + `PressScale` + optional `Dismissible` wrapper (swipe dismiss)

### `animated_input_field.dart`
- Animated focus border (color/width transition), error shake (`Curves.elasticIn`), success/error glow + icon states

### `premium_card.dart`
- Dual-shadow depth, `AnimatedScale` press (0.98), `FadeSlideIn` staggered entrance

### `premium_drawer.dart`
- Staggered `FadeSlideIn` animations for drawer header/items/footer

### `drawer_item.dart`
- `AnimatedScale` press (0.97), `AnimatedContainer` active highlight, `AnimatedSwitcher` icon, active dot indicator

### `fare_display.dart`
- Read-only fare amount with label, configurable `color`/`fontSize`/`showLabel`

### `status_banner.dart`
- `AnimatedSwitcher` (scale) for icon swap (hourglass ↔ checkmark), `AnimatedDefaultTextStyle`, `AnimatedContainer` for color/border

### `location_search_field.dart`
- Debounced Mapbox search, dropdown suggestions, current-location button
- Dropdown `maxHeight` = `MediaQuery.height * 0.28` clamped 80–220

### `ride_search_indicator.dart`
- **Searching state:** pulse/radar expanding ring (`AnimationController.repeat()` 1.5s), animated cycling dots (`_SearchingText`)
- **Found state:** cross-fades (via `AnimatedSwitcher` + `ScaleTransition`) to driver card with avatar, name, rating, car model, ETA, contact button
- `FadeSlideIn` entrance with 80ms delay

### `driver_offer_card.dart`
- `FadeSlideIn` bottom-up entrance
- `Dismissible` swipe-to-decline (horizontal)
- `PressScale` (0.99) tap feedback
- 3 staggered reveals (avatar→locations→buttons) with 60ms gaps
- Expandable "More details" section (distance, est. time, rating)
- `AnimatedRotation` on expand chevron

### `active_trip_card.dart`
- Status dot + header label, passenger avatar + name, fare badge, grouped location section, Contact + End ride buttons
- `FadeSlideIn` entrance
- Dual-tone bottom sheet styling

### Map widgets (`widgets/map/`)

| File | Purpose |
|---|---|
| `animated_marker.dart` | Static factory methods: `bounceIn()` (elastic scale via `_BounceInWrapper`), `pulse()` (repeating `_PulseMarker`), `locationDot()`, `pickupPin()`, `dropoffPin()` |
| `map_animator.dart` | `smoothMove(mapController, point, zoom)` with cubic ease-out + `fitBounds(mapController, bounds, options)` |
| `map_memory.dart` | Singleton: persists `lastPosition` (`LatLng`) + `lastZoom` (`double`) for cross-screen map continuity |

---

## 8. Screens — Auth & Onboarding

### `splash_screen.dart`
- 4-second delay → checks `Supabase.auth.currentUser`
  - No user → `/onboarding`
  - Has user, no profile → `/passenger-profile-setup` or `/driver-profile-setup`
  - Has user + profile → `/passenger-home` or `/driver-home`

### `onboarding_screen.dart`
- Car background image, "Klux VIP" header, subtitle, two CTA cards (driver / passenger)
- Each card: icon + title + subtitle, `Navigator.push` with role param

### `sign_in_screen.dart`
- Email + password fields, "Forgot password?", Sign In button, Sign Up link
- Biometric auto-login: checks `local_auth` → `auth.signInWithBiometric()` if enabled
- Social buttons (Google, Apple) — static, no implementation

### `sign_up_screen.dart`
- Full name + email + password fields, "I agree to Terms & Privacy", Sign Up button
- Reads `role` from query params
- On success → navigates to `/otp`

### `role_selection_screen.dart`
- Three cards: Affiliate, Driver, Passenger
- Each: icon + title + short description
- Sets role via `auth.updateUserRole()` → navigates to profile setup

### `otp_screen.dart`
- 6-digit PIN input (`pinput` package), 60-second resend timer, auto-verify on complete
- Handles signup OTP, password-reset OTP based on query params
- On success → navigates to profile setup or home

### `forgot_password_screen.dart`
- Email field → sends OTP → navigates to `/otp` with `isPasswordReset=true`

### `new_password_screen.dart`
- New password + confirm password fields → calls `auth.updatePassword()`

---

## 9. Screens — Profile Setup

### `driver_profile_setup_screen.dart`
- First name, last name, DOB, gender dropdown, country dropdown, profile photo picker (→ Cloudinary)
- **Style:** glassmorphic container with `BackdropFilter` blur + subtle border
- Creates/updates driver profile in Supabase → `/driver-id-verification`

### `passenger_profile_setup_screen.dart`
- First name, last name, gender, country, preferred categories (multi-select chips), profile photo
- Travel preferences: "Ready to explore new destinations?", "Love comfort and luxury?"
- Creates passenger profile → `/passenger-home`

### `driver_id_verification_screen.dart`
- Didit SDK KYC flow: "Start Verification" → creates session → launches Didit SDK
- On success: sends confirmation email, navigates to `/vehicle-registration`
- States: idle, loading, verifying, completed, error

### `vehicle_registration_screen.dart`
- Make, model, year, color, license plate fields + photo upload
- Registers vehicle via `VehicleRepository` → `/driver-home`

---

## 10. Screens — Passenger

### `passenger_home_screen.dart` (675 lines)
- **Map:** `FlutterMap` with Mapbox tiles, `MapController`, `MapMemory` init/dispose
- **Markers:** `AnimatedMarker.pulse()` + `AnimatedMarker.locationDot()` at current position
- **Drawer:** `PremiumDrawer` with `DrawerItem`s (Profile, Ride History, Saved Places, Notifications, Settings, Support, Privacy, Logout)
- **UI:** Menu button (top-left), profile avatar (top-right), "Where to?" input + "Book a ride" button (bottom)
- **Booking flow:** "Book a ride" → `/booking-selection`
- On init: fetches profile, gets current location via `Geolocator`

### `booking_selection_screen.dart`
- Three premium-style option cards:
  - **Instant Booking** — "Ride now", clock icon, subtitle
  - **Schedule Booking** — "Ride later", calendar icon
  - **Special Booking** — "Special event", star icon
- Each navigates to respective booking screen

### `instant_booking_screen.dart` (594 lines)
- **Map:** Full-screen `FlutterMap` with pickup/dropoff markers, `MapMemory` persistence
- **DraggableScrollableSheet** (0.08–0.75):
  - Passengers count (numeric input), Comments (dialog)
  - Location inputs: Current Location (green dot) + Where to (red pin) — uses `LocationSearchField`
  - **Fare input** — `_AnimatedFareInput` widget: pulsing glow animation, `AnimatedSwitcher` on value, border highlight
  - "Find a driver" button → calls `RideProvider.requestInstantRide()` → matches via edge function → `/trip-summary`

### `schedule_booking_screen.dart` (732 lines)
- Date + time picker, same map/location/fare layout as instant
- Simulated 4-second search delay, no real provider call
- `MapController` + `MapMemory` + `AnimatedMarker.locationDot`

### `special_booking_screen.dart` (649 lines)
- "Request estimate" label, date/time + locations + comment
- Simulated search, no real provider call
- `MapController` + `MapMemory` + `AnimatedMarker.locationDot`

### `trip_summary_screen.dart` (336 lines)
- **Map:** Polyline layer + `AnimatedMarker` (locationDot, pickupPin, dropoffPin)
- **RideSearchIndicator** (top): pulse radar while searching; driver card (avatar, name, rating, ETA, contact) when found/active
- **Bottom sheet** (dynamic via `Consumer<RideProvider>`):
  - Status == `requested` → trip summary (passengers, locations, fare, payment method, Done)
  - Status == `in_progress` → `ActiveTripCard` (trip status, passenger info, end ride)
- Polls `RideProvider.currentRideDetails['status']` for real-time state

### `payment_method_screen.dart`
- List saved cards (brand, last4, expiry), "Add card" button, card selector bottom sheet
- Process payment → `/payment-successful`
- Each card: colored brand icon + number + expiry + checkmark if selected

### `payment_successful_screen.dart`
- Large checkmark animation + rotating ring + confetti particles
- "Done" button → context pops to home
- Top: "Payment Successful" with status icons

### `ride_history_screen.dart`
- **Placeholder:** "Ride history coming soon." text

### `saved_places_screen.dart`
- **Placeholder:** "You have not saved any place" with location icon

### `notifications_screen.dart`
- **Placeholder:** "You have no new notifications." with bell icon

### `passenger_profile_screen.dart`
- Avatar + name + email, stats row (rides/trips/points), menu items (Edit Profile, Saved Places, Payment, Ride History, Notifications, Settings, Support, Privacy, Logout)
- Each item navigates to respective screen

### `edit_profile_screen.dart`
- First name, last name fields, profile photo (tap → picker → Cloudinary upload), Save button

---

## 11. Screens — Driver

### `driver_home_screen.dart` (586 lines)
- **Tabs:** "Available" (Tab 1) | "Completed" (Tab 2) — `TabController` with segmented pill style
- **Available tab:** `StreamBuilder` on `listenToRequestedRides()` → `AnimatedSwitcher` wrapping list of `DriverOfferCard`s (swipe-dismiss, accept, expandable details)
- **Completed tab:** `FutureBuilder` on `getDriverCompletedRides()` → list of completed ride summary cards
- **Drawer:** `PremiumDrawer` + `DrawerItem`s (Earnings/Wallet, Ride History, Vehicle Management, Performance, Support, Settings)
- **Header:** Menu icon + segmented tab bar + profile avatar

### `active_ride_screen.dart` (116 lines)
- **Map:** Full-screen `FlutterMap` with `AnimatedMarker.locationDot`
- **Bottom:** `ActiveTripCard` via `Consumer<RideProvider>` — passenger name, pickup/dropoff, fare, status, time elapsed, "End ride" button
- **Back button** top-left

### `start_ride_screen.dart` (200 lines)
- **Map:** Full-screen `FlutterMap` with `AnimatedMarker.locationDot` + route `PolylineLayer`
- **Bottom sheet:** "Waiting time" label with live timer (`Timer.periodic` 1s), "Start the ride" button → `updateRideStatus('in_progress')` → `/active-ride`, Cancel button

### `end_ride_confirmation_screen.dart` (329 lines)
- **Map:** Full-screen with route polyline + markers
- **Bottom sheet (glassmorphic):** `BackdropFilter` blur, "Ride completed?" text, pickup/dropoff addresses (from ride details), "Yes" button → `updateRideStatus('completed')` → `clearRide()` → `/ride-payment-received`
- **Style:** Frosted glass with subtle border + white/gold accents

### `ride_payment_received_screen.dart` (334 lines)
- Full-screen confetti overlay + rotating ring animation + elastic checkmark
- "$140 Received" text, "You can continue working" subtitle
- Animated star decorations, "Back to home" button → `/driver-home`

### `confirm_arrival_screen.dart` (338 lines)
- **Map:** `FlutterMap` + markers + route polyline
- **Bottom sheet:** Status dot + "Confirmation of arrival" header, trip info preview (pickup/dropoff), "Confirm arrival" button → `updateRideStatus('arriving')` → `/start-ride`, Cancel button
- `.animate().slideY().fadeIn()` entrance via `flutter_animate`

### `account_screen.dart` (336 lines)
- **Header:** Balance amount + account number + currency
- **Tabs:** "Earnings" | "Withdraw" | "History"
- **Earnings tab:** Total earnings card, today/this week/month stats, earnings list
- **Withdraw tab:** Bank account cards + "Withdraw" button → `/withdraw-method`
- **History tab:** Transaction history list
- All data from `PaymentProvider`

### `withdraw_method_screen.dart` (176 lines)
- Four method cards: Bank, Payoneer, Coinbase, PayPal
- Bank → `/add-bank-account`, others show "Coming soon"

### `add_bank_account_screen.dart` (370 lines)
- Bank name, account name, account number, routing number, SWIFT/BIC fields
- Bottom sheet for setting/confirming 4-digit PIN
- Saves via `PaymentRepository` → `/withdraw-to-bank`

### `withdraw_to_bank_screen.dart` (281 lines)
- Confirm bank details, enter amount, verify PIN, optional fingerprint
- Submits withdrawal request → success toast + pop to account

### `driver_profile_screen.dart` (199 lines)
- Profile header: avatar + name + rating
- Menu items: Edit Profile, Vehicle Info, ID Documents
- Each navigates to respective edit/view screen

### `driver_edit_profile_screen.dart` (282 lines)
- First/last name fields, profile photo with camera/gallery picker → Cloudinary upload, Save button

### `driver_performance_screen.dart` (250 lines)
- Average rating display (large number + stars), stats grid (on-time, cancellations, response rate), rating breakdown bars, recent reviews list

### `driver_ride_history_screen.dart` (27 lines)
- **Placeholder:** "Completed trips will appear here."

### `vehicle_info_screen.dart` (228 lines)
- Read-only display: make, model, year, color, license plate, vehicle photos
- Edit button removes + re-adds vehicle

### `vehicle_management_screen.dart` (325 lines)
- List of registered vehicles with active indicator
- "Add Vehicle" modal bottom sheet (make/model/year/color/license)
- Set active, delete options
- Bottom: active vehicle info or "Register a vehicle" CTA

### `id_verification_documents_screen.dart` (284 lines)
- Status card: pending/verified/rejected with colored icon
- Uploaded documents list (type, status badge, date)
- "Re-verify" button if rejected → relaunches Didit SDK

---

## 12. Screens — Shared

### `settings_screen.dart`
- Push notifications toggle, Face ID / biometric toggle, Theme selector (System / Light / Dark), Logout button

### `support_screen.dart`
- Category dropdown (Payment, Technical, Account, Other), Subject + Description fields, Submit button → creates ticket via `SupportRepository`

### `ride_review_screen.dart`
- 5-star rating bar (tap to select), optional comment field, Submit button → creates review via `ReviewRepository`
- Receives `rideId`, `revieweeId`, `revieweeName` from query params

### `privacy_policy_screen.dart`
- Static placeholder text block

---

## 13. Route Table

| Path | Screen |
|---|---|
| `/` | SplashScreen |
| `/onboarding` | OnboardingScreen |
| `/sign-in` | SignInScreen |
| `/sign-up` | SignUpScreen |
| `/forgot-password` | ForgotPasswordScreen |
| `/new-password` | NewPasswordScreen |
| `/otp` | OtpScreen |
| `/role-selection` | RoleSelectionScreen |
| `/driver-profile-setup` | DriverProfileSetupScreen |
| `/passenger-profile-setup` | PassengerProfileSetupScreen |
| `/passenger-profile` | PassengerProfileScreen |
| `/driver-id-verification` | DriverIdVerificationScreen |
| `/vehicle-registration` | VehicleRegistrationScreen |
| `/ride-review` | RideReviewScreen |
| `/passenger-home` | PassengerHomeScreen |
| `/booking-selection` | BookingSelectionScreen |
| `/instant-booking` | InstantBookingScreen |
| `/schedule-booking` | ScheduleBookingScreen |
| `/special-booking` | SpecialBookingScreen |
| `/trip-summary` | TripSummaryScreen |
| `/payment-method` | PaymentMethodScreen |
| `/payment-successful` | PaymentSuccessfulScreen |
| `/ride-history` | RideHistoryScreen |
| `/saved-places` | SavedPlacesScreen |
| `/notifications` | NotificationsScreen |
| `/settings` | SettingsScreen |
| `/support` | SupportScreen |
| `/privacy-policy` | PrivacyPolicyScreen |
| `/driver-home` | DriverHomeScreen |
| `/driver-profile` | DriverProfileScreen |
| `/driver-edit-profile` | DriverEditProfileScreen |
| `/confirm-arrival` | ConfirmArrivalScreen |
| `/start-ride` | StartRideScreen |
| `/active-ride` | ActiveRideScreen |
| `/end-ride-confirmation` | EndRideConfirmationScreen |
| `/ride-payment-received` | RidePaymentReceivedScreen |
| `/account` | AccountScreen |
| `/withdraw-method` | WithdrawMethodScreen |
| `/add-bank-account` | AddBankAccountScreen |
| `/withdraw-to-bank` | WithdrawToBankScreen |
| `/driver-ride-history` | DriverRideHistoryScreen |
| `/vehicle-management` | VehicleManagementScreen |
| `/vehicle-info` | VehicleInfoScreen |
| `/driver-performance` | DriverPerformanceScreen |
| `/driver-id-documents` | IdVerificationDocumentsScreen |
| `/edit-profile` | EditProfileScreen |

---

## 14. Passenger Flow

```
Splash → Onboarding → Sign Up → OTP → Role Selection (Passenger)
  → Passenger Profile Setup → Passenger Home
  → Booking Selection → Instant/Schedule/Special Booking
  → Trip Summary (searching → driver found → in progress)
  → Payment Method → Payment Successful → Review
```

## 15. Driver Flow

```
Splash → Onboarding → Sign Up → OTP → Role Selection (Driver)
  → Driver Profile Setup → ID Verification (Didit) → Vehicle Registration
  → Driver Home → Accept Offer → Confirm Arrival
  → Start Ride → Active Ride → End Ride Confirmation
  → Payment Received → Review
  → Account (Earnings / Withdraw / Bank)
```

## 16. Ride Status Lifecycle

```
requested → (driver accepts via RPC) → arriving
  → (driver taps "Confirm arrival") → in_progress
  → (driver taps "Start the ride") → in_progress
  → (driver taps "End ride" + "Yes") → completed
```

## 17. Placeholder Screens

| Screen | Text |
|---|---|
| `ride_history_screen.dart` | "Ride history coming soon." |
| `saved_places_screen.dart` | "You have not saved any place" |
| `notifications_screen.dart` | "You have no new notifications." |
| `driver_ride_history_screen.dart` | "Completed trips will appear here." |

## 18. Design Conventions

- **Dark mode detection:** All screens use `final isDark = Theme.of(context).brightness == Brightness.dark`
- **Back navigation:** GoRouter `context.pop()` throughout
- **No typed models:** All data is raw `Map<String, dynamic>`
- **No dependency injection:** Services/repos instantiated directly (e.g., `ProfileRepository()`)
- **Map screens:** Consistent pattern: `FlutterMap` + Mapbox tiles + `MapMemory` singleton + `AnimatedMarker`
- **Driver screens:** Glassmorphic UI (`BackdropFilter` blur + semi-transparent containers + subtle borders)
- **Animations:** `flutter_animate` chains (`.animate().fadeIn().slideY()`) with staggered delays; custom `FadeSlideIn`/`PressScale` for reusable patterns
- **Container styling:** `BorderRadius.circular(30)` for bottom sheets, `BorderRadius.circular(16/20)` for cards, `BorderRadius.circular(24)` for buttons
