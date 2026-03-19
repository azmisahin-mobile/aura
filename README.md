# 🌌 AURA: Sound of Your Rhythm

> "Don't choose your music. Let your life choose the sound."

**AURA**, seçim yorgunluğuna ve abonelik dayatmalarına karşı geliştirilmiş, cihazın derinliklerinde yaşayan bir **"Görünmez Audio Engine"**dir.

### 🧠 AURA Neural Matrix (Zeka Katmanı)
AURA, seni bir veritabanına hapseden algoritmalar yerine, senin tepkilerini cihaz içinde (Offline) öğrenen bir **Neural Matrix** kullanır:
- **Öğrenme:** Bir frekansı 30 saniye dinlersen AURA bunu ödüllendirir.
- **Unutma:** Sola kaydırdığın (Dislike) türler cezalandırılır. Puanı düşen türler karalisteye alınır ve bir daha asla karşına çıkmaz.
- **Keşif:** %20 ihtimalle sana konfor alanının dışından yeni bir kapı açar.

### 🎧 Öne Çıkan Özellikler
- **Zero-UI:** Ekrana bakmana gerek yok. AURA titreşimlerle (Haptic) seninle iletişim kurar.
- **Kültürel & Çevresel Bağlam:** GPS ile ülkeni (TR, DE, vb.), sensörlerle hareketini, hava durumu servisiyle modunu anlar.
- **Ölümsüz Akış (Auto-Heal):** Kırık linkleri, sessiz yayınları (Dead-Air) ve internet kopmalarını algılar; kendi kendini iyileştirerek akışı asla bozmaz.

### 🛠️ Teknoloji Yığını
- **Core:** Flutter (Dart), Clean Architecture (DDD)
- **AI:** Local Reinforcement Learning (Bandit Algorithm)
- **Context Engine:** `geolocator`, `geocoding`, `sensors_plus`, Open-Meteo API
- **Audio:** `just_audio` (Smart Buffering & Playlist API)


## 🤖 Geliştirme
```bash
flutter clean
flutter pub get
flutter run | grep "flutter"
```

Live
```bash
flutter clean
flutter run --release
```

Lütfen `docs/INSTRUCTIONS.md` , `docs/INSTRUCTIONS.md`, `docs/SPEC.md`, `AURA_ARCHITECTURE_SPEC.md` ve `docs/CHANGELOG.md`  dosylarını okuyarak geliştirmeye devam edin.