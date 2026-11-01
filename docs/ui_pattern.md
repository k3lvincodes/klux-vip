# Kenick VIP — UI & UX Design Patterns Specification

This document provides a comprehensive analysis and formal specification of the **Client Homepage** (`PassengerHomeScreen`) and **Hamburger Menu** (`KenickNavigationDrawer`). Use this reference to replicate and maintain consistent luxury design language, motion physics, typography, and component structures across the entire Kenick VIP application suite.

---

## 1. Design Philosophy & Aesthetic Identity

Kenick VIP employs an **editorial luxury aesthetic** characterized by:
1. **Bold Minimalism & High Contrast**: Dark surfaces (`#000000`, `#141416`, `#1E1E1E`) paired with signature vibrant gold (`#EAB308`) and stark white typography.
2. **Editorial Typography**: Generous whitespace, refined Poppins font weights, tight letter spacing, and deliberate line-height hierarchy.
3. **Layered Motion & Spatial Physics**: Smooth physics-driven drag transitions, slide-up discovery drawers, and floating pill controls over full-bleed hero media.
4. **Subtle Depth & Tactility**: Multi-stop linear gradients, soft ambient shadows, and pill-shaped containers rather than harsh boxy borders.

---

## 2. Design Tokens & Foundations

### 2.1 Color Palette

| Token Name | Hex Code | Visual Role |
| :--- | :--- | :--- |
| `primary` | `#EAB308` | Signature Kenick Gold; used for CTA buttons, active tabs, underline accents, and focus rings. |
| `softYellow` | `#FEF08A` | Light yellow accent for subtle highlights, badges, and tab indicator washes. |
| `darkBackground` | `#000000` / `#08060D` | Base scaffold background for dark mode screens. |
| `darkDrawerBg` | `#141416` | Premium deep charcoal used for the full-screen navigation drawer background. |
| `darkSurface` | `#1E1E1E` | Card backgrounds, floating navigation pill, and modal sheets. |
| `darkCardStage` | `#121316` / `#1E2026` | Outer and inner container layers for multi-level feature cards. |
| `lightBackground` | `#F6F6F8` / `#EBE5E4` | Base light mode background. |
| `lightDrawerBg` | `#F9F8F6` | Cream-white light background for drawer and modals. |
| `lightCardStage` | `#D6DBE1` / `#ECEEF1` | Surface highlights and card backdrops in light mode. |
| `dividerDark` | `#27272A` | Subtle dividers and hairline borders in dark mode. |
| `dividerLight` | `#E4E4E7` | Subtle dividers and hairline borders in light mode. |
| `textWhite` | `#FFFFFF` | Primary text on dark backgrounds and media. |
| `textDark` | `#111827` / `#18181B` | Primary text in light mode and button label text on gold CTAs. |
| `textMutedDark` | `#A1A1AA` | Secondary/subtitle text on dark surfaces (versioning, hints). |
| `textMutedLight` | `#71717A` | Secondary/subtitle text on light surfaces. |

### 2.2 Typography Scale (`GoogleFonts.poppins`)

| Hierarchy Role | Font Size | Weight | Line Height | Letter Spacing | Shadows / Effects |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero Editorial Title** | `32.0` | `FontWeight.w600` | `1.18` | `-0.3` | `Shadow(color: Colors.black87, blurRadius: 14, offset: Offset(0, 2))` |
| **Drawer Nav Top Links** | `22.0` | `FontWeight.w500` | `1.2` | `-0.3` | None |
| **Card / Feature Heading** | `21.0` | `FontWeight.w500` | `1.2` | `-0.3` | None |
| **Screen Greeting Header** | `20.0` | `FontWeight.w400` | `1.2` | `-0.2` | Optional drop shadow on hero photo |
| **Input / Destination Line** | `16.0` | `FontWeight.w400` | `1.3` | `0.1` | `Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1))` |
| **Drawer Sub-Items** | `15.0` | `FontWeight.w400` | `1.2` | Normal | None |
| **Drawer Log out** | `15.5` | `FontWeight.w500` | `1.2` | Normal | None |
| **Section Titles** | `14.5` | `FontWeight.w500` | `1.2` | `0.1` | None |
| **CTA Button Label** | `14.0` | `FontWeight.w600` | `1.15` | Normal | None |
| **Grid Card Title** | `14.0` | `FontWeight.w600` | `1.25` | Normal | Placed over dark gradient |
| **Body / Caption Copy** | `12.5` | `FontWeight.w400` | `1.45` | Normal | `color: Colors.white.withValues(alpha: 0.8)` |
| **Drawer App Version** | `12.5` | `FontWeight.w400` | `1.2` | Normal | Muted text color |
| **Tab Label** | `10.5` | `FontWeight.w600` (active) / `w500` (inactive) | `1.2` | Normal | Placed under tab icon |

