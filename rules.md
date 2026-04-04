# Klux VIP - Project Rules & Conventions

This document tracks the explicit design, architecture, and behavior rules established for the Klux VIP project. Adhere strictly to these guidelines to ensure UI/UX consistency across the app.

## UI Styling & Components

### 1. Inputs & Text Fields
- **DO NOT** rely on the default Material `TextField` borders or active underlines.
- **DO** always disable default outlines by explicitly passing:
  ```dart
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  ```
- **DO** force pure white backgrounds by explicitly using `filled: true` and `fillColor: AppColors.white` inside the `InputDecoration`.
- **DO** wrap input components in a standard `Container` mapping a subtle exterior outline `border: Border.all(color: const Color(0xFFE5E7EB))` (unless completely borderless layout is requested, e.g. OTP boxes).
- **DO** standardize input field heights to exactly **40px**.
- **DO** standardize the internal text size (including hints) to exactly **12px**.

### 2. Border Radiuses
- **DO** apply exactly **12px** (`BorderRadius.circular(12)`) uniformly across text inputs, dropdown selectors, OTP boxes, and minor layout containers.

### 3. Popups & Notifications
- **DO NOT** use native `ScaffoldMessenger.of(context).showSnackBar` underneath the screen.
- **DO** consistently use our custom top-bouncing toast notifications `CustomToast.showError(context, ...)` or `CustomToast.showSuccess(context, ...)` for informing the user.

### 4. Icons & AppBars
- **DO NOT** use `Icons.arrow_back` (the standard Android arrow with the horizontal line).
- **DO** use the sleek chevron icon `Icons.arrow_back_ios_new` for all navigation and app bars.

### 5. Layout Alignment
- **DO NOT** build Hamburger/Drawer navigation items with hardcoded background wrappers (e.g. `Container(color: AppColors.white)`), as this falsely indicates an active tab state.

## Behaviors & Logic

### 1. Keyboard Management & Dropdowns
- **DO NOT** trigger a dropdown BottomSheet or modal without clearing text input focus first.
- **DO** aggressively strip focus from the UI utilizing `FocusScope.of(context).unfocus();` *before* opening a modal popup or date-picker to prevent Flutter from resurrecting the keyboard when the modal closes.

### 2. OTP Forms & Code Verification
- **DO** ensure code-entry widgets (like `OTP` screens) account for clipboard pasting logic. Limit length natively without blocking rapid multi-character pasting workflows, splitting pasted values synchronously across respective controller segments.

### 3. Profile Setup & Pre-Filling
- **DO NOT** assume profile records automatically exist for new users just because they registered. Database profile entries MUST primarily generate at the finish line of the "Setup Profile" phase.
- **DO** utilize `Supabase.instance.client.auth.currentUser.userMetadata?['name']` to securely extract and smartly pre-fill the layout text controllers (like first/last name splitting) when users open the setup configuration screen.

### 4. Navigation Intercepts & Guarding
- **DO NOT** allow authenticated users without fully completed `passenger_profiles` or `driver_profiles` to access their respective Home screens. 
- **DO** utilize repository profile checks at critical login intersections (e.g. regular sign-in and OTP magic links) to force-reroute incomplete users firmly into `/passenger-profile-setup` or `/driver-profile-setup`.
