# 🌌 AURA: Sound of Your Rhythm

> "Don't choose your music. Let your life choose the sound."

**AURA**, seçim yorgunluğuna ve abonelik dayatmalarına karşı geliştirilmiş bir "Görünmez Audio Engine"dir. Kullanıcıyı bir arayüze hapsetmek yerine; sensörler, GPS ve zaman verileriyle kullanıcının o anki "modunu" anlar ve en uygun açık kaynaklı ses akışını (Radyo, Yerel Müzik, AI Ambient) başlatır.

### 🎧 Neden AURA?
- **Sıfır Karar:** Play'e bas ve unut. Gerisini sensörler halleder.
- **Sıfır Abonelik:** Sadece özgür ve açık kaynaklar (Radio Browser, Librivox, Open Proxies).
- **Bağlam Duyarlı (Context-Aware):** Koşuyorsan ritim artar, duruyorsan dinginleşir.
- **Hafif ve Hızlı:** Flutter ile yazılmış, kaynak tüketmeyen minimalist yapı.

### 🛠️ Teknoloji Yığını
- **Core:** Flutter (Dart)
- **Audio:** `just_audio` (Multi-source streaming)
- **Context Engine:** `sensors_plus`, `geolocator`
- **Data Sources:** Radio-Browser API, Piped API (YouTube Audio), Local Storage.
