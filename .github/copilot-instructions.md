# Instruksi Copilot untuk `mobile-opname`

## Gambaran Proyek
- **Tipe:** Aplikasi Flutter lintas platform (Android, iOS, Web, Desktop)
- **Entry point utama:** `lib/main.dart`
- **Arsitektur:**
  - Menggunakan pola BLoC (lihat `lib/bloc/`)
  - Lapisan service di `lib/services/`
  - Utilitas dan nilai bersama di `lib/shared/`
  - UI diatur di `lib/ui/pages/` dan `lib/ui/widgets/`
  - Model di `lib/models/`

## Alur Kerja Utama
- **Build:**
  - Perintah build Flutter standar (`flutter build <platform>`)
  - Android/iOS: Konfigurasi native di `android/` dan `ios/`
  - Desktop: Lihat `linux/`, `macos/`, `windows/`
- **Test:**
  - Jalankan semua tes: `flutter test`
  - Contoh tes: `test/widget_test.dart`
- **Debug:**
  - Gunakan alat debug bawaan Flutter
  - Konfigurasi spesifik platform di folder masing-masing

## Konvensi Proyek
- **Manajemen State:**
  - Pola BLoC untuk pemisahan logika bisnis
  - Alur autentikasi di `lib/bloc/auth/` dan `lib/services/auth_service.dart`
- **Kode Bersama:**
  - Metode/nilai umum di `lib/shared/`
  - Helper JWT & auth: `lib/shared/jwt_utils.dart`, `lib/shared/auth_service.dart`
- **UI:**
  - Halaman: `lib/ui/pages/`
  - Widget: `lib/ui/widgets/`
- **Aset:**
  - Tempatkan aset statis di `assets/`

## Integrasi & Dependensi
- **Dependensi Flutter/Dart:** Dikelola di `pubspec.yaml`
- **Integrasi native:**
  - Android: Konfigurasi Gradle di `android/`
  - iOS: CocoaPods di `ios/`
- **Skrip:**
  - Pembuatan ikon desktop: `scripts/generate_desktop_icons.ps1`

## Contoh
- Menambah halaman baru: buat file Dart di `lib/ui/pages/`, update navigasi jika perlu
- Menambah BLoC baru: letakkan di `lib/bloc/`, ikuti struktur BLoC yang ada
- Menambah service: implementasi di `lib/services/`, gunakan dependency injection jika diperlukan

## Referensi
- Entry point utama: `lib/main.dart`
- Contoh BLoC: `lib/bloc/auth/`
- Service autentikasi: `lib/services/auth_service.dart`
- Metode bersama: `lib/shared/`
- Tes widget: `test/widget_test.dart`

---
Untuk detail lebih lanjut, lihat `README.md` atau tanyakan contoh alur kerja spesifik.
