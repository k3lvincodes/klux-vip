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

## 3. Apple App Store Deployment (Via Codemagic Workflow Editor - No Mac)

Since you are running on Windows and do not have a physical Mac machine, you cannot run Xcode locally. You achieve a **100% automated build, signing, and upload to TestFlight and the App Store** using **Codemagic** (Workflow Editor UI).

---

### Step 3.1: Apple Developer Portal & App Store Connect Setup (In Browser)
All developer configurations are done via web browser:
1. **Create App ID on [developer.apple.com](https://developer.apple.com/account/)**:
   - Go to **Certificates, Identifiers & Profiles** -> **Identifiers** -> Click `+` -> **App IDs**.
   - Description: `Kenick VIP`
   - Bundle ID: Explicit -> `com.kenick.vip.kenickVip`
   - Capabilities: Check **Push Notifications** (and any other required capabilities).
2. **Generate App Store Connect API Key** (allows Codemagic to automatically create distribution certificates, provisioning profiles, and upload builds):
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com/) -> **Users and Access** -> **Integrations** -> **App Store Connect API**.
   - Click `+` to generate a new API Key:
     - Name: `Codemagic CI`
     - Access: `Admin` or `App Manager`
   - **Download the `.p8` private key file immediately** (Apple only allows downloading it once!).
   - Copy and note down:
     - **Issuer ID** (UUID at top of the page)
     - **Key ID** (10-character alphanumeric code)
3. **Create the App Record in App Store Connect**:
   - Go to **Apps** -> Click `+` -> **New App**.
   - Platform: **iOS**
   - Name: **Kenick** (or **Kenick VIP**)
   - Primary Language: **English**
   - Bundle ID: Select `com.kenick.vip.kenickVip`
   - SKU: `KENICK-VIP-001`
   - User Access: **Full Access**

---

### Step 3.2: Codemagic Workflow Editor Configuration

Configure Codemagic entirely through its web UI (**Workflow Editor**, no `codemagic.yaml` needed):

1. **Repository Setup**:
   - Connect repository `https://github.com/k3lvincodes/klux-vip.git` (branch `main`).
   - Under **Project path**, enter: `app`
2. **Build Settings**:
   - **Flutter version**: Stable (or matched to your project).
   - **Xcode version**: Latest stable.
   - **Build Mode**: **Release** (Mode `Release` is required for TestFlight & App Store submissions; `Debug` will be rejected by Apple).
3. **Environment Variables**:
   - Add variable `ENV_FILE` containing your full `.env` configuration (Supabase URL, Anon Key, Stripe Publishable Key, Google Maps API Key, Didit credentials).
   - Codemagic injects this at build time into `app/.env`.
4. **iOS Code Signing (Automatic)**:
   - Under **Distribution** -> **iOS code signing**:
   - Select **Automatic code signing**.
   - Upload your App Store Connect API Key (`.p8` file).
   - Enter **Key ID** and **Issuer ID**.
   - Select Bundle Identifier: `com.kenick.vip.kenickVip`.
   - Provisioning profile type: `App Store`.
5. **App Store Connect Distribution**:
   - Under **Distribution** -> **App Store Connect**:
   - Check **Publishing to App Store Connect**.
   - Check **Submit to TestFlight**.

---

### Step 3.3: Critical Native iOS & CocoaPods Configuration (Already Solved in Code)

The following architectural fixes have already been committed to `app/ios/` to guarantee smooth Codemagic builds:

