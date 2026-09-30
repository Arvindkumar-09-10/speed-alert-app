# 🚗 Speed Alert App

A real-time speed monitoring and safety alert application built with **Flutter**. The app tracks device movement using GPS location services, compares real-time speed against customizable threshold limits, and provides instant audio/visual alerts to help prevent overspeeding.

---

## ✨ Features

- 📍 **Real-Time Speed Tracking**: Live GPS speed detection displaying current speed in km/h.
- ⚠️ **Customizable Speed Limits**: Set custom speed thresholds tailored for city roads, highways, or personal safety preferences.
- 🔔 **Instant Safety Alerts**: Immediate visual warnings and audio alerts when speed exceeds the defined limit.
- 📱 **Cross-Platform**: Built on Flutter for smooth performance on Android, iOS, and desktop platforms.
- 🎨 **Clean & Intuitive UI**: Simple dashboard design focused on minimal driver distraction.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Location Services**: `geolocator` / GPS APIs
- **Version Control**: Git & GitHub

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- An Android device or emulator with Location/GPS enabled

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/Arvindkumar-09-10/speed-alert-app.git](https://github.com/Arvindkumar-09-10/speed-alert-app.git)
   cd speed-alert-app'''


INSTALL DEPENDENCIES:

flutter pub get




RUN THE APPLICATION:

flutter run







Note: For real-time speed testing, run the app on a physical mobile device with GPS enabled, or simulate movement via Android Emulator Extended Controls.



PROJECT STRUCTURE:

lib/
├── main.dart             # Application entry point
├── screens/              # UI screens & dashboard layouts
├── services/             # GPS location & speed tracking logic
└── widgets/              # Reusable UI components & alert badges