### 2.3 Radii & Elevation Standards

- **Capsule / Pill Buttons & Floating Bars**: `BorderRadius.circular(36)` or `BorderRadius.circular(30)`
- **Large Feature Cards**: `BorderRadius.circular(24)` (outer container) and `BorderRadius.circular(20)` (nested inner card)
- **Grid Tiles & Car Selector Cards**: `BorderRadius.circular(18)` or `BorderRadius.circular(16)`
- **Segmented Control Tabs**: `BorderRadius.circular(10)` to `12`
- **Bottom Modal Sheets**: `BorderRadius.vertical(top: Radius.circular(30))`
- **Shadows**:
  - Floating pill: `color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16), blurRadius: 18, offset: Offset(0, 4)`
  - Active ride card / FAB: `blurRadius: 12, offset: Offset(0, 3)`
  - Legibility text shadow: `Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1))`

---

## 3. Client Homepage UI Architecture (`PassengerHomeScreen`)

The Client Homepage is structured as an interactive 3-tier view state:

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 1: Full-Screen Luxury Cover Mode (Hero Page)           │
│  - Ambient Gradients (Top 220px, Bottom 480px)              │
│  - Top Greeting & Menu Trigger                              │
│  - Ongoing Ride Floating Banner (Conditional)               │
│  - Editorial Headline: "The Ride You Deserve"               │
│  - Minimalist Underlined Destination Trigger                │
│  - "Explore rides & services" downward affordance           │
└─────────────────────────────────────────────────────────────┘
                             │
            ▲ Swipe Up Gesture (AnimationController)
            ▼ Pull Down Gesture / Overscroll Top
                             │
┌─────────────────────────────────────────────────────────────┐
│ Tier 2: Slide-up Discovery View                             │
│  - Drag Header & Sync Greeting Bar                          │
│  - Section: "Recommended for you"                           │
│  - Multi-tier Stage Card ("Pick up where you left off")     │
│  - Section: "Ride types"                                    │
│  - 2x2 Image-Backed Grid with bottom-left titles            │
└─────────────────────────────────────────────────────────────┘
                             │
            Tap Destination / Start Booking
                             │
┌─────────────────────────────────────────────────────────────┐
│ Tier 3: Route & Dispatch Live Sheet View                    │
│  - Live Interactive VIP Map with Polyline & Custom Markers  │
│  - Floating Back-to-Cover Button (top-left)                │
│  - DraggableScrollableSheet with snap points (12% and 48%)  │
│  - Segmented Mode Tabs (Instant / Schedule / Special)       │
│  - Vehicle Selector Card with Live Fare Pill                │
│  - Full-width Gold Dispatch Button                          │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 Tier 1: Full-Screen Luxury Cover Mode

#### A. Ambient Gradient System
To allow dynamic editorial photography (`passenger_hero.jpg`) while ensuring WCAG-compliant legibility of white text:
1. **Top Header Gradient**:
   - `height: 220`
   - Colors: `[Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.45), Colors.transparent]`
2. **Bottom Editorial Gradient**:
   - `height: 480`
   - Stops: `[0.0, 0.35, 0.7, 1.0]`
   - Colors: `[Colors.transparent, Colors.black.withValues(alpha: 0.5), Colors.black.withValues(alpha: 0.82), Colors.black.withValues(alpha: 0.96)]`

#### B. Top Header Bar
- Wrapped in `SafeArea` with padding: `horizontal: 22.0, vertical: 8.0`.
- Left: Greeting `"Welcome, [FirstName]"` (extracted dynamically from Supabase / Profile).
- Right: Large tap target `42x42` icon button with `Icons.menu_rounded` (size `30` or `28`), with subtle black drop shadow.

