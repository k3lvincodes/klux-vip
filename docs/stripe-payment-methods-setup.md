# Stripe Payment Methods Setup Guide (Apple Pay, Google Pay & PayPal)

This document provides step-by-step instructions to configure and activate **Apple Pay**, **Google Pay**, and **PayPal** through **Stripe** for the **Kenick VIP** app.

---

## 1. Overview & Architecture

The mobile app and backend are now configured to process payments via Stripe's unified **PaymentSheet** and direct **PaymentIntents**:
- **App (`flutter_stripe`):** When a user selects Apple Pay, Google Pay, or PayPal, the app triggers Stripe's native `PaymentSheet`.
- **Backend (`payments` edge function):** Creates a Stripe `PaymentIntent` with `automatic_payment_methods: { enabled: true }`.
- **Webhook (`stripe-webhook`):** Automatically captures the payment and transitions the transaction and ride status to `completed`.

To make the biometric and wallet sheets appear on real devices, the external developer accounts and Stripe Dashboard toggles described below must be configured.

---

## 2. Google Pay Setup (Android)

Google Pay works on Android devices running Google Play Services.

### Step 2.1: Enable Google Pay in Stripe Dashboard
1. Log in to your [Stripe Dashboard](https://dashboard.stripe.com/).
2. Navigate to **Settings** > **Payment Methods** (or go to `https://dashboard.stripe.com/settings/payment_methods`).
3. Under the **Wallets** section, find **Google Pay** and ensure its status is set to **Turned On** (Default).

### Step 2.2: Configure Android Manifest & Assets
The Google Pay API is enabled via Google Play Services in `AndroidManifest.xml`. Ensure this meta-data tag is inside `<application>` in `app/android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.wallet.api.enabled"
    android:value="true" />
```

### Step 2.3: Production Approval (When ready for Play Store)
1. For development/testing, Google Pay runs in `testEnv: true` mode and accepts Google test cards.
2. Before publishing to Google Play Store:
   - Request production access at the [Google Pay & Wallet Console](https://pay.google.com/business/console).
   - Submit screenshots of your app's payment flow.
   - Once approved, change `testEnv: true` to `testEnv: false` in `payment_method_screen.dart` / `booking_payment_screen.dart`.

---

## 3. Apple Pay Setup (iOS)

Apple Pay requires an active **Apple Developer Program** membership ($99/year) and an **Apple Merchant ID**.

### Step 3.1: Create an Apple Merchant Identifier
1. Go to the [Apple Developer Portal - Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. Click the **+** button next to Identifiers.
3. Select **Merchant IDs** and click **Continue**.
4. Enter:
   - **Description:** `Kenick VIP Merchant ID`
   - **Identifier:** `merchant.com.kenick.vip.kenickVip`
5. Click **Continue** and then **Register**.

### Step 3.2: Create Payment Processing Certificate with Stripe
1. In the [Stripe Dashboard - Apple Pay Settings](https://dashboard.stripe.com/settings/apple_pay), click **+ Add new application**.
2. Download the **Certificate Signing Request (CSR)** file provided by Stripe (`stripe.certSigningRequest`).
3. Return to the [Apple Developer Portal - Identifiers](https://developer.apple.com/account/resources/identifiers/list/merchant).
4. Click on your newly created Merchant ID (`merchant.com.kenick.vip.kenickVip`).
5. Under **Apple Pay Payment Processing Certificate**, click **Create Certificate**.
6. Upload the `.certSigningRequest` file you downloaded from Stripe.
7. Click **Continue** and download the resulting certificate file (`.cer`).
8. Go back to the Stripe Dashboard prompt and upload this `.cer` certificate.

### Step 3.3: Enable Apple Pay in Xcode
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select the **Runner** target in the sidebar.
3. Go to the **Signing & Capabilities** tab.
4. Click **+ Capability** and double-click **Apple Pay**.
5. Check the box for your Merchant ID (`merchant.com.kenick.vip.kenickVip`).

### Step 3.4: Set Merchant Identifier in Stripe Configuration
In `payment_method_screen.dart` (and `booking_payment_screen.dart`), the Apple Pay parameters are passed to `PaymentSheetApplePay`:
```dart
applePay: const stripe.PaymentSheetApplePay(
  merchantCountryCode: 'US',
  merchantIdentifier: 'merchant.com.kenick.vip.kenickVip',
),
```

---

## 4. PayPal Setup (via Stripe)

Stripe supports PayPal without needing a standalone PayPal SDK. Payments are routed through Stripe so your funds, invoices, and webhooks stay unified.

### Step 4.1: Enable PayPal in Stripe Dashboard
1. Go to **Settings** > **Payment Methods** in the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods).
2. Scroll to the **Buy Now, Pay Later and Wallets** or **Bank redirects** section.
3. Find **PayPal** and click **Turn on**.

### Step 4.2: Connect your PayPal Business Account
1. When prompted by Stripe, click **Connect with PayPal**.
2. Log into your **PayPal Business** account.
3. Grant permissions for Stripe to process transactions on behalf of your PayPal account.
4. Once connected, PayPal will show as **Active** in your Stripe Dashboard.

### Step 4.3: How PayPal executes in the app
- Because `automatic_payment_methods: { enabled: true }` is enabled in our backend `payments` function, Stripe automatically includes PayPal in the `PaymentSheet` whenever the customer currency and country are eligible (e.g., USD, EUR, GBP).
- The user taps PayPal, approves in the secure in-app browser sheet, and returns directly to the Kenick VIP app with a successful payment.

---

## 5. Verification & Testing Checklist

| Step | Method | Verification Procedure | Expected Result |
|:---:|:---:|:---|:---|
| 1 | **Cards** | Enter test card `4242 4242 4242 4242` with any expiry & CVC. | Authorizes payment and redirects to `/payment-successful`. |
| 2 | **Google Pay** | Run on Android device with a Google Account that has a saved payment card. Tap **Google pay**. | Native Google Pay bottom sheet appears showing card selection and biometric prompt. |
| 3 | **Apple Pay** | Run on a physical iPhone signed into an Apple ID with Wallet enabled. Tap **Apple pay**. | Native Apple Pay sheet slides up with Face ID / Touch ID prompt. |
| 4 | **PayPal** | Select **Paypal** and tap **Proceed to pay**. | Stripe PaymentSheet loads showing the PayPal option, which opens the PayPal login modal. |
