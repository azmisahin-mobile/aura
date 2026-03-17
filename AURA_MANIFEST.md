# AURA Project Handover & Vision Document

## 1. Projenin Amacı (The Philosophy)
AURA, kullanıcının müzik seçme zorunluluğunu ortadan kaldıran, sensör tabanlı bir "akış" uygulamasıdır. Spotify/YouTube gibi platformların "karar yorgunluğu" yaratan arayüzlerine karşı bir dijital minimalist başkaldırıdır.

## 2. Mevcut Durum (Current Sprint)
- **Core Engine:** Accelerometer (ivmeölçer) verisiyle kullanıcının hareket durumu (Focus, Chill, Energy) tespit ediliyor.
- **Audio Logic:** Radio-Browser API kullanılarak, belirlenen moda göre dünya üzerindeki açık radyolardan stream çekiliyor.
- **UI:** Sıfır-arayüz (Zero-UI) felsefesine uygun, mod değişimine göre renk değiştiren minimalist bir yapı.

## 3. Teknik Mimari
- **State Management:** Flutter BLoC (Cubit)
- **Audio:** Just_Audio (Cross-platform streaming)
- **Sensors:** Sensors_Plus (Real-time stream mapping)

## 4. Gelecek Planı (Next Steps)
- **Piped API Entegrasyonu:** YouTube üzerindeki müzikleri sadece audio stream olarak çekmek.
- **GPS Speed Context:** İvmeölçere ek olarak hız verisiyle (araçta/yürüyüşte/koşuda) daha hassas mod tahmini.
- **Local AI Generator:** API'lerin kesildiği veya modun uymadığı anlarda on-device minik modellerle (Magenta vb.) ritim üretimi.

---
*Bu proje azmisahin-mobile organizasyonu altında açık kaynak felsefesiyle geliştirilmektedir.*