#### C. Active Trip Floating Banner
Displays if an ongoing ride exists (`status != 'completed'` and `status != 'cancelled'`).
- `Positioned(top: 104, left: 20, right: 20)`
- Background: `Colors.black.withValues(alpha: 0.8)` with `border: Border.all(color: AppColors.primary, width: 1.5)`.
- Icon pill: Circular primary gold container (`alpha: 0.2`) with radar or car icon.
- Copy: Title in Poppins 14px bold, Subtitle in Poppins 12px 75% white.
- Trailing chevron: `Icons.arrow_forward_ios_rounded` (14px, gold).

#### D. Destination Line Pattern
Instead of a boxed text field, Kenick uses a minimalist editorial line:
- Indicator: 8x8 circular gold dot (`AppColors.primary`).
- Label: `"Enter your destination"` in Poppins 16px, w400, white with 95% opacity.
- Accent Underline: Height 1.5 container with a gradient from `AppColors.primary` to `AppColors.primary.withValues(alpha: 0.35)`.

#### E. Exploration Affordance Trigger
- Placed directly below the destination line (36px gap).
- Gold downward arrow (`Icons.arrow_downward_rounded`, size 16) + `"Explore rides & services"` (Poppins 14px, w500).
- Tapping triggers `_pageTransitionController.forward()`.

---

### 3.2 Tier 2: Slide-up Discovery View

#### A. Motion & Gestures
- Controlled by an `AnimationController` with duration `400ms`.
- Curve: `Curves.easeOutCubic`, reverse curve: `Curves.easeInCubic`.
- Slide transition: `Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)`.
- **Drag-to-Dismiss**: A vertical drag handler on the top header tracks delta. If drag velocity exceeds `250` or progress drops below `0.75`, the sheet smoothly snaps back down.
- **Overscroll Return**: In the scroll view, a `NotificationListener<ScrollNotification>` watches for upward pulls at offset `0` (overscroll `< -15px` or `< -8px`). When triggered, it automatically dismisses back to Cover Mode.

#### B. Multi-Tier Feature Card Pattern ("Pick up where you left off")
A signature Kenick card structure featuring an upper visual stage and an inset contrast container:
1. **Outer Card**:
   - `BorderRadius.circular(24)`
   - Color: `Color(0xFF1E2026)` (dark) / `Color(0xFFD6DBE1)` (light)
   - Border: 1px subtle outline variant (`alpha: 0.4` to `0.9`)
   - Upper spacing: 195px height dedicated to vehicle artwork or hero imagery.
2. **Inner Inset Overlay**:
   - Padding around inner container: `fromLTRB(8, 0, 8, 8)`
   - Background: `Color(0xFF121316)` (dark) / `Color(0xFF16181D)` (light)
   - `BorderRadius.circular(20)`
   - Padding: 20px all sides
   - Content:
     - Title: Poppins 21px, w500, white, letterSpacing -0.3.
     - Body: Poppins 12.5px, w400, white 80% opacity, line height 1.45.
     - CTA Button: Height 42, radius 21, gold background (`#EAB308`), text 14px w600 `#111827`.

#### C. 2x2 Image-Backed Grid ("Ride types")
- `GridView.builder` with `crossAxisCount: 2`, `crossAxisSpacing: 12`, `mainAxisSpacing: 12`, `childAspectRatio: 0.95`.
- Each card:
  - `ClipRRect(borderRadius: BorderRadius.circular(18))`
  - Background image: `CachedNetworkImage` with `fit: BoxFit.cover`.
  - Contrast Gradient: `LinearGradient(stops: [0.35, 1.0], colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)])`.
  - Title: Positioned `bottom: 14, left: 14, right: 14` with Poppins 14px, w600, white, height 1.25.

---

### 3.3 Tier 3: Floating Bottom Navigation Pill & Dynamic Quick-Book FAB

#### A. The Navigation Pill
- Positioned: `Align(alignment: Alignment.bottomCenter)` within `SafeArea(bottom)`.
- Margins: `fromLTRB(20, 0, 20, 6)`.
- Container decoration:
  - Background: `AppColors.darkSurface.withValues(alpha: 0.96)` (dark) / `Colors.white.withValues(alpha: 0.96)` (light).
  - Border radius: `BorderRadius.circular(36)`.
  - Border: 1px subtle stroke.
  - Shadow: Deep blur shadow (`blurRadius: 18, offset: Offset(0, 4)`).
