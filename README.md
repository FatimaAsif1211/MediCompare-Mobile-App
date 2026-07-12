
MediCompare - Mobile Application

https://img.shields.io/badge/Flutter-3.x-blue.svg
https://img.shields.io/badge/Dart-3.x-blue.svg
https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-orange.svg
https://img.shields.io/badge/License-MIT-green.svg
https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen.svg
https://img.shields.io/badge/Backend-FastAPI%20%7C%20Railway-success

Overview

MediCompare is a healthcare mobile application developed using Flutter that enables users to compare medicine prices across 12+ pharmacies in Pakistan. The application integrates with a FastAPI backend for real-time web scraping, Firebase for authentication and data persistence, and Google Gemini AI for intelligent medicine analysis.

Backend Repository: MediCompare-Backend-Model

Core Features

· Live Price Comparison: Real-time scraping from 12+ pharmacies with automatic best price detection
· AI-Powered Analysis: Google Gemini integration for side-by-side medicine comparisons
· Firebase Authentication: Secure email/password authentication with password recovery
· Personal Medicine Cabinet: Complete CRUD operations with Cloud Firestore synchronization
· Best Deals Feed: Curated feed of lowest verified prices
· Category Browsing: Organized by Vitamins, Baby Care, Heart Care, and more
· 30+ Screens: Comprehensive Material Design user interface
· Deep Linking: Direct navigation to pharmacy product pages

Technology Stack

Component Technology
Framework Flutter 3.x
Programming Language Dart
State Management Provider
Authentication Firebase Authentication
Database Cloud Firestore
AI Integration Google Gemini AI
Backend API FastAPI (Python)
Backend Hosting Railway
Platforms Android, iOS, Web

Quick Start

Prerequisites

· Flutter SDK (^3.0.0)
· Android Studio or Visual Studio Code
· Firebase Account (free tier)
· Google Gemini API Key

Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/medicompare-mobile.git
cd medicompare-mobile

# Install dependencies
flutter pub get

# Configure Firebase (add configuration files)
# Run the application
flutter run
```

Firebase Configuration

1. Create a project at Firebase Console
2. Enable Email/Password authentication
3. Create a Cloud Firestore database
4. Download configuration files:
   · Android: google-services.json → android/app/
   · iOS: GoogleService-Info.plist → ios/Runner/

Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      match /medicines/{document} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

Backend Integration

The application communicates with the FastAPI backend for price scraping services. The backend repository is maintained separately:

Backend Repository: MediCompare-Backend-Model

Backend Configuration

Update the backend URL in lib/utils/scraper_service.dart:

```dart
const String baseUrl = 'http://localhost:8000'; // Development
// const String baseUrl = 'https://your-backend.railway.app'; // Production
```

Backend Features

· FastAPI-based REST API
· 12+ pharmacy web scrapers
· Price normalization and sorting
· Automatic best price detection
· Deployed on Railway

Application Screens

Screen Purpose
Authentication Login, Signup, Password Recovery
Home Dashboard Categories and popular medicines
Medicine Detail Dosage, side effects, warnings
Price Comparison Live prices from all pharmacies
AI Compare Gemini-powered side-by-side analysis
Medicine Cabinet Personal inventory management
Best Deals Lowest prices across all products
Profile User settings and account management

Building for Production

Android

```bash
# APK
flutter build apk --release

# App Bundle
flutter build appbundle --release
```

iOS

```bash
flutter build ios --release
```

Web

```bash
flutter build web --release
firebase deploy --only hosting
```

Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

System Architecture

```
+-----------------------------------------------------------+
|                     Flutter Frontend                        |
|  +-----------------------------------------------------+  |
|  |                  30+ UI Screens                       |  |
|  |           Provider (State Management)                 |  |
|  +-----------------------------------------------------+  |
|  +-----------------------------------------------------+  |
|  |                   Service Layer                       |  |
|  |  scraper_service.dart  |  ai_service.dart           |  |
|  +-----------------------------------------------------+  |
+-----------------------------------------------------------+
                            | HTTP
                            v
+-----------------------------------------------------------+
|              FastAPI Backend (Railway)                     |
|          12+ Pharmacy Web Scrapers                         |
|      [MediCompare-Backend-Model]                           |
+-----------------------------------------------------------+
                            |
                            v
+-----------------------------------------------------------+
|                  External Services                          |
|  Firebase Auth  |  Cloud Firestore  |  Google Gemini      |
|  12+ Pharmacies |  Pharmacy APIs    |                     |
+-----------------------------------------------------------+
```

Data Models

Medicine Cabinet Structure

```
users/
  +-- {uid}/
      +-- email: string
      +-- name: string
      +-- createdAt: timestamp
      +-- medicines/
          +-- {docId}/
              +-- name: string
              +-- quantity: string
              +-- status: string
              +-- updatedAt: timestamp
```

Troubleshooting

Common Issues

Firebase Not Initialized

· Verify google-services.json is in the correct location
· Confirm Firebase project is properly configured

Backend Connection Failed

· Check the backend URL in scraper_service.dart
· Verify the backend service is running
· Review CORS configuration

Authentication Errors

· Confirm Firebase Authentication is enabled
· Validate email/password requirements

Cabinet Not Updating

· Review Firestore security rules
· Verify user authentication status
· Check network connectivity

Contributing

1. Fork the repository
2. Create a feature branch (git checkout -b feature/feature-name)
3. Commit changes (git commit -m 'Add feature')
4. Push to branch (git push origin feature/feature-name)
5. Open a Pull Request

License

MIT License - see LICENSE file for details.

Contact

· Issues: GitHub Issues
· Backend Repository: MediCompare-Backend-Model
