# MediCompare

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.x-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen.svg)
![Backend](https://img.shields.io/badge/Backend-FastAPI%20%7C%20Railway-success)

## Overview

MediCompare is a cross-platform mobile application developed in Flutter for comparing medicine prices across pharmacies operating in Pakistan. The application retrieves pricing data through a dedicated FastAPI backend that performs real-time web scraping, and it employs Firebase for authentication and data persistence and Google Gemini AI for comparative medicine analysis.

The backend service is maintained in a separate repository: [https://github.com/FatimaAsif1211/MediCompare-Backend-Model]

## Core Features

- **Live Price Comparison** — Retrieves current prices from twelve or more pharmacies and automatically identifies the lowest available price for a given medicine.
- **AI-Assisted Analysis** — Integrates Google Gemini to generate comparative summaries of alternative medicines.
- **Authentication** — Email and password authentication with password recovery, implemented through Firebase Authentication.
- **Personal Medicine Cabinet** — Enables users to record, update, and remove entries for medicines they use, with data synchronized through Cloud Firestore.
- **Best Deals Feed** — Presents a curated list of the lowest verified prices across tracked products.
- **Category Browsing** — Organizes medicines into categories such as vitamins, baby care, and heart care.
- **Deep Linking** — Allows direct navigation from within the application to the corresponding pharmacy product page.
- **User Interface** — Comprises more than thirty screens implemented using Material Design principles.

## Technology Stack

| Component | Technology |
|---|---|
| Framework | Flutter 3.x |
| Language | Dart |
| State Management | Provider |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| AI Integration | Google Gemini AI |
| Backend API | FastAPI (Python) |
| Backend Hosting | Railway |
| Supported Platforms | Android, iOS, Web |

## Prerequisites

- Flutter SDK, version 3.0.0 or later
- Android Studio or Visual Studio Code
- A Firebase account (the free tier is sufficient)
- A Google Gemini API key

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/medicompare-mobile.git
cd medicompare-mobile

# Install dependencies
flutter pub get

# Configure Firebase (see below), then run the application
flutter run
```

## Firebase Configuration

1. Create a project in the Firebase Console.
2. Enable Email/Password authentication.
3. Create a Cloud Firestore database.
4. Download and place the configuration files as follows:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

### Firestore Security Rules

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

## Backend Integration

The application communicates with the FastAPI backend to obtain pharmacy pricing data. The backend is maintained in a separate repository: [MediCompare-Backend-Model](#).

### Backend Configuration

The backend base URL is defined in `lib/utils/scraper_service.dart` and should be updated according to the deployment environment:

```dart
const String baseUrl = 'http://localhost:8000'; // Development
// const String baseUrl = 'https://your-backend.railway.app'; // Production
```

### Backend Capabilities

- REST API implemented with FastAPI
- Scrapers for twelve or more pharmacies
- Price normalization and sorting
- Automatic detection of the lowest available price
- Deployment on Railway

## Application Screens

| Screen | Purpose |
|---|---|
| Authentication | Login, registration, and password recovery |
| Home Dashboard | Category browsing and popular medicines |
| Medicine Detail | Dosage, side effects, and warnings |
| Price Comparison | Current prices across pharmacies |
| AI Compare | Gemini-generated comparative analysis |
| Medicine Cabinet | Management of the user's personal medicine inventory |
| Best Deals | Lowest verified prices across all tracked products |
| Profile | Account and application settings |

## Building for Production

### Android

```bash
# APK
flutter build apk --release

# App Bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
firebase deploy --only hosting
```

## Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

## System Architecture

```
+-------------------------------------------------------------+
|                      Flutter Frontend                        |
|  +---------------------------------------------------------+ |
|  |                 30+ UI Screens                          | |
|  |          Provider (State Management)                    | |
|  +---------------------------------------------------------+ |
|  +---------------------------------------------------------+ |
|  |                  Service Layer                          | |
|  |   scraper_service.dart   |   ai_service.dart             | |
|  +---------------------------------------------------------+ |
+-------------------------------------------------------------+
                            |  HTTP
                            v
+-------------------------------------------------------------+
|                FastAPI Backend (Railway)                     |
|              12+ Pharmacy Web Scrapers                       |
|             (MediCompare-Backend-Model)                      |
+-------------------------------------------------------------+
                            |
                            v
+-------------------------------------------------------------+
|                    External Services                         |
|   Firebase Auth   |   Cloud Firestore   |   Google Gemini     |
|   12+ Pharmacies  |   Pharmacy APIs     |                     |
+-------------------------------------------------------------+
```

## Data Model

### Medicine Cabinet Structure

```
users/
  └── {uid}/
        ├── email: string
        ├── name: string
        ├── createdAt: timestamp
        └── medicines/
              └── {docId}/
                    ├── name: string
                    ├── quantity: string
                    ├── status: string
                    └── updatedAt: timestamp
```

## Troubleshooting

**Firebase not initialized**
- Confirm that `google-services.json` is placed in the correct directory.
- Verify that the Firebase project is properly configured.

**Backend connection failed**
- Check the backend URL configured in `scraper_service.dart`.
- Confirm that the backend service is running.
- Review the backend's CORS configuration.

**Authentication errors**
- Confirm that Firebase Authentication is enabled for the project.
- Validate that the submitted email and password meet the required format.

**Medicine cabinet not updating**
- Review the Firestore security rules.
- Confirm that the user is authenticated.
- Verify network connectivity.

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/feature-name`.
3. Commit the changes: `git commit -m 'Add feature'`.
4. Push the branch: `git push origin feature/feature-name`.
5. Open a pull request.

## License

This project is distributed under the MIT License. See the `LICENSE` file for details.

## Contact

- Issues: GitHub Issues page of this repository
- Backend Repository: [https://github.com/FatimaAsif1211/MediCompare-Backend-Model](#)         
