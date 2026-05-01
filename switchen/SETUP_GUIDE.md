# Switchen — Setup Guide

## Prasyarat

Pastikan semua tools berikut sudah terinstall:

| Tool | Versi | Link |
|---|---|---|
| Flutter SDK | ≥ 3.3.0 | https://flutter.dev/docs/get-started/install/windows |
| Dart SDK | Bundled dengan Flutter | - |
| Android Studio | Latest | https://developer.android.com/studio |
| Xcode (Mac only) | ≥ 15 | App Store |
| VS Code | Latest | https://code.visualstudio.com |
| Node.js | ≥ 18 | https://nodejs.org |
| Supabase CLI | Latest | `npm install -g supabase` |

---

## Step 1: Install Flutter

1. Download Flutter SDK dari https://flutter.dev/docs/get-started/install/windows
2. Extract ke `C:\flutter` (atau path pilihanmu)
3. Tambahkan `C:\flutter\bin` ke PATH environment variable:
   - Buka System Properties → Environment Variables
   - Edit `Path` → New → `C:\flutter\bin`
4. Verifikasi: buka terminal baru, jalankan `flutter doctor`
5. Pastikan semua ✅ sebelum lanjut

---

## Step 2: Buat Flutter Project

Karena semua kode sudah disiapkan, jalankan:

```bash
cd "d:\0Semester 4\IYREF"
flutter create switchen --org com.switchen --platforms android,ios --project-name switchen
```

> ⚠️ Ini akan buat file default. Kita sudah punya kode kita sendiri, jadi hapus file default yang tidak dibutuhkan.

Kemudian install dependencies:
```bash
cd switchen
flutter pub get
```

---

## Step 3: Setup Supabase

1. Buka https://supabase.com/dashboard
2. Klik **New Project** → isi nama "switchen", set password DB
3. Setelah project ready, buka **SQL Editor**
4. Copy-paste isi file `supabase/schema.sql` dan klik **Run**
5. Buka **Settings → API** → copy:
   - `Project URL` → masukkan ke `.env` sebagai `SUPABASE_URL`
   - `anon/public key` → masukkan ke `.env` sebagai `SUPABASE_ANON_KEY`

### Setup Storage Buckets
Di Supabase Dashboard → **Storage**:
1. Buat bucket `product-images` (public: ✅)
2. Buat bucket `partner-logos` (public: ✅)

---

## Step 4: Setup Google Maps API

1. Buka https://console.cloud.google.com
2. Buat project baru "switchen"
3. Aktifkan APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API**
   - **Places API**
4. Buka **Credentials** → **Create Credentials** → **API Key**
5. Salin API key → masukkan ke `.env` sebagai `GOOGLE_MAPS_API_KEY`

### Android Config
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application ...>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
  ...
</application>
```

### iOS Config
Edit `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
// Tambahkan di application(_:didFinishLaunchingWithOptions:):
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

Edit `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Switchen perlu akses lokasi untuk menampilkan toko terdekat</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Switchen perlu akses lokasi untuk notifikasi toko terdekat</string>
```

---

## Step 5: Setup Firebase (FCM)

1. Buka https://console.firebase.google.com
2. Buat project "switchen"
3. Tambahkan app Android:
   - Package name: `com.switchen`
   - Download `google-services.json` → pindahkan ke `android/app/`
4. Tambahkan app iOS:
   - Bundle ID: `com.switchen`
   - Download `GoogleService-Info.plist` → tambahkan ke Xcode project (`ios/Runner/`)
5. Install Firebase CLI: `npm install -g firebase-tools`
6. Jalankan: `flutterfire configure`

### Android: tambahkan di `android/build.gradle`:
```groovy
dependencies {
  classpath 'com.google.gms:google-services:4.4.0'
}
```

### Android: tambahkan di `android/app/build.gradle`:
```groovy
apply plugin: 'com.google.gms.google-services'
```

---

## Step 6: Setup Midtrans Sandbox

1. Daftar di https://dashboard.sandbox.midtrans.com
2. Buka **Settings → Access Keys**
3. Copy **Client Key** (prefix `SB-Mid-client-`) → masukkan ke `.env` sebagai `MIDTRANS_CLIENT_KEY`
4. Copy **Server Key** (prefix `SB-Mid-server-`) → akan dipakai di Supabase secrets

---

## Step 7: Deploy Edge Functions

Install Supabase CLI:
```bash
npm install -g supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Set secrets untuk Edge Functions:
```bash
supabase secrets set MIDTRANS_SERVER_KEY=SB-Mid-server-xxxx
supabase secrets set FCM_SERVER_KEY=your-fcm-server-key
supabase secrets set QR_SECRET=switchen_qr_secret_2024_prod
```

Deploy semua edge functions:
```bash
supabase functions deploy rotation-algo
supabase functions deploy generate-coupon
supabase functions deploy send-notification
supabase functions deploy midtrans-webhook
```

Daftarkan URL webhook Midtrans di dashboard Midtrans:
```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-webhook
```

---

## Step 8: Jalankan App

```bash
cd "d:\0Semester 4\IYREF\switchen"
flutter pub get
flutter run
```

Untuk build APK debug:
```bash
flutter build apk --debug
```

---

## Tambahkan `pinput` ke pubspec.yaml

Package untuk OTP input (lupa ditambahkan di pubspec.yaml awal):
```yaml
pinput: ^5.0.0
```

---

## Struktur File yang Sudah Dibuat

```
switchen/
├── .env                          ✅ Template env vars
├── pubspec.yaml                  ✅ Semua dependencies
├── supabase/
│   ├── schema.sql                ✅ Database schema lengkap
│   └── functions/
│       ├── rotation-algo/        ✅ Algoritma rotasi toko
│       ├── generate-coupon/      ✅ Generate QR token
│       ├── send-notification/    ✅ FCM push notif
│       └── midtrans-webhook/     ✅ Payment callback
└── lib/
    ├── main.dart                 ✅
    ├── app.dart                  ✅ Material3 + Outfit font
    ├── router.dart               ✅ GoRouter semua routes
    ├── injection_container.dart  ✅ GetIt DI semua fitur
    └── core/
        ├── constants/            ✅ colors, strings, routes
        ├── errors/               ✅ failures, exceptions
        ├── network/              ✅ supabase_client, network_info
        ├── usecases/             ✅ base abstract classes
        └── utils/                ✅ logger, date_helper, qr_generator
    └── features/
        └── auth/                 ✅ LENGKAP (all layers)
        └── store_discovery/      🔄 Domain layer siap, data & presentation belum
        └── order/                ⏳ Belum
        └── payment/              ⏳ Belum
        └── coupon/               ⏳ Belum
        └── partner_dashboard/    ⏳ Belum
        └── admin/                ⏳ Belum
        └── notification/         ⏳ Belum
```

Legend: ✅ Selesai | 🔄 Sebagian | ⏳ Belum
