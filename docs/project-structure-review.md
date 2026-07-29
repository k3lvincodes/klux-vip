# Project Structure Review

> **Date:** July 29, 2026
> **Reviewer:** opencode/big-pickle
> **Scope:** Full project structure audit — Flutter app, React website, root monorepo, documentation, configs

---

## Table of Contents

1. [Current Structure](#1-current-structure)
2. [Issues Found](#2-issues-found)
3. [Recommended Structure](#3-recommended-structure)
4. [Migration Guide](#4-migration-guide)
5. [Summary](#5-summary)

---

## 1. Current Structure

### 1.1 Root Level

```
klux-vip/
├── .git/
├── .gitignore
├── .vscode/
├── README.md
├── rules.md                    # Project rules
├── structure.md                # App structure docs
├── backend.md                  # Backend plan
├── color.md                    # Color palette
├── build/                      # Empty/unnecessary
├── docs/                       # More docs
│   ├── app-bugs.md
│   ├── app-critical-issues.md
│   ├── app-errors.md
│   ├── db_proposal.md
│   ├── test-results.md
│   ├── todo.md
│   └── unused-architecture.md
├── app/                        # Flutter mobile app
└── website/                    # React website + admin
```

### 1.2 Flutter App (`app/`)

```
app/
├── .env / .env.example
├── pubspec.yaml
├── analysis_options.yaml
├── klux_vip.iml
├── generate_logos.py           # Loose Python scripts
├── remove_bg.py                # at root level
├── analyze_logo.py
├── test2.dart                  # Loose test files
├── test_didit.dart             # at root level
├── test_didit_v3.dart
├── analyze_errors.txt
├── devtools_options.yaml
├── .metadata
├── android/ ios/ linux/ macos/ web/ windows/
├── assets/
│   └── images/                 # 9 image files
├── test/
│   └── widget_test.dart        # Only 1 test file
├── supabase/
│   ├── .temp/
│   ├── clear_all_data.sql
│   ├── deno.json
│   ├── functions/              # 9 edge functions
│   │   ├── create-booking/index.ts
│   │   ├── didit-lookup/index.ts
│   │   ├── didit-webhook/index.ts
│   │   ├── email-notifications/index.ts
│   │   ├── matchmaker/index.ts
│   │   ├── notifications/index.ts
│   │   ├── payments/index.ts
│   │   ├── sms-notifications/index.ts
│   │   └── stripe-webhook/index.ts
│   └── migrations/             # 5 SQL migrations
│       ├── 20260401000000_initial_schema.sql
│       ├── 20260520000001_seed_admin.sql
│       ├── 20260623000001_add_stripe_webhook.sql
│       ├── 20260728000000_booking_system.sql
│       └── 20260729000000_fix_admin_dashboard_stats.sql
└── lib/                        # 106 Dart files, 26,438 LOC
    ├── main.dart               # Entry point (638 lines — large)
    ├── config/
    │   └── env_config.dart     # 1 file
    ├── models/                 # 9 files
    │   ├── driver_document.dart
    │   ├── notification.dart
    │   ├── payment_method.dart
    │   ├── review.dart
    │   ├── ride.dart
    │   ├── support_ticket.dart
    │   ├── transaction.dart
    │   ├── user_profile.dart
    │   └── vehicle.dart
    ├── providers/              # 5 files
    │   ├── auth_provider.dart
    │   ├── booking_provider.dart
    │   ├── payment_provider.dart
    │   ├── ride_provider.dart
    │   └── theme_provider.dart
    ├── repositories/           # 8 files
    │   ├── document_repository.dart
    │   ├── notification_repository.dart
    │   ├── payment_repository.dart
    │   ├── profile_repository.dart
    │   ├── review_repository.dart
    │   ├── ride_repository.dart
    │   ├── support_repository.dart
    │   └── vehicle_repository.dart
    ├── screens/                # 50 files
    │   ├── (root)              # 17 shared/auth screens
    │   │   ├── driver_id_verification_screen.dart
    │   │   ├── driver_profile_setup_screen.dart
    │   │   ├── forgot_password_screen.dart
    │   │   ├── new_password_screen.dart
    │   │   ├── onboarding_screen.dart
    │   │   ├── otp_screen.dart
    │   │   ├── passenger_profile_setup_screen.dart
    │   │   ├── privacy_policy_screen.dart
    │   │   ├── ride_review_screen.dart
    │   │   ├── role_selection_screen.dart
    │   │   ├── settings_screen.dart
    │   │   ├── sign_in_screen.dart
    │   │   ├── sign_up_screen.dart
    │   │   ├── splash_screen.dart
    │   │   ├── support_screen.dart
    │   │   ├── terms_of_service_screen.dart
    │   │   └── vehicle_registration_screen.dart
    │   ├── driver/             # 18 driver screens
    │   │   ├── account_screen.dart
    │   │   ├── active_ride_screen.dart
    │   │   ├── add_bank_account_screen.dart
    │   │   ├── confirm_arrival_screen.dart
    │   │   ├── driver_edit_profile_screen.dart
    │   │   ├── driver_home_screen.dart
    │   │   ├── driver_performance_screen.dart
    │   │   ├── driver_profile_screen.dart
    │   │   ├── driver_ride_history_screen.dart
    │   │   ├── end_ride_confirmation_screen.dart
    │   │   ├── id_verification_documents_screen.dart
    │   │   ├── rate_client_screen.dart
    │   │   ├── ride_payment_received_screen.dart
    │   │   ├── start_ride_screen.dart
    │   │   ├── vehicle_info_screen.dart
    │   │   ├── vehicle_management_screen.dart
    │   │   ├── withdraw_method_screen.dart
    │   │   └── withdraw_to_bank_screen.dart
    │   └── passenger/          # 16 passenger screens
    │       ├── booking_invoice_screen.dart
    │       ├── booking_payment_screen.dart
    │       ├── booking_selection_screen.dart
    │       ├── edit_profile_screen.dart
    │       ├── instant_booking_screen.dart
    │       ├── notifications_screen.dart
    │       ├── passenger_home_screen.dart
    │       ├── passenger_profile_screen.dart
    │       ├── payment_method_screen.dart
    │       ├── payment_successful_screen.dart
    │       ├── ride_history_screen.dart
    │       ├── saved_places_screen.dart
    │       ├── schedule_booking_screen.dart
    │       ├── special_booking_screen.dart
    │       ├── tip_selection_screen.dart
    │       └── trip_summary_screen.dart
    ├── services/               # 9 files
    │   ├── auth_routing_service.dart
    │   ├── cloudinary_service.dart
    │   ├── device_biometrics_service.dart
    │   ├── didit_verification_service.dart
    │   ├── email_notification_service.dart
    │   ├── fare_rate_service.dart
    │   ├── firebase_service.dart
    │   ├── location_search_service.dart
    │   └── register_fcm_token.dart
    ├── theme/                  # 1 file
    │   └── app_colors.dart
    ├── utils/                  # 2 files
    │   ├── app_animations.dart
    │   └── custom_toast.dart
    └── widgets/                # 19 files
        ├── active_trip_card.dart
        ├── active_trip_chat_sheet.dart
        ├── animated_card.dart
        ├── animated_input_field.dart
        ├── animated_list_item.dart
        ├── biometric_lock_screen.dart
        ├── custom_button.dart
        ├── drawer_item.dart
        ├── driver_offer_card.dart
        ├── fare_display.dart
        ├── location_search_field.dart
        ├── premium_card.dart
        ├── premium_drawer.dart
        ├── ride_search_indicator.dart
        ├── shimmer_loading.dart
        ├── status_banner.dart
        └── map/
            ├── animated_marker.dart
            ├── map_animator.dart
            └── map_memory.dart
```

### 1.3 React Website (`website/`)

```
website/
├── .env / .env.example
├── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json / tsconfig.app.json / tsconfig.node.json
├── eslint.config.js
├── public/                    # 43 static assets (images)
├── dist/                      # Build output
└── src/                       # 56 files, 8,350 LOC
    ├── App.tsx / App.css / index.css / main.tsx
    ├── assets/                # 3 files (hero.png, react.svg, vite.svg)
    ├── components/            # 7 files (flat)
    │   ├── ErrorBoundary.tsx
    │   ├── FAQ.tsx
    │   ├── Footer.tsx
    │   ├── LanguageSwitcher.tsx
    │   ├── Navbar.tsx
    │   ├── ProtectedRoute.tsx
    │   └── PublicLayout.tsx
    ├── context/               # 1 file
    │   └── AuthContext.tsx
    ├── i18n/                  # 15 files
    │   ├── formatters.ts
    │   ├── index.ts
    │   └── locales/           # 13 locale directories
    │       ├── ar/ en-AU/ en-CA/ en-GB/ en-NG/ en-US/
    │       ├── es-US/ fr-CA/ ha-NG/ ig-NG/ pcm-NG/ pt-BR/ yo-NG/
    ├── lib/                   # 1 file
    │   └── supabase.ts
    ├── pages/                 # 12 public pages
    │   ├── AboutUs.tsx
    │   ├── AdminLogin.tsx
    │   ├── BookingPage.tsx
    │   ├── Contact.tsx
    │   ├── CookiesPage.tsx
    │   ├── Fleets.tsx
    │   ├── HowItWorks.tsx
    │   ├── LandingPage.tsx
    │   ├── PrivacyPolicy.tsx
    │   ├── Services.tsx
    │   ├── TermsConditions.tsx
    │   ├── Testimonials.tsx
    │   └── admin/             # 11 admin pages
    │       ├── AdminLayout.tsx
    │       ├── DocumentsPage.tsx
    │       ├── DriversPage.tsx
    │       ├── Overview.tsx
    │       ├── PricingPage.tsx
    │       ├── RidesPage.tsx
    │       ├── SupportPage.tsx
    │       ├── TransactionsPage.tsx
    │       ├── UserDetail.tsx
    │       ├── UsersPage.tsx
    │       └── VehiclesPage.tsx
    └── styles/                # 2 CSS files
        ├── admin.css
        └── admin-login.css
```

---

## 2. Issues Found

### 2.1 Root Level Issues

| # | Severity | Issue | Details |
|---|----------|-------|---------|
| R1 | 🟠 High | **Documentation scattered across root and docs/** | `rules.md`, `structure.md`, `backend.md`, `color.md` are at root. `docs/` has 7 more files. No single source of truth. |
| R2 | 🟡 Medium | **Root `build/` directory** | Empty/unnecessary build artifacts at root level. Should be gitignored or removed. |
| R3 | 🟢 Low | **No monorepo tooling** | No `pnpm-workspace.yaml`, `turbo.json`, or `nx.json` for managing app/ and website/ together. |
| R4 | 🟢 Low | **No CI/CD config** | No `.github/workflows/` or deployment scripts. |
| R5 | 🟢 Low | **No root `.env.example`** | Each sub-project has its own, but no unified env reference at root. |

---

### 2.2 Flutter App Issues

| # | Severity | Issue | Details |
|---|----------|-------|---------|
| F1 | 🔴 Critical | **`main.dart` is 638 lines** | Entry point is bloated — contains providers, router config, biometric lock screen, page transitions, and the entire app shell. Should be split into focused modules. |
| F2 | 🟠 High | **Loose files at `app/` root** | `test2.dart`, `test_didit.dart`, `test_didit_v3.dart` — test files scattered at root, not in `test/`. `generate_logos.py`, `remove_bg.py`, `analyze_logo.py` — Python scripts at app root. `analyze_errors.txt` — stale output file. |
| F3 | 🟠 High | **Only 1 test file** | `test/widget_test.dart` exists. 106 Dart files with 0 meaningful test coverage. |
| F4 | 🟠 High | **`theme/` has only 1 file** | `app_colors.dart` is the only theme file. No typography, no spacing, no component themes, no dark/light mode definitions in a theme file. |
| F5 | 🟡 Medium | **`config/` has only 1 file** | `env_config.dart` sits alone. Could include app-wide constants, feature flags, API versioning. |
| F6 | 🟡 Medium | **`utils/` has only 2 files** | `app_animations.dart` and `custom_toast.dart`. Could include formatters, validators, date helpers, etc. |
| F7 | 🟡 Medium | **17 shared screens at `screens/` root** | Auth screens (sign_in, sign_up, otp, forgot_password, new_password), profile setup screens, onboarding, settings, support, privacy, terms — all mixed together at screens root without sub-grouping. |
| F8 | 🟡 Medium | **No barrel files / exports.dart** | Every import is a full path. No centralized export file for clean imports across the app. |
| F9 | 🟡 Medium | **`widgets/map/` is the only nested widget directory** | Other complex widget groups (e.g., booking flow widgets, payment widgets) are not grouped. |
| F10 | 🟢 Low | **Supabase functions live inside `app/`** | `app/supabase/` contains edge functions and migrations. These are backend code, not Flutter app code. The `supabase/` directory conceptually belongs at the project root or in a dedicated `backend/` directory. |
| F11 | 🟢 Low | **No `README.md` in `app/`** | The Flutter app has no dedicated README for setup, architecture overview, or contributing guidelines. |

---

### 2.3 React Website Issues

| # | Severity | Issue | Details |
|---|----------|-------|---------|
| W1 | 🔴 Critical | **`BookingPage.tsx` is 998 lines** | Single file handles map, booking form, fare calculation, payment, confirmation. Should be split into 4-5 focused components. |
| W2 | 🟠 High | **`components/` is flat with 7 unrelated files** | `ErrorBoundary`, `FAQ`, `Footer`, `LanguageSwitcher`, `Navbar`, `ProtectedRoute`, `PublicLayout` — no grouping by feature or type. |
| W3 | 🟠 High | **No shared types/interfaces** | No `types/` or `interfaces/` directory. Types are defined inline in each file (e.g., `BookingFormData` in BookingPage, `UserProfile` in UserDetail). |
| W4 | 🟠 High | **No hooks directory** | No `hooks/` for custom React hooks. Auth logic, data fetching, form validation are all inline in components. |
| W5 | 🟡 Medium | **No constants/config directory** | No `constants/` for API endpoints, route paths, error messages, or app configuration. Values are hardcoded across files. |
| W6 | 🟡 Medium | **Mixed styling approaches** | `index.css` (public pages), `App.css` (empty), `admin.css`, `admin-login.css` (admin), inline styles in BookingPage, non-functional Tailwind classes in ProtectedRoute/AdminLayout. 4+ styling approaches. |
| W7 | 🟡 Medium | **`pages/` has 12 public pages in flat directory** | No grouping by feature (e.g., legal pages together, booking-related together). |
| W8 | 🟡 Medium | **`admin/` has 11 pages in flat directory** | Related pages not grouped (e.g., `UsersPage` + `UserDetail` should be together, `RidesPage` + `TransactionsPage` are ride-related). |
| W9 | 🟢 Low | **`lib/` has only `supabase.ts`** | A `lib/` directory with a single file. Could be merged into `context/` or `config/`. |
| W10 | 🟢 Low | **`assets/` has `react.svg` and `vite.svg`** | Default Vite template assets still present — not used in production. |

---

### 2.4 Cross-Cutting Issues

| # | Severity | Issue | Details |
|---|----------|-------|---------|
| C1 | 🟠 High | **No shared types between app and website** | Both projects define their own `UserProfile`, `Ride`, `Vehicle` types independently. No shared schema or type definitions. |
| C2 | 🟠 High | **Supabase client duplicated** | `app/lib/services/` has Supabase setup. `website/src/lib/supabase.ts` has its own. Edge functions in `app/supabase/` use yet another. Three different Supabase client configurations. |
| C3 | 🟡 Medium | **No shared constants** | Color palette defined in `color.md` (root) and `app_colors.dart` (Flutter) and `index.css` (website). No single source of truth for design tokens. |
| C4 | 🟡 Medium | **Edge functions inside Flutter app** | Backend code (`app/supabase/functions/`) lives inside the Flutter project directory. Deploying backend requires navigating into the mobile app folder. |
| C5 | 🟢 Low | **No unified linting/formatting** | Flutter uses `analysis_options.yaml`, website uses `eslint.config.js`. No shared code style conventions across the monorepo. |

---

## 3. Recommended Structure

### 3.1 Root Level — Monorepo

```
klux-vip/
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Run tests + lint on PR
│       ├── deploy-website.yml        # Deploy website to Vercel/Netlify
│       └── deploy-functions.yml      # Deploy Supabase edge functions
│
├── .vscode/
│   └── settings.json
│
├── docs/                             # ALL documentation here (single source)
│   ├── architecture.md               # System architecture overview
│   ├── api-reference.md              # Edge function API docs
│   ├── color-palette.md              # Was color.md — design tokens
│   ├── project-rules.md              # Was rules.md — conventions
│   ├── backend-plan.md               # Was backend.md — backend roadmap
│   ├── structure-flutter.md          # Was structure.md — Flutter app docs
│   ├── structure-website.md          # NEW — website architecture docs
│   ├── bugs/                         # Bug tracking
│   │   ├── app-bugs.md
│   │   ├── app-critical-issues.md
│   │   └── app-errors.md
│   ├── testing/
│   │   └── test-results.md
│   └── planning/
│       ├── todo.md
│       └── unused-architecture.md
│
├── app/                              # Flutter mobile app (unchanged location)
├── backend/                          # Supabase backend (moved from app/supabase/)
│   ├── functions/                    # Edge functions
│   │   ├── create-booking/
│   │   ├── didit-lookup/
│   │   ├── didit-webhook/
│   │   ├── email-notifications/
│   │   ├── matchmaker/
│   │   ├── notifications/
│   │   ├── payments/
│   │   ├── sms-notifications/
│   │   └── stripe-webhook/
│   ├── migrations/                   # SQL migrations
│   │   ├── 20260401000000_initial_schema.sql
│   │   ├── 20260520000001_seed_admin.sql
│   │   ├── 20260623000001_add_stripe_webhook.sql
│   │   ├── 20260728000000_booking_system.sql
│   │   └── 20260729000000_fix_admin_dashboard_stats.sql
│   ├── deno.json
│   └── README.md
│
├── website/                          # React website (unchanged location)
│
├── shared/                           # NEW — shared types and constants
│   ├── types/
│   │   ├── ride.ts                   # Ride, RideStatus, RideType
│   │   ├── user.ts                   # UserProfile, DriverProfile, PassengerProfile
│   │   ├── vehicle.ts                # Vehicle
│   │   ├── payment.ts                # PaymentMethod, Transaction
│   │   └── index.ts                  # Barrel export
│   ├── constants/
│   │   ├── colors.ts                 # Single source for design tokens
│   │   ├── routes.ts                 # Route path constants
│   │   └── index.ts
│   └── README.md
│
├── README.md                         # Project README
├── .gitignore
├── .env.example                      # Unified env reference
├── pnpm-workspace.yaml               # Monorepo config (or turbo.json)
└── turbo.json                        # Optional: Turborepo config
```

---

### 3.2 Flutter App — Recommended

```
app/
├── lib/
│   ├── main.dart                     # SLIM: ~50 lines — init + run app
│   ├── app.dart                      # MaterialApp.router + providers setup
│   │
│   ├── core/                         # NEW — shared infrastructure
│   │   ├── constants/
│   │   │   ├── app_constants.dart    # App-wide constants (name, version, etc.)
│   │   │   ├── api_constants.dart    # API endpoints, timeout values
│   │   │   ├── asset_paths.dart      # Image/icon paths
│   │   │   └── index.dart            # Barrel
│   │   ├── theme/
│   │   │   ├── app_colors.dart       # Color palette
│   │   │   ├── app_theme.dart        # ThemeData definitions (light + dark)
│   │   │   ├── app_text_styles.dart  # Typography
│   │   │   ├── app_spacing.dart      # Spacing constants
│   │   │   └── index.dart
│   │   ├── router/
│   │   │   ├── app_router.dart       # GoRouter config (was in main.dart)
│   │   │   ├── route_names.dart      # Route path constants
│   │   │   └── index.dart
│   │   ├── utils/
│   │   │   ├── app_animations.dart   # Was in utils/
│   │   │   ├── custom_toast.dart     # Was in utils/
│   │   │   ├── formatters.dart       # NEW — date, currency, phone formatters
│   │   │   ├── validators.dart       # NEW — form validation helpers
│   │   │   └── index.dart
│   │   ├── network/
│   │   │   ├── supabase_client.dart  # Single Supabase client init
│   │   │   └── index.dart
│   │   └── extensions/
│   │       ├── context_extensions.dart  # NEW — BuildContext helpers
│   │       └── index.dart
│   │
│   ├── features/                     # NEW — feature-based organization
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── auth_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── sign_in_screen.dart
│   │   │       ├── sign_up_screen.dart
│   │   │       ├── otp_screen.dart
│   │   │       ├── forgot_password_screen.dart
│   │   │       └── new_password_screen.dart
│   │   │
│   │   ├── onboarding/
│   │   │   └── screens/
│   │   │       ├── splash_screen.dart
│   │   │       ├── onboarding_screen.dart
│   │   │       └── role_selection_screen.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   │   └── profile_repository.dart
│   │   │   └── screens/
│   │   │       ├── driver_profile_setup_screen.dart
│   │   │       ├── passenger_profile_setup_screen.dart
│   │   │       ├── driver_profile_screen.dart
│   │   │       ├── passenger_profile_screen.dart
│   │   │       ├── edit_profile_screen.dart
│   │   │       └── driver_edit_profile_screen.dart
│   │   │
│   │   ├── booking/
│   │   │   ├── data/
│   │   │   │   ├── ride_repository.dart
│   │   │   │   └── fare_rate_service.dart
│   │   │   ├── providers/
│   │   │   │   ├── ride_provider.dart
│   │   │   │   └── booking_provider.dart
│   │   │   └── screens/
│   │   │       ├── passenger_home_screen.dart
│   │   │       ├── booking_selection_screen.dart
│   │   │       ├── instant_booking_screen.dart
│   │   │       ├── schedule_booking_screen.dart
│   │   │       ├── special_booking_screen.dart
│   │   │       ├── trip_summary_screen.dart
│   │   │       └── ride_review_screen.dart
│   │   │
│   │   ├── ride/
│   │   │   ├── data/
│   │   │   │   └── ride_repository.dart  (if separate from booking)
│   │   │   ├── providers/
│   │   │   │   └── ride_provider.dart    (if separate from booking)
│   │   │   └── screens/
│   │   │       ├── driver_home_screen.dart
│   │   │       ├── active_ride_screen.dart
│   │   │       ├── start_ride_screen.dart
│   │   │       ├── end_ride_confirmation_screen.dart
│   │   │       ├── confirm_arrival_screen.dart
│   │   │       ├── rate_client_screen.dart
│   │   │       └── ride_payment_received_screen.dart
│   │   │
│   │   ├── payment/
│   │   │   ├── data/
│   │   │   │   └── payment_repository.dart
│   │   │   ├── providers/
│   │   │   │   └── payment_provider.dart
│   │   │   └── screens/
│   │   │       ├── payment_method_screen.dart
│   │   │       ├── payment_successful_screen.dart
│   │   │       ├── booking_invoice_screen.dart
│   │   │       ├── booking_payment_screen.dart
│   │   │       └── tip_selection_screen.dart
│   │   │
│   │   ├── wallet/
│   │   │   └── screens/
│   │   │       ├── account_screen.dart
│   │   │       ├── withdraw_method_screen.dart
│   │   │       ├── add_bank_account_screen.dart
│   │   │       └── withdraw_to_bank_screen.dart
│   │   │
│   │   ├── vehicle/
│   │   │   ├── data/
│   │   │   │   └── vehicle_repository.dart
│   │   │   └── screens/
│   │   │       ├── vehicle_registration_screen.dart
│   │   │       ├── vehicle_info_screen.dart
│   │   │       └── vehicle_management_screen.dart
│   │   │
│   │   ├── verification/
│   │   │   ├── data/
│   │   │   │   ├── document_repository.dart
│   │   │   │   └── didit_verification_service.dart
│   │   │   └── screens/
│   │   │       ├── driver_id_verification_screen.dart
│   │   │       └── id_verification_documents_screen.dart
│   │   │
│   │   ├── driver-performance/
│   │   │   └── screens/
│   │   │       ├── driver_performance_screen.dart
│   │   │       └── driver_ride_history_screen.dart
│   │   │
│   │   ├── notifications/
│   │   │   ├── data/
│   │   │   │   └── notification_repository.dart
│   │   │   └── screens/
│   │   │       └── notifications_screen.dart
│   │   │
│   │   ├── support/
│   │   │   ├── data/
│   │   │   │   └── support_repository.dart
│   │   │   └── screens/
│   │   │       └── support_screen.dart
│   │   │
│   │   ├── settings/
│   │   │   └── screens/
│   │   │       └── settings_screen.dart
│   │   │
│   │   └── legal/
│   │       └── screens/
│   │           ├── privacy_policy_screen.dart
│   │           └── terms_of_service_screen.dart
│   │
│   ├── models/                       # Keep — typed data models
│   │   ├── ride.dart
│   │   ├── user_profile.dart
│   │   ├── vehicle.dart
│   │   ├── transaction.dart
│   │   ├── payment_method.dart
│   │   ├── driver_document.dart
│   │   ├── notification.dart
│   │   ├── review.dart
│   │   ├── support_ticket.dart
│   │   └── index.dart                # Barrel export
│   │
│   ├── services/                     # Keep — external integrations
│   │   ├── cloudinary_service.dart
│   │   ├── device_biometrics_service.dart
│   │   ├── email_notification_service.dart
│   │   ├── firebase_service.dart
│   │   ├── location_search_service.dart
│   │   └── index.dart
│   │
│   └── widgets/                      # Keep — shared widgets
│       ├── buttons/
│       │   └── custom_button.dart
│       ├── cards/
│       │   ├── animated_card.dart
│       │   ├── premium_card.dart
│       │   ├── driver_offer_card.dart
│       │   ├── active_trip_card.dart
│       │   └── fare_display.dart
│       ├── inputs/
│       │   ├── animated_input_field.dart
│       │   └── location_search_field.dart
│       ├── feedback/
│       │   ├── shimmer_loading.dart
│       │   ├── status_banner.dart
│       │   └── ride_search_indicator.dart
│       ├── navigation/
│       │   ├── premium_drawer.dart
│       │   └── drawer_item.dart
│       ├── layout/
│       │   └── animated_list_item.dart
│       ├── overlays/
│       │   └── biometric_lock_screen.dart
│       └── map/
│           ├── animated_marker.dart
│           ├── map_animator.dart
│           └── map_memory.dart
│
├── test/
│   ├── unit/                         # NEW — unit tests
│   │   ├── models/
│   │   ├── providers/
│   │   ├── repositories/
│   │   └── services/
│   ├── widget/                       # NEW — widget tests
│   │   └── widgets/
│   ├── integration/                  # NEW — integration tests
│   │   └── flows/
│   └── widget_test.dart              # Move existing test here
│
├── scripts/                          # NEW — Python scripts moved here
│   ├── generate_logos.py
│   ├── remove_bg.py
│   └── analyze_logo.py
│
├── supabase/                         # Keep — Flutter-specific Supabase config
│   ├── functions/                    # (or move to backend/)
│   └── migrations/
│
└── (remove loose files: test2.dart, test_didit.dart, test_didit_v3.dart, analyze_errors.txt)
```

**Key changes:**
- `main.dart` split into `main.dart` (50 lines) + `app.dart` (router + providers)
- 17 shared screens grouped into `features/` by domain
- `widgets/` organized into subdirectories by type
- `core/` directory for theme, constants, router, utils
- Test directory structured with unit/widget/integration
- Python scripts moved to `scripts/`
- Loose test files removed

---

### 3.3 React Website — Recommended

```
website/src/
├── main.tsx                          # Entry point
├── App.tsx                           # Root component with providers
├── index.css                         # Global styles
│
├── types/                            # NEW — shared TypeScript types
│   ├── ride.ts
│   ├── user.ts
│   ├── vehicle.ts
│   ├── payment.ts
│   ├── admin.ts                      # Admin-specific types
│   └── index.ts
│
├── constants/                        # NEW — app constants
│   ├── routes.ts                     # Route path constants
│   ├── messages.ts                   # Error/success messages
│   ├── config.ts                     # App config (pagination, limits)
│   └── index.ts
│
├── hooks/                            # NEW — custom React hooks
│   ├── useAuth.ts                    # Auth logic extracted from AuthContext
│   ├── useSupabaseQuery.ts           # Generic Supabase data fetching
│   ├── useDebounce.ts
│   └── index.ts
│
├── context/                          # Keep — React contexts
│   └── AuthContext.tsx
│
├── lib/                              # Keep — Supabase client
│   └── supabase.ts
│
├── components/                       # Reorganized by type
│   ├── layout/                       # Layout components
│   │   ├── Navbar.tsx
│   │   ├── Footer.tsx
│   │   ├── PublicLayout.tsx
│   │   └── AdminLayout.tsx           # Was pages/admin/AdminLayout.tsx
│   ├── ui/                           # Reusable UI components
│   │   ├── ErrorBoundary.tsx
│   │   ├── LanguageSwitcher.tsx
│   │   └── LoadingSpinner.tsx         # NEW — extracted from ProtectedRoute
│   └── sections/                     # Landing page sections
│       ├── FAQ.tsx
│       ├── Testimonials.tsx           # Was pages/Testimonials.tsx
│       ├── HowItWorks.tsx             # Was pages/HowItWorks.tsx
│       ├── Fleets.tsx                 # Was pages/Fleets.tsx
│       ├── Services.tsx               # Was pages/Services.tsx
│       └── AboutUs.tsx                # Was pages/AboutUs.tsx
│
├── pages/                            # Route-level pages only
│   ├── LandingPage.tsx
│   ├── BookingPage.tsx               # SHOULD BE SPLIT into:
│   │                                 #   - BookingPage.tsx (container)
│   │                                 #   - BookingMap.tsx
│   │                                 #   - BookingForm.tsx
│   │                                 #   - BookingFare.tsx
│   │                                 #   - BookingPayment.tsx
│   │                                 #   - BookingConfirmation.tsx
│   ├── Contact.tsx
│   ├── AdminLogin.tsx
│   ├── legal/                        # NEW — legal pages grouped
│   │   ├── PrivacyPolicy.tsx
│   │   ├── TermsConditions.tsx
│   │   └── CookiesPage.tsx
│   └── admin/                        # Admin pages — keep flat but group logically
│       ├── Overview.tsx
│       ├── users/                    # NEW — user management grouped
│       │   ├── UsersPage.tsx
│       │   └── UserDetail.tsx
│       ├── DriversPage.tsx
│       ├── VehiclesPage.tsx
│       ├── RidesPage.tsx
│       ├── TransactionsPage.tsx
│       ├── DocumentsPage.tsx
│       ├── PricingPage.tsx
│       └── SupportPage.tsx
│
├── styles/                           # Keep — centralized CSS
│   ├── global.css                    # Was index.css
│   ├── admin.css
│   ├── admin-login.css
│   └── variables.css                 # NEW — CSS custom properties (design tokens)
│
├── i18n/                             # Keep — unchanged
│   ├── index.ts
│   ├── formatters.ts
│   └── locales/...
│
└── assets/                           # Cleaned up
    └── hero.png                      # Remove react.svg, vite.svg
```

**Key changes:**
- `BookingPage.tsx` (998 lines) split into 6 focused components
- `types/` directory for all TypeScript interfaces
- `constants/` for route paths and config values
- `hooks/` for custom React hooks
- Components organized by type (layout, ui, sections)
- Landing page sections moved from `pages/` to `components/sections/`
- Legal pages grouped under `pages/legal/`
- Admin user pages grouped under `pages/admin/users/`
- CSS organized with a `variables.css` for design tokens
- Unused assets removed

---

### 3.4 Backend — Recommended

```
backend/                              # Moved from app/supabase/
├── README.md                         # NEW — setup and deployment guide
├── deno.json
├── clear_all_data.sql
│
├── functions/                        # 9 edge functions (unchanged)
│   ├── create-booking/index.ts
│   ├── didit-lookup/index.ts
│   ├── didit-webhook/index.ts
│   ├── email-notifications/index.ts
│   ├── matchmaker/index.ts
│   ├── notifications/index.ts
│   ├── payments/index.ts
│   ├── sms-notifications/index.ts
│   └── stripe-webhook/index.ts
│
└── migrations/                       # 5 SQL migrations (unchanged)
    ├── 20260401000000_initial_schema.sql
    ├── 20260520000001_seed_admin.sql
    ├── 20260623000001_add_stripe_webhook.sql
    ├── 20260728000000_booking_system.sql
    └── 20260729000000_fix_admin_dashboard_stats.sql
```

---

## 4. Migration Guide

### 4.1 Priority 1 — Critical (Do First)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P1a | **Split `main.dart`** into `main.dart` (~50 lines) + `app.dart` (providers + router + app shell) | 1-2 hours | Entry point becomes readable; easier to test providers |
| P1b | **Split `BookingPage.tsx`** into 6 components (`BookingPage`, `BookingMap`, `BookingForm`, `BookingFare`, `BookingPayment`, `BookingConfirmation`) | 3-4 hours | 998-line file becomes manageable; each component testable |
| P1c | **Move `app/supabase/` to root `backend/`** | 30 minutes | Backend becomes a first-class citizen, not hidden inside Flutter app |
| P1d | **Consolidate documentation** — move `rules.md`, `structure.md`, `backend.md`, `color.md` into `docs/` | 30 minutes | Single source of truth for all docs |

### 4.2 Priority 2 — High (Do Next)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P2a | **Create `core/` in Flutter** — move theme, constants, router, utils | 2-3 hours | Clean separation of infrastructure from features |
| P2b | **Create `features/` in Flutter** — reorganize 50 screens into 12 feature modules | 4-6 hours | Domain-driven structure; easy to find related code |
| P2c | **Create `types/` in website** — extract shared TypeScript interfaces | 2-3 hours | Single source of truth for data shapes |
| P2d | **Create `hooks/` in website** — extract custom hooks from components | 2-3 hours | Reusable logic; cleaner components |
| P2e | **Add `exports.dart` barrel files** in Flutter | 1-2 hours | Clean imports across the app |

### 4.3 Priority 3 — Medium (Polish)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P3a | **Organize `widgets/` in Flutter** into subdirectories by type | 1-2 hours | Easy to find the right widget |
| P3b | **Organize `components/` in website** into layout/ui/sections | 1-2 hours | Clear component hierarchy |
| P3c | **Create `constants/`** in both app and website | 1-2 hours | No more magic strings/numbers |
| P3d | **Group admin pages** in website (users/, legal/) | 1 hour | Related pages together |
| P3e | **Create `scripts/`** in Flutter app for Python utilities | 15 minutes | Clean root directory |
| P3f | **Add `variables.css`** for website design tokens | 1 hour | Single source for colors/spacing |

### 4.4 Priority 4 — Low (Nice to Have)

| # | Action | Effort | Impact |
|---|--------|--------|--------|
| P4a | **Add CI/CD workflows** (GitHub Actions) | 2-3 hours | Automated testing and deployment |
| P4b | **Add monorepo tooling** (Turborepo or pnpm workspaces) | 1-2 hours | Parallel builds, shared deps |
| P4c | **Add test infrastructure** — unit/widget/integration test directories | 2-4 hours | Test coverage foundation |
| P4d | **Add README.md** to app/ and backend/ | 30 minutes | Better onboarding |
| P4e | **Remove unused assets** (react.svg, vite.svg, App.css) | 5 minutes | Cleaner codebase |
| P4f | **Remove loose files** (test2.dart, test_didit.dart, etc.) | 5 minutes | Clean root directory |

---

## 5. Summary

### Current State

| Area | Files | LOC | Issues |
|------|-------|-----|--------|
| Flutter `lib/` | 106 | 26,438 | 11 issues (2 critical, 4 high, 5 medium) |
| Website `src/` | 56 | 8,350 | 10 issues (1 critical, 3 high, 4 medium, 2 low) |
| Root level | 12 | — | 5 issues (0 critical, 1 high, 1 medium, 3 low) |
| Cross-cutting | — | — | 5 issues (0 critical, 2 high, 2 medium, 1 low) |
| **Total** | **174+** | **34,788+** | **31 issues** |

### Top 5 Most Impactful Changes

| Rank | Change | Why |
|------|--------|-----|
| 1 | **Split `main.dart`** | 638-line entry point is unmaintainable. Splitting it makes the app bootable and testable. |
| 2 | **Split `BookingPage.tsx`** | 998-line file is the single biggest code smell in the website. Splitting it into 6 focused components makes each piece testable and maintainable. |
| 3 | **Move `supabase/` to root `backend/`** | Backend code shouldn't live inside the Flutter app directory. This is a 30-minute change with huge clarity impact. |
| 4 | **Create `features/` in Flutter** | 50 screens in a flat directory is hard to navigate. Feature-based grouping (auth, booking, ride, payment, etc.) makes the codebase self-documenting. |
| 5 | **Consolidate docs** | 4 markdown files at root + 7 in docs/ = confusion. Single `docs/` directory with clear subdirectories solves this instantly. |

### Estimated Total Effort

| Priority | Effort |
|----------|--------|
| Priority 1 (Critical) | 5-7 hours |
| Priority 2 (High) | 11-17 hours |
| Priority 3 (Medium) | 5-8 hours |
| Priority 4 (Low) | 6-10 hours |
| **Total** | **27-42 hours** |

The top 5 changes alone (Priority 1 + most of Priority 2) take **16-24 hours** and address **80%** of the structural issues.

---

*Structure review generated by opencode/big-pickle on July 29, 2026*
