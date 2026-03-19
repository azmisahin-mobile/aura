# Changelog

## [1.5.0] - 2026-03-19
### Added
- **Çevresel Zeka (Weather Context):** GPS üzerinden Open-Meteo API'ye bağlanılarak anlık hava durumu (Yağmur, Kar, Güneş, Bulutlu) algılama sistemi eklendi.
- **Hava Durumu Müzik Bükücü:** Yağmurlu havada Jazz, Güneşli havada Upbeat çalmasını sağlayan akıllı etiket algoritması (Smart Tags) eklendi.
- **Haptic Feedback (Dokunsal İletişim):** Kullanıcı etkileşimleri (Kaydırma) ve mod değişimleri için cihaza Zero-UI titreşim bildirimleri eklendi.
- **Ölümsüzlük (Background Audio Service):** Uygulama arka plana atıldığında veya ekran kilitlendiğinde müziğin ve GPS sensörlerinin kapanmasını engelleyen Foreground Service eklendi. Kilit ekranı medya paneli entegre edildi.

## [1.3.0] - 2026-03-19
### Added
- **Api Resolver Engine:** API'lere paralel (Race condition) istek atarak en hızlı (Fastest) sunucuyu bulan ve önbelleğe (Cache) alan ağ zekası eklendi.
- **Auto-Discovery:** Radio Browser node'ları artık DNS üzerinden dinamik keşfediliyor.
- **Yenilmez Fallback:** Piped API'nin yanına Invidious API eklendi.

## [1.2.1] - 2026-03-19
### Added
- **Çoklu Radio Browser node desteği**: 10 farklı node ile bağlantı dayanıklılığı arttı.
- **Çoklu Piped API instance desteği**: 6 farklı instance ile yedeklilik sağlandı.
- **Stream önbellekleme**: Son başarılı stream'ler hafızada tutulur, tüm çevrimiçi kaynaklar başarısız olursa önbellek kullanılır.
- **Sensör okumalarında moving average**: Daha kararlı durum geçişleri.
- **GPS pil optimizasyonu**: Daha düşük çözünürlük ve mesafe filtresi ile pil tüketimi azaltıldı.
- **Hata yönetimi**: Her node/instance başarısızlığı loglanır ve sonrakine geçilir.

### Fixed
- `debugPrint` kullanılan dosyalara eksik import'lar eklendi (`package:flutter/foundation.dart`).

## [1.2.0] - 2026-03-18
### Added
- **Zaman Bağlamı (Circadian Rhythm):** Sabah, öğle ve gece için müzik algoritmaları ayrıştırıldı.
- **Hafıza (Learning Engine):** Kullanıcı sola kaydırdığında (dislike), Aura artık bunu öğreniyor ve bir sonraki sefer o tarzı açmıyor.
- **Ölümsüzlük (Fallback Chain):** Radio-Browser çökerse Piped API (Açık Kaynak YouTube) devreye giriyor.
- **Çevrimdışı Mod:** İnternet tamamen kesilirse cihaz içine gömülü (Ambient) frekans devreye giriyor, AURA asla susmuyor.
- **Psikolojik Zero-UI:** Kaydırma (Swipe) ve Uzun Basma eylemleri eklendi. Butonsuz tasarım mükemmelleştirildi.


## [1.1.0] - 2026-03-18
### Added
- **Mimari:** Clean Architecture (DDD) standartlarına geçildi.
- **Context Engine:** Sadece ivmeölçer değil, GPS ile hız entegrasyonu sağlandı (Hız > 20 km/h ise Energy modu).
- **Smart Fading:** Müzik geçişlerinde sinematik ses kısılıp-açılma (fade in/out) özelliği eklendi.
- **Zero-UI:** Tüm düğmeler kaldırıldı. Dokunmatik alan genişletildi ve müzik çalarken "Nefes Alan (Pulsing)" logo animasyonu eklendi.

## [1.0.2] - 2026-03-17
### Fixed
- CI/CD release izinleri düzeltildi.

## [1.0.0] - İlk Sürüm
- İvmeölçer tabanlı temel Radio-Browser entegrasyonu.
