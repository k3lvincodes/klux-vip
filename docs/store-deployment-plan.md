# Kenick VIP - Mobile App Store & Play Store Deployment Plan
*(Windows Development & No-Mac Setup)*

This comprehensive guide outlines the end-to-end plan to publish the **Kenick VIP** Flutter application to both the **Google Play Store** and the **Apple App Store**, specifically tailored for developers working on **Windows without a physical Mac machine**.

---

## Table of Contents
1. [Prerequisites & App Identity](#1-prerequisites--app-identity)
2. [Google Play Store Deployment (From Windows)](#2-google-play-store-deployment-from-windows)
3. [Apple App Store Deployment (Without a Mac)](#3-apple-app-store-deployment-without-a-mac)
4. [Store Approval Checklist (Avoiding Rejections)](#4-store-approval-checklist-avoiding-rejections)
5. [Required Store Assets & Metadata](#5-required-store-assets--metadata)
6. [Phase-by-Phase Execution Checklist](#6-phase-by-phase-execution-checklist)

---

## 1. Prerequisites & App Identity

### 1.1 Developer Accounts (Already Active)
- **Google Play Developer Account:** $25 one-time registration fee (Active).
- **Apple Developer Program:** $99/year subscription (Active).

### 1.2 Bundle & Package Identifiers
Ensure your identifiers match your developer portal registrations:
- **Android Package Name:** `com.kenick.vip.kenick_vip` (defined in `android/app/build.gradle.kts`)
- **iOS Bundle Identifier:** `com.kenick.vip.kenickVip` (defined in `ios/Runner.xcodeproj/project.pbxproj`)
- **App Display Name:** `Kenick` (Android) / `Kenick Vip` (iOS)
- **Version Number:** `1.0.0+1` (defined in `pubspec.yaml`, where `1.0.0` is the version name and `1` is the build number). Increment the build number (`+2`, `+3`, etc.) with every submission.

### 1.3 Live URLs from Your Web Project
Both stores require live URLs before publishing:
- **Privacy Policy URL:** `https://your-domain.com/privacy` (already built in `website/src/pages/legal/PrivacyPolicy.tsx`)
- **Terms & Conditions URL:** `https://your-domain.com/terms` (already built in `website/src/pages/legal/TermsConditions.tsx`)
- **Support / Contact Email:** e.g., `support@kenickvip.com`

---

## 2. Google Play Store Deployment (From Windows)

Building and releasing Android apps from Windows is fully native with Flutter.

### Step 2.1: Generate a Release Keystore
In your terminal, navigate to your JDK or run standard `keytool`:

```powershell
cd "c:\Users\SKYNET\Desktop\K3 Boys\SkyDream\K3 Dev Projects\kenick\app\android"
keytool -genkey -v -keystore release-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias kenick -storepass YourStrongPassword123 -keypass YourStrongPassword123
```
*(Enter your name, organization, and country code when prompted).*

> [!CAUTION]
> **Keep `release-keystore.jks` and your passwords backed up in a secure vault.** If lost, you will never be able to update this app on Google Play without contacting Google Support.

### Step 2.2: Configure `key.properties`
Create a file named `key.properties` inside `app/android/`:
```properties
storePassword=YourStrongPassword123
keyPassword=YourStrongPassword123
keyAlias=kenick
storeFile=../release-keystore.jks
```
*(Note: `android/key.properties` and `*.jks` are already included in `.gitignore` so they won't be pushed to Git).*

### Step 2.3: Configure `app/android/app/build.gradle.kts`
Update the release signing config to read from `key.properties`:
```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
```

### Step 2.4: Build the Android App Bundle (`.aab`)
Google Play strictly requires `.aab` format (not `.apk`) for new apps:
```powershell
cd "c:\Users\SKYNET\Desktop\K3 Boys\SkyDream\K3 Dev Projects\kenick\app"
flutter build appbundle --release
```
Your compiled bundle will be generated at:
`app/build/app/outputs/bundle/release/app-release.aab`

### Step 2.5: Google Play Console Setup & Submission
1. Log in to [Google Play Console](https://play.google.com/console).
2. Click **Create app**:
   - Name: `Kenick`
   - Default language: `English (US)` or `English (UK)`
   - App or game: `App`
   - Free or paid: `Free`
3. Complete the **Policy & Content** forms:
   - **Privacy Policy:** Paste your website privacy link.
   - **App Access:** Select "All or some functionality is restricted" -> Add test credentials (a pre-registered rider account and a test driver account with credentials and bypass OTP).
   - **Ads:** Select "No, my app does not contain ads".
   - **Content rating:** Complete the questionnaire (Utilities / Ride hailing / Chauffeur service).
   - **Target audience:** Ages 18 and over.
   - **Data Safety form:** Declare data collected (Approximate/Precise location for ride tracking, Name/Email/Phone for profile, Payment info processed via Stripe).
4. **Closed Testing Track (20 Testers Rule)**:
   - For personal accounts created after Nov 2023, Google requires at least 20 testers opted in for 14 continuous days before applying for Production access.
   - Upload `app-release.aab` to **Closed testing (Alpha)**.
   - Share the opt-in link with 20 friends, colleagues, or beta testing services.
5. After 14 days of closed testing, apply for **Production Track** release.

---

## 3. Apple App Store Deployment (Without a Mac)

Since you are running on Windows and do not have a physical Mac, you cannot run Xcode locally. However, you can achieve a **100% automated build, signing, and upload to TestFlight and the App Store** using a cloud CI/CD platform with macOS runners.

### Recommended Tool: **Codemagic** (or GitHub Actions)
**Codemagic** is purpose-built for Flutter and offers:
- Free monthly build minutes on M1/M2 macOS runners.
- Direct integration with Apple Developer Portal to automatically generate certificates and provisioning profiles.
- Automatic upload directly to **Apple TestFlight** and **App Store Connect**.

---

### Step 3.1: Apple Developer Portal Setup (In Browser)
You do all of this in your web browser:
1. Log in to [developer.apple.com](https://developer.apple.com/account/).
2. Navigate to **Certificates, Identifiers & Profiles**:
   - Go to **Identifiers** -> Click `+` -> Select **App IDs**.
   - Description: `Kenick VIP`
   - Bundle ID: Explicit -> `com.kenick.vip.kenickVip`
   - Capabilities: Check **Push Notifications** and any required entitlements.
3. Generate an **App Store Connect API Key** (this allows the cloud builder to sign and upload for you):
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com/) -> **Users and Access** -> **Integrations** -> **App Store Connect API**.
   - Click `+` to generate a new API Key:
     - Name: `Codemagic CI` (or `GitHub Actions CI`)
     - Access: `Admin` or `App Manager`
   - Download the `.p8` private key file immediately (it can only be downloaded once!).
   - Note down:
     - **Issuer ID** (UUID at the top)
     - **Key ID** (10-character code)
     - The downloaded `.p8` file contents.

### Step 3.2: Create the App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com/) -> **Apps** -> Click `+` -> **New App**.
2. Fill in:
   - Platform: **iOS**
   - Name: **Kenick** (or **Kenick VIP**)
   - Primary Language: **English**
   - Bundle ID: Select `com.kenick.vip.kenickVip`
   - SKU: `KENICK-VIP-001`
   - User Access: **Full Access**

### Step 3.3: Configure Cloud Build (Codemagic or GitHub Actions)

#### Option A: Using Codemagic (Easiest - 10-minute setup)
1. Sign up at [Codemagic.io](https://codemagic.io/) using your GitHub/Git repository.
2. Select your repository and select the `app` project directory.
3. In Codemagic **App settings**:
   - Under **Distribution** -> **iOS code signing**:
     - Select **Automatic code signing**.
     - Connect your **App Store Connect API Key** (upload the `.p8` file, enter Key ID and Issuer ID).
     - Select Bundle Identifier: `com.kenick.vip.kenickVip`.
   - Under **Distribution** -> **App Store Connect**:
     - Check **Publishing to App Store Connect**.
     - Check **Submit to TestFlight**.
4. Click **Start new build** -> Select `iOS` -> Workflow: `Release`.
5. Codemagic will:
   - Spin up an Apple Silicon Mac runner.
   - Run `flutter pub get`.
   - Fetch/create the Apple Distribution Certificate and Provisioning Profile.
   - Build `flutter build ipa --release`.
   - Upload the `.ipa` directly to App Store Connect / TestFlight!

#### Option B: Using GitHub Actions (`.github/workflows/ios-release.yml`)
If you prefer running inside your own GitHub repository, a GitHub Actions workflow with `macos-latest` runner can automatically sign with fastlane / Apple API key and upload to TestFlight.

### Step 3.4: Test on Your iPhone via TestFlight
Once the cloud build finishes uploading:
1. Open [App Store Connect](https://appstoreconnect.apple.com/) -> **Apps** -> **Kenick** -> **TestFlight**.
2. Add yourself under **Internal Testing**.
3. Install the **TestFlight** app from the App Store on your physical iPhone.
4. Open the email invitation and install the live build on your iPhone to verify maps, Stripe, and GPS tracking.

---

## 4. Store Approval Checklist (Avoiding Rejections)

Both Apple and Google have strict review guidelines. Address these 5 points to pass on the first attempt:

### 4.1 In-App Account Deletion (CRITICAL)
- **Apple Guideline 5.1.1(v)** and **Google Play User Data Policy**: Any app that allows users to create an account must allow users to delete their account and associated personal data directly within the app.
- **Action**: Add an explicit "Delete Account" button in the Profile / Settings page with a confirmation dialog that invokes your account deletion backend endpoint.

### 4.2 Reviewer Demo Credentials (Mandatory)
- Store review teams cannot receive SMS OTP codes or verify real driving licenses.
- **Action**: In `App Store Connect` (App Review Information) and `Google Play Console` (App Access), provide:
  - Demo Rider Email/Password (or phone number with a fixed review OTP like `123456`).
  - Demo Driver/Chauffeur Account with simulated active status.

### 4.3 Realistic Permission Descriptions in `Info.plist`
Apple will reject the app if descriptions are vague:
```xml
<!-- Good examples in ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kenick uses your location to display nearby luxury vehicles, set accurate pickup points, and track your chauffeur in real time.</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Kenick uses continuous location tracking to navigate your route and calculate trip distances even when the screen is locked.</string>

<key>NSCameraUsageDescription</key>
<string>Kenick requires camera access to take profile photos and complete identity verification for passengers and drivers.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Kenick requires photo library access to upload required vehicle and identity documents.</string>

<key>NSFaceIDUsageDescription</key>
<string>Kenick uses Face ID to enable fast, secure biometric sign-in to your account.</string>
```

### 4.4 Payment System Compliance (Stripe Exemption)
- **Apple Guideline 3.1.5**: Digital goods (subscriptions, coins, digital content) must use Apple In-App Purchase (30% fee).
- **Physical Goods & Services Exemption**: On-demand transportation, ride hailing, and physical chauffeur services are explicitly **exempt** from Apple IAP. Using Stripe for payment processing is 100% compliant with both Apple and Google rules.

---

## 5. Required Store Assets & Metadata

Prepare these creative assets prior to opening the review submission:

### 5.1 Google Play Store Assets
| Asset | Dimensions | Format |
| :--- | :--- | :--- |
| App Icon | 512 × 512 px | 32-bit PNG (no alpha/transparency on background) |
| Feature Graphic | 1024 × 500 px | PNG or JPEG |
| Phone Screenshots | Min 2, max 8 screens | 16:9 or 9:16 aspect ratio (e.g. 1080 × 1920 or 1080 × 2400) |
| Short Description | Up to 80 characters | "Luxury chauffeur and VIP executive ride hailing service." |
| Full Description | Up to 4000 characters | Highlight luxury fleet, verified chauffeurs, transparent pricing, security. |

### 5.2 Apple App Store Assets
| Asset | Dimensions | Format |
| :--- | :--- | :--- |
| App Icon | 1024 × 1024 px | PNG (no transparency, no rounded corners — Apple adds radius automatically) |
| 6.7" iPhone Screenshots | 1290 × 2796 px (or 1179 × 2556 px) | PNG or JPEG (Required: iPhone 15 Pro Max / 16 Pro Max sizes) |
| 6.5" iPhone Screenshots | 1242 × 2688 px | PNG or JPEG (Required if supporting older screen ratios) |
| Promotional Text | Up to 170 characters | Quick hook visible before user expands description. |
| Keywords | Up to 100 characters, comma-separated | `luxury ride,chauffeur,vip transport,executive car,limo,ride hailing` |
| Support URL & Privacy URL | Valid Web Links | `https://your-domain.com` and `https://your-domain.com/privacy` |

---

## 6. Phase-by-Phase Execution Checklist

### Phase 1: Code & Security Adjustments (Local Windows)
- [ ] Ensure account deletion flow exists in Passenger & Chauffeur profile screens.
- [ ] Configure `key.properties` and update `app/android/app/build.gradle.kts`.
- [ ] Verify `Info.plist` usage descriptions are descriptive and clear.
- [ ] Verify `.env` has production credentials (Supabase, Stripe live keys).

### Phase 2: Google Play Store
- [ ] Generate `release-keystore.jks` using `keytool`.
- [ ] Run `flutter build appbundle --release`.
- [ ] Complete Google Play Console listing (Data Safety, Content Rating, Privacy Policy).
- [ ] Upload bundle to **Closed Testing** and gather 20 testers for 14 days.
- [ ] Promote to **Production** track.

### Phase 3: Apple App Store (Cloud CI/CD - No Mac)
- [ ] Create App ID `com.kenick.vip.kenickVip` in Apple Developer Portal.
- [ ] Generate App Store Connect API Key (`.p8`, Issuer ID, Key ID).
- [ ] Create the new App record in App Store Connect.
- [ ] Set up Codemagic (or GitHub Actions) with automatic code signing.
- [ ] Trigger the cloud release build and verify delivery in **TestFlight**.
- [ ] Test the build on a physical iPhone via TestFlight.
- [ ] Submit the build for **App Store Review** with demo reviewer credentials.
