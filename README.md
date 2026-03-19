# 🌌 AURA: Sound of Your Rhythm

> "Don't choose your music. Let your life choose the sound."

**AURA**, seçim yorgunluğuna ve abonelik dayatmalarına karşı geliştirilmiş bir "Görünmez Audio Engine"dir. Kullanıcıyı bir arayüze hapsetmek yerine; sensörler, GPS, **Hava Durumu** ve zaman verileriyle kullanıcının o anki "modunu" anlar ve en uygun açık kaynaklı ses akışını başlatır.

### 🎧 Neden AURA?
- **Sıfır Karar (Zero-UI):** Play'e bas ve unut. Buton yok, arama yok. Ekrana bakmana bile gerek yok, AURA seninle **titreşimlerle (Haptic)** iletişim kurar.
- **Çevresel Farkındalık:** Yağmur yağıyorsa Jazz, güneşliyse Upbeat, gece yarısıysa Dark Ambient çalar.
- **Sıfır Abonelik:** Sadece özgür ve açık kaynaklar (Radio Browser, Piped, Invidious).
- **Ölümsüz Motor:** Ekranı kilitle veya telefonu cebine koy. AURA arka planda sensörleri okumaya ve hızına göre ritmi değiştirmeye devam eder.

### 🛠️ Teknoloji Yığını
- **Core:** Flutter (Dart), Clean Architecture (DDD)
- **Audio & OS:** `just_audio`, `just_audio_background` (Foreground Service)
- **Context Engine:** `sensors_plus`, `geolocator`, Open-Meteo API
- **Data Sources:** Radio-Browser API, Piped/Invidious API (YouTube Audio), Local Storage.

## 🤖 Geliştirme

Lütfen `AI_INSTRUCTIONS.md` ve `SPEC.MD` dosylarını okuyarak geliştirmeye devam edin.