- Tabs (Home, Rides, Help):
  - **Active State**: Inset pill with soft yellow tint (`AppColors.primary.withValues(alpha: 0.08)`), radius 30, primary gold icon and label.
  - **Inactive State**: `Colors.white70` (dark) or `Colors.grey.shade700` (light).

#### B. Dynamic Quick-Book Car FAB
- An auxiliary circular gold action button (`48x48`, `BoxShape.circle`, `AppColors.primary`).
- Icon: `Icons.directions_car_rounded` (26px, dark `#111827`).
- **Reactive Visibility**: Driven by `AnimatedBuilder` on `_pageTransitionController`.
  - On Cover Mode (`t == 0`): Completely hidden (`SizedBox.shrink()`).
  - When swiped up into Discovery View: Smoothly scales up (`0.5 + 0.5 * t`) and fades in alongside the navigation pill.

---

## 4. Hamburger Navigation Menu Specification (`KenickNavigationDrawer`)

Rather than a standard 70%-width native drawer, Kenick VIP utilizes a **full-bleed, branded modal screen** pushed via a custom `PageRouteBuilder` with seamless lateral slide animation.

### 4.1 Drawer Theme & Color Mapping

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
final bgColor = isDark ? const Color(0xFF141416) : const Color(0xFFF9F8F6);
final textPrimary = isDark ? Colors.white : const Color(0xFF18181B);
final textMuted = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
final dividerColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
```

### 4.2 Structural Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Header: "Welcome, Kelvin"                  [ Close (X) ]    │
├─────────────────────────────────────────────────────────────┤
│ (24px spacing)                                              │
│ Primary Item: Newsfeed (22px w500)                          │
│ (20px spacing)                                              │
│ Primary Item: Offers (22px w500)                            │
│ (20px spacing)                                              │
│ Accordion Header: Account (22px w500)     [ Chevron Up/Down]│
│ ─────────────────────────────────────────────────────────── │
│   Personal information               [ Person Circle Icon ] │
│ ─────────────────────────────────────────────────────────── │
│   Frequent addresses                 [ Location Pin Icon ]  │
│ ─────────────────────────────────────────────────────────── │
│   Payment and billing                [ Credit Card Icon ]   │
│ ─────────────────────────────────────────────────────────── │
│   Notifications                      [ Bell Icon ]          │
│ ─────────────────────────────────────────────────────────── │
│   Legal information                  [ Bank / Legal Icon ]  │
│ ─────────────────────────────────────────────────────────── │
│ (Expanded scroll space)                                     │
├─────────────────────────────────────────────────────────────┤
│ Footer:                                                     │
│   Kenick VIP 1.0.0 (12.5px muted)                           │
│ ─────────────────────────────────────────────────────────── │
│   [ Logout Icon ] Log out (15.5px w500)                     │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 Key Drawer Patterns

#### A. Top Level Links vs Sub-Items
- **Primary Top-Level Links** ("Newsfeed", "Offers", "Account"):
  - Poppins 22px, `FontWeight.w500`, `letterSpacing: -0.3`.
  - Generous vertical rhythm (20px spacing between items).
- **Sub-Items** (Inside "Account" accordion):
  - Row layout with text on the left (Poppins 15px, `FontWeight.w400`) and outline/Cupertino icon on the right (size 22).
  - Separated by thin hairline dividers (`height: 1, thickness: 0.8, color: dividerColor`).
  - Vertical padding per row: 14.0px.

#### B. Footer Pattern
- App version label: `"Kenick VIP 1.0.0"` in Poppins 12.5px, muted color.
- Divider separator.
- Logout row: `Icons.logout_rounded` (20px) + `"Log out"` text (Poppins 15.5px, w500).
- Handled with clean auth invalidation (`context.read<AuthProvider>().signOut()`) and redirection to `/sign-in`.

#### C. Lateral PageRouteBuilder Motion
When opening or dismissing the drawer, smooth lateral easing is applied:

```dart
Navigator.of(context).push(
  PageRouteBuilder(
    opaque: false,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return KenickNavigationDrawer(
        userName: displayName,
        avatarUrl: profileImageUrl,
        isDark: Theme.of(context).brightness == Brightness.dark,
      );
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  ),
);
```

When navigating from drawer items to destination screens, use `pushReplacement` with a coordinated push-and-recede slide transition:

```dart
void _navigateTo(Widget screen) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0), // Subtle parallax exit
            ).animate(secondaryCurved),
            child: child,
          ),
        );
      },
    ),
  );
}
```

---

## 5. Reusable Component Recipes & Blueprints

Copy and adapt these exact blueprints when replicating Kenick VIP interfaces in other screens.

### 5.1 Editorial Section Header
```dart
Widget buildSectionHeader(String title, ColorScheme cs) {
  return Text(
    title,
    style: GoogleFonts.poppins(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: cs.onSurfaceVariant,
      letterSpacing: 0.1,
    ),
  );
}
```

### 5.2 Signature Gold CTA Button (Pill)
```dart
Widget buildGoldPillButton({
  required String label,
  required VoidCallback onPressed,
  double height = 42,
  IconData? icon,
}) {
  return SizedBox(
    width: double.infinity,
    height: height,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF111827)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

### 5.3 Two-Tier Stage Feature Card Blueprint
```dart
Widget buildStageFeatureCard({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonLabel,
  required VoidCallback onButtonPressed,
  required bool isDark,
  Widget? topGraphic,
}) {
  final cs = Theme.of(context).colorScheme;

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E2026) : const Color(0xFFD6DBE1),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.9)
            : cs.outlineVariant.withValues(alpha: 0.4),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upper Visual Stage
        SizedBox(
          height: 195,
          child: Center(child: topGraphic ?? const SizedBox.shrink()),
        ),

        // Bottom Inset Dark Card
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121316) : const Color(0xFF16181D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                buildGoldPillButton(
                  label: buttonLabel,
                  onPressed: onButtonPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

### 5.4 Image-Backed Gradient Tile
```dart
Widget buildImageTile({
  required String title,
  required String imageUrl,
  required IconData fallbackIcon,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? const Color(0xFF1E2026) : const Color(0xFFD6DBE1),
              child: Center(
                child: Icon(fallbackIcon, color: Colors.white38, size: 32),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF1E2026) : const Color(0xFFD6DBE1),
              child: Center(
                child: Icon(fallbackIcon, color: Colors.white38, size: 32),
              ),
            ),
          ),

          // Contrast Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.35, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),

          // Bottom Title
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 5.5 Minimalist Underlined Action Trigger
```dart
Widget buildUnderlineActionTrigger({
  required String label,
  required VoidCallback onTap,
  Color dotColor = AppColors.primary,
}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                dotColor,
                dotColor.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    ),
  );
}
```

---

## 6. Implementation Checklist for New Screens

When building a new client screen or replicating this UX pattern elsewhere:

- [ ] **Typography**: Are all headings and body copy using `GoogleFonts.poppins` with the exact weight scale specified in Section 2.2?
- [ ] **Contrast & Gradients**: If placing typography over photos or maps, are ambient multi-stop linear gradients applied?
- [ ] **Buttons & Accents**: Are primary actions styled with `#EAB308` gold pill backgrounds (`radius: height / 2`) and `#111827` dark text?
- [ ] **Card Hierarchy**: Are primary cards utilizing the nested contrast stage pattern (outer stage + inset `#121316` card)?
- [ ] **Navigation Drawer**: If presenting top-level app navigation, are you using `KenickNavigationDrawer` via `PageRouteBuilder` with `Curves.easeOutCubic` slide transition?
- [ ] **Touch Targets**: Do all hamburger menus, close buttons, and accordion toggles have a minimum tap target of `40x40` to `44x44` pt with `HitTestBehavior.opaque`?
- [ ] **Dark & Light Adaptability**: Does the UI adapt gracefully between `#000000` / `#141416` in dark mode and `#F6F6F8` / `#F9F8F6` in light mode?
- [ ] **Physics & Overscroll**: Do drag-based sheets incorporate velocity thresholds and top overscroll listeners for natural gesture dismissals?
