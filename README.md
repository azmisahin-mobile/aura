# 🌌 AURA: Sound of Your Rhythm

> "Don't choose your music. Let your life choose the sound."

**AURA**, seçim yorgunluğuna ve abonelik dayatmalarına karşı geliştirilmiş bir "Görünmez Audio Engine"dir. Kullanıcıyı bir arayüze hapsetmek yerine; sensörler, GPS, **Hava Durumu**, **Lokasyon (Ülke)** ve zaman verileriyle kullanıcının o anki "modunu" anlar ve en uygun açık kaynaklı ses akışını başlatır.

### 🎧 Neden AURA?
- **Sıfır Karar (Zero-UI):** Play'e bas ve unut. AURA seninle titreşimlerle (Haptic) konuşur.
- **Kültürel Lokasyon:** Bulunduğun ülkenin tınılarını hisseder. (Örn: Türkiye'deysen arka planda bir ney veya anadolu rock frekansı yakalayabilir).
- **Çevresel Farkındalık:** Yağmur yağıyorsa Jazz, güneşliyse Upbeat çalar.
- **Ölümsüz Motor:** Ekranı kilitle veya telefonu cebine koy. AURA arka planda internet kopsa bile cihazdaki önbelleği kullanır veya çevrimdışı ses üretir.

### 🛠️ Teknoloji Yığını
- **Core:** Flutter (Dart), Clean Architecture (DDD)
- **Audio & OS:** `just_audio` (Smart Buffering), `just_audio_background`
- **Context Engine:** `sensors_plus`, `geolocator`, `geocoding`, Open-Meteo API
- **Data Sources:** Radio-Browser API, Piped/Invidious API, Local Storage.

## 🤖 Geliştirme
```bash
flutter clean
flutter pub get
flutter run | grep "flutter"
```

Lütfen `docs/INSTRUCTIONS.md` , `docs/INSTRUCTIONS.md`, `docs/SPEC.md`, `AURA_ARCHITECTURE_SPEC.md` ve `docs/CHANGELOG.md`  dosylarını okuyarak geliştirmeye devam edin.