1. **DiditSDK Resolution & Subspec Synchronization** (`app/ios/Podfile`):
   - **Issue:** `DiditSDK` is not hosted on CocoaPods trunk (`cdn.cocoapods.org`). Furthermore, if `DIDIT_SDK_IOS_NFC_ENABLED` is unset, the Flutter plugin defaults to the full `DiditSDK` while the Podfile defaults to `Core`, resulting in CocoaPods duplicate framework conflicts: `The 'Pods-Runner' target has frameworks with conflicting names: diditsdk.xcframework`.
   - **Solution in `Podfile`:**
     ```ruby
     ENV['DIDIT_SDK_IOS_NFC_ENABLED'] = 'false'
     $DiditSdkIosVariant = 'core'
     platform :ios, '15.0'

     didit_sdk_ios_podspec = 'https://raw.githubusercontent.com/didit-protocol/sdk-ios/3.6.2/DiditSDK.podspec'

     target 'Runner' do
       use_frameworks!
       use_modular_headers!
       pod 'DiditSDK/Core', :podspec => didit_sdk_ios_podspec
       flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
     end
     ```
   - **Why `Core`:** Kenick VIP uses camera, microphone, photo library, and Face ID for identity verification. It does not perform NFC passport reading. Using `Core` prevents Apple review rejection for undeclared NFC entitlements and reduces build size by ~120MB (omits OpenSSL).

2. **Apple App Icon Alpha Channel Compliance (Error 90717)**:
   - **Issue:** Apple App Store Connect strictly rejects any app icon with an alpha channel or transparent corners (`ERROR: Invalid large app icon. The large app icon in the asset catalog in “Runner.app” can’t be transparent or contain an alpha channel`).
   - **Solution:** All 21 icon sizes in `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` are formatted strictly as **24-bit RGB PNGs without alpha channel**, composited onto a solid `#000000` square background. Apple's iOS automatically handles corner rounding dynamically on devices.
   - Master 1024x1024 icon for App Store listing is preserved at: `Kenick_app_icon_1024x1024_apple_standard.png`.

---

### Step 3.4: Processing & TestFlight Distribution

Once Codemagic finishes building and uploads the `.ipa`:

1. **Processing in App Store Connect (5–15 min)**:
   - Open [App Store Connect](https://appstoreconnect.apple.com/) -> **Apps** -> **Kenick** -> **TestFlight**.
   - Build `1.0.0 (1)` will show as **Processing**.
2. **Export Compliance**:
   - When processing completes, a yellow **Missing Compliance** warning will appear.
   - Click **Manage** / **Provide Export Compliance Information**.
   - Select **No** for proprietary encryption (standard HTTPS/TLS used by Supabase, Stripe, and Flutter is exempt).
3. **Internal Testing on Physical iPhone**:
   - In the TestFlight tab sidebar, click **Internal Testing** -> Add your email.
   - Open the **TestFlight** app on your iPhone, accept the invite, and install the build.
   - Verify live map tiles, real GPS location tracking, Supabase authentication, and Stripe payment flows.
4. **App Store Public Submission**:
   - In the **1.0.0 Prepare for Submission** tab:
     - Select the processed build under **Build**.
     - Provide App Store listing details, 6.7" iPhone screenshots, and support URLs.
     - Enter Demo Reviewer credentials in **App Review Information**.
     - Click **Submit for Review**.

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

### Phase 3: Apple App Store (Codemagic Workflow Editor - No Mac)
- [x] Create App ID `com.kenick.vip.kenickVip` in Apple Developer Portal.
- [x] Generate App Store Connect API Key (`.p8`, Issuer ID, Key ID).
- [x] Create the new App record in App Store Connect.
- [x] Configure Codemagic Workflow Editor with automatic code signing & App Store Connect integration.
- [x] Resolve CocoaPods DiditSDK dependency & subspec conflict in `Podfile`.
- [x] Fix Apple App Store Icon 90717 compliance (24-bit RGB, no alpha/transparency).
- [x] Successfully build `.ipa` in Release mode and upload to App Store Connect via Codemagic.
- [ ] Complete Export Compliance in App Store Connect (select "No" for encryption).
- [ ] Test the release build on a physical iPhone via TestFlight Internal Testing.
- [ ] Submit the build for **App Store Review** with demo reviewer credentials and store screenshots.
