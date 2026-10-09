# Wireless Flutter Debugging Guide (Via Phone Hotspot)

This guide documents the exact steps to run and debug the Flutter app (`app`) wirelessly on your physical Android phone using your **phone's mobile hotspot**—without needing a third-party Wi-Fi router, and without keeping any USB cord attached.

---

## 📋 Background & How It Works

* **The Setup:** The phone acts as a Mobile Hotspot providing internet to your laptop.
* **The Mechanism:** Instead of the restrictive Android 11 "Wireless Debugging" toggle (which gets disabled when hosting a hotspot), we use Android's native **ADB TCP/IP (port 5555)** daemon.
* **The Cord:** A USB cable is only needed for **5 seconds** once per phone reboot to start the listener. After that, the cord is unplugged and development is 100% wireless with real-time Hot Reload.

---

## 🛠️ Prerequisites

1. **USB Debugging Enabled on Phone:**
   * Go to **Settings > About Phone** > Tap **Build Number** 7 times to enable Developer Options.
   * Go to **Settings > Developer Options** > Turn **ON** `USB Debugging`.
2. **ADB Path on Laptop:**
   * Your Android SDK ADB executable is located at:
     ```text
     C:\Android\Sdk\platform-tools\adb.exe
     ```

---

## 🚀 How to Connect & Run (Step-by-Step)

### Step 1: Turn on Phone Hotspot & Connect Laptop
1. On your phone, turn on **Personal Hotspot**.
2. On your Windows laptop, connect your Wi-Fi to your phone's hotspot.

### Step 2: Initialize ADB TCP Mode (5-second cord handshake)
1. Plug your phone into your laptop with a USB cable.
2. In PowerShell, enable TCP mode on port `5555`:
   ```powershell
   & "C:\Android\Sdk\platform-tools\adb.exe" tcpip 5555
   ```
   *Expected output:* `restarting in TCP mode port: 5555`
3. **Unplug the USB cord and put it away.**

### Step 3: Find Your Phone's Gateway IP
Because your phone is hosting the hotspot, your phone is the **Default Gateway** for your laptop.
1. Run `ipconfig` in PowerShell:
   ```powershell
   ipconfig
   ```
2. Look under **Wireless LAN adapter Wi-Fi** for **Default Gateway**:
   ```text
   IPv4 Address. . . . . . . . . . . : 10.252.235.172
   Default Gateway . . . . . . . . . : 10.252.235.160
   ```
   *(In this case, the phone IP is `10.252.235.160`)*.

### Step 4: Connect Wirelessly Over ADB
Connect your laptop to the phone's IP on port 5555:
```powershell
& "C:\Android\Sdk\platform-tools\adb.exe" connect 10.252.235.160:5555
```
*Expected output:* `connected to 10.252.235.160:5555`

> **Note:** If prompted on the phone with "Allow debugging over network?", tap **Allow** and check "Always allow".

### Step 5: Verify Connected Devices
Check that Flutter recognizes your phone wirelessly:
```powershell
flutter devices
```
You will see your physical phone listed as an active target device:
```text
TECNO KM5 (mobile) • 10.252.235.160:5555 • android-arm64 • Android 15 (API 35)
```

### Step 6: Run Your App in Real Time
Navigate into your `app` folder and launch:
```powershell
cd app
flutter run
```
* **Hot Reload:** Press `r` in the terminal to instantly apply code changes.
* **Hot Restart:** Press `R` in the terminal for a full state reset.

---

## 🛑 How to Shut Everything Down Cleanly

When you are done with your development session:

### 1. Stop the Running Flutter App
In the terminal where Flutter is running, press:
```text
q
```
This stops the debug session, unhooks the Dart VM Service, and returns you to the PowerShell prompt.

### 2. Disconnect the Wireless ADB Session
Disconnect ADB from your phone's wireless port:
```powershell
& "C:\Android\Sdk\platform-tools\adb.exe" disconnect 10.252.235.160:5555
```
*(Or disconnect all wireless devices at once:)*
```powershell
& "C:\Android\Sdk\platform-tools\adb.exe" disconnect
```
*Expected output:* `disconnected everything`

### 3. (Optional) Shut Down the ADB Background Server
If you want to free background memory and terminate the local ADB daemon completely:
```powershell
& "C:\Android\Sdk\platform-tools\adb.exe" kill-server
```

### 4. Turn Off Mobile Hotspot
Turn off **Personal Hotspot** on your phone to conserve battery and cellular data.

---

## 💡 Quick Tips & Troubleshooting

| Scenario | What to do |
|---|---|
| **Do I need to plug the cord in every day?** | **No.** As long as your phone has not been restarted or powered off, TCP mode stays active on port 5555. You only need to reconnect with `adb connect <Gateway-IP>:5555`. |
| **I restarted my phone.** | You must plug the cord in for 5 seconds and run `adb tcpip 5555` once again to restart the port. |
| **"Cannot connect (10060)" error.** | Hotspot IPs can occasionally change when toggled off and on. Run `ipconfig` in PowerShell and check the current `Default Gateway` IP under the Wi-Fi adapter. |
| **Tired of typing the full ADB path?** | Add `C:\Android\Sdk\platform-tools` to your Windows User `Path` Environment Variable so you can just type `adb` instead of the full path. |
