# 📱 Quick Start Guide: Mobile + Backend

To run this app on your physical Android device easily, follow these two steps:

## 1. Start the Backend (Computer)
Double-click `release\run_backend.bat`.
This will:
- Check for Python
- Install dependencies
- Start the analyzer server on your machine.
- **Keep this window open!**

## 2. Install the App (Mobile)
1. Connect your phone via USB.
2. Ensure **USB Debugging** is enabled in Developer Options.
3. Double-click `start_mobile_app.bat`.
This will:
- Build the APK
- Install it directly to your connected phone.

## Troubleshooting
- **Connection Error**: Ensure your phone and computer are on the **SAME Wi-Fi**.
- **Firewall**: Your computer may block the phone. Ensure port `8000` is open or temporarily disable your firewall if it fails.
- **Python/Flutter**: Ensure both are in your system's PATH.
