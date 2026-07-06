# 🌸 PCOS Wellness Tracker

A Flutter mobile application designed to help women with Polycystic Ovary Syndrome (PCOS) monitor their daily wellness, food intake, menstrual cycle, and receive AI-powered wellness insights.

---

## 📱 Features

### 🔐 Authentication
- User Registration
- User Login
- Secure Logout
- Firebase Authentication

### 🏠 Dashboard
- Wellness overview
- Quick navigation
- Latest wellness information

### 📝 Daily Wellness Log
Users can record:
- Mood
- Sleep
- Water intake
- Stress level
- Energy level
- Weight

### 🍓 Food Tracker
- Breakfast
- Lunch
- Dinner
- Snacks
- Cravings

### 🌸 Cycle Tracker
- Period tracking
- Flow tracking
- Symptoms
- Medication
- Predicted next period
- Estimated ovulation

### 📊 Insights
- Wellness Score
- Mood trends
- Sleep trends
- Water intake chart
- Weight chart
- Cycle Summary
- Food Summary
- AI Wellness Coach

### 👤 Profile
- User information
- Account details
- Logout

---

## 🛠 Technologies Used

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Google Gemini API
- FL Chart

---

## 🤖 AI Wellness Coach

The application integrates Google's Gemini API to generate personalised wellness recommendations based on:

- Daily wellness logs
- Food logs
- Cycle logs

The AI provides supportive lifestyle recommendations only and is **not intended to diagnose or treat medical conditions**.

---

## 🗄 Database

Cloud Firestore stores:

- User Profile
- Daily Logs
- Food Logs
- Cycle Logs

Each user's data is securely separated using their Firebase Authentication UID.

---

---

# 🚀 Getting Started

## Prerequisites

Before running the project, ensure the following are installed:

- Flutter SDK (3.x or later)
- Dart SDK
- Android Studio (recommended)
- Visual Studio Code (optional)
- Firebase CLI (optional)
- Git

Verify Flutter installation:

```bash
flutter doctor
```

Resolve any issues reported by Flutter before continuing.

---

# 📥 Clone the Repository

```bash
git clone https://github.com/AlyshaAnne/pcos_wellness.git
cd pcos_wellness
```

Install dependencies:

```bash
flutter pub get
```

---

# 🔥 Firebase Setup

This project uses Firebase Authentication and Cloud Firestore.

Create your own Firebase project and configure:

- Firebase Authentication
- Cloud Firestore

Replace the Firebase configuration files with your own:

### Android

```
android/app/google-services.json
```

### iOS

```
ios/Runner/GoogleService-Info.plist
```

---

# 🤖 Gemini AI Setup

This project uses Google's Gemini API.

1. Create a Gemini API key from Google AI Studio.
2. Open:

```
lib/services/ai_service.dart
```

3. Replace:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY';
```

with your own API key.

---

# ▶ Running the Application

## Android Device

Connect an Android phone with **USB Debugging** enabled or start an Android Emulator.

Check connected devices:

```bash
flutter devices
```

Run:

```bash
flutter run
```

---

## Android Emulator

Open Android Studio.

Start an emulator from:

```
Device Manager
```

Then run:

```bash
flutter run
```

---

## Windows Desktop

Enable Windows desktop support if required:

```bash
flutter config --enable-windows-desktop
```

Run:

```bash
flutter run -d windows
```

---

## Web Browser

Run:

```bash
flutter run -d chrome
```

or

```bash
flutter run -d edge
```

---

## iOS (macOS only)

Open:

```
ios/Runner.xcworkspace
```

using Xcode.

Run:

```bash
flutter run -d ios
```

---

# 📂 Project Structure

```
lib/
│
├── config/
├── models/
├── screens/
│   ├── auth/
│   ├── dashboard/
│   ├── daily_log/
│   ├── food/
│   ├── cycle/
│   ├── insights/
│   └── profile/
│
├── services/
├── theme/
├── widgets/
└── main.dart
```

---

# 📄 License

This project was developed for educational purposes as part of a Final Year Project at Asia Pacific University (APU).

---

## 👩‍💻 Author

**Alysha Anne Ariventran**

Bachelor of Software Engineering

Asia Pacific University (APU)

Final Year Project
