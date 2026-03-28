# Hibiscus Efsya Sales App

<p align="center">
	<img src="assets/images/hibiscusefsya1-removebg-preview.png" alt="Hibiscus Efsya" width="260" />
</p>

## Tech Stack

### Core Framework

- **Framework**: Flutter 3.0+ (Dart 3.0+)
- **Platforms**: Android, Web

### State Management & Navigation

- **State Management**: Provider ^6.1.0
- **Localization**: intl ^0.19.0

### Networking & Storage

- **HTTP Client**: http ^1.2.0 (with custom `ApiService`)
- **Local Storage**:
  - Shared Preferences ^2.2.0 (user preferences)
  - Flutter Secure Storage ^9.2.0 (sensitive data)
- **Database**: SQLite via sqflite
- **File Caching**: cached_network_image ^3.3.0

### Location Services

- **Geolocation**: geolocator ^12.0.0
- **Geocoding**: geocoding ^3.0.0

### Media & File Management

- **Image Picker**: image_picker ^1.0.0
- **Camera**: camera ^0.11.0+1
- **File Picker**: file_picker ^8.0.0
- **File Access**: path_provider ^2.1.0
- **Sharing**: share_plus ^9.0.0

### Permissions

- **Permission Handler**: permission_handler ^11.3.0

### QR Code & Barcode

- **QR Generator**: qr_flutter ^4.1.0
- **Barcode Scanner**: mobile_scanner ^5.1.1
- **Barcode Display**: barcode_widget ^2.0.3

### Bluetooth & Printing

- **Bluetooth Serial**: flutter_bluetooth_serial ^0.4.0
- **ESC/POS Printing**: esc_pos_utils_plus ^2.0.4

### Data Visualization

- **Charts**: fl_chart ^0.68.0

### UI & UX

- **Shimmer Effect**: shimmer ^3.0.0
- **Icons**: cupertino_icons ^1.0.6
- **Custom Fonts**: Poppins (Regular, Medium, SemiBold, Bold)

### Development Tools

- **Flutter Lints**: ^3.0.0
- **App Icon Generator**: flutter_launcher_icons ^0.14.3

## Backend Integration

### API Connection

Aplikasi terhubung dengan REST API backend melalui custom `ApiService` yang terletak di [lib/services/api_service.dart](lib/services/api_service.dart).

**Base URL**: Dikonfigurasi di [lib/config/app_config.dart](lib/config/app_config.dart)
```dart
static const String baseUrl = 'https://sales.hibiscusefsya.com/api/v1';
```

### Supported HTTP Methods

API Service mendukung:
- `GET` - Mengambil data
- `POST` - Membuat data baru
- `PUT` - Memperbarui data
- `DELETE` - Menghapus data
- `getBytes` - Download file (PDF, Excel, dll)

### Authentication & Token Management

Aplikasi menggunakan **Bearer Token Authentication** dengan berikut:

1. **Login Flow**:
   - User login dengan email dan password
   - Backend mengembalikan `token` dan `user` data
   - Token disimpan di Shared Preferences dengan key `auth_token`

2. **Token Storage**:
   - **Secure Token**: Disimpan menggunakan Flutter Secure Storage
   - **User Data**: Disimpan di Shared Preferences
   - **Auto-login**: Aplikasi mencoba auto-login saat startup jika token masih valid

3. **Token Injection**:
   - Setiap request otomatis menambahkan header:
   ```
   Authorization: Bearer {token}
   Accept: application/json
   Content-Type: application/json
   ```

4. **Token Validation**:
   - Setiap kali app dibuka, token diverifikasi dengan endpoint `GET /profile`
   - Jika token expired, user akan di-logout otomatis

5. **Logout**:
   - Endpoint `POST /logout` dipanggil untuk invalidate token di backend
   - Token dan user data dihapus dari local storage

**Auth Provider**: [lib/providers/auth_provider.dart](lib/providers/auth_provider.dart)

### Backend Technology Stack

Backend API menggunakan:
- **Framework**: Laravel (PHP)
- **API Version**: v1 (REST API)
- **Authentication**: Sanctum (Token-based)
- **Base URL**: sales.hibiscusefsya.com

## Build & Setup

### Prerequisites

- Flutter SDK 3.0+ ([install](https://flutter.dev/docs/get-started/install))
- Dart 3.0+
- Android SDK (untuk Android build)
- Git

### Installation

```bash
# Clone repository
git clone https://github.com/Faizpi/hibiscusefsya-sales-app.git
cd flutter_app

# Get dependencies
flutter pub get

# Generate app icons
flutter pub run flutter_launcher_icons

# Generate localization (jika ada)
flutter gen-l10n
```

### Development Build

```bash
# Run app di device/emulator
flutter run

# Run dengan debug logs
flutter run -v

# Run di web
flutter run -d chrome

# Run di Android emulator
flutter run -d emulator-5554
```

### Production Build

#### Android APK
```bash
# Build APK
flutter build apk --release

# Build split ABIs (lebih optimal)
flutter build apk --release --split-per-abi

# Output: build/app/outputs/flutter-apk/
```

#### Android App Bundle (untuk Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/
```

#### Web Build
```bash
flutter build web --release
# Output: build/web/
```

### Configuration

Sebelum build, pastikan untuk mengatur:

1. **API Base URL** - Edit [lib/config/app_config.dart](lib/config/app_config.dart):
   ```dart
   static const String baseUrl = 'https://sales.hibiscusefsya.com/api/v1';
   ```

2. **App Icons** - Edit [pubspec.yaml](pubspec.yaml) bagian `flutter_launcher_icons`:
   ```yaml
   flutter_launcher_icons:
     android: true
     image_path: assets/images/hibiscusefsya1.png
   ```

3. **Android Signing** - Buat `android/key.properties`:
   ```properties
   storeFile=../app_release.keystore
   storePassword=your_store_password
   keyAlias=key_alias_name
   keyPassword=your_key_password
   ```

### Environment Variables

Untuk production, ikuti langkah-langkah di [android/local.properties](android/local.properties).

## Project Structure

```
lib/
├── config/           # Konfigurasi app (API base URL, constants)
├── main.dart         # Entry point aplikasi
├── models/           # Data models
├── providers/        # State management (Provider)
├── screens/          # UI screens
├── services/         # API service dan business logic
├── utils/            # Helper functions dan formatters
└── widgets/          # Custom widgets
```

