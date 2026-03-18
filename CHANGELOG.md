# Changelog

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

## [1.2.0] - AURA'nın Zihni ve Ölümsüzlük Güncellemesi
### Added
- **Zaman Bağlamı (Circadian Rhythm):** Sabah, öğle ve gece için müzik algoritmaları ayrıştırıldı.
- **Hafıza (Learning Engine):** Kullanıcı sola kaydırdığında (dislike), Aura artık bunu öğreniyor ve bir sonraki sefer o tarzı açmıyor.
- **Ölümsüzlük (Fallback Chain):** Radio-Browser çökerse Piped API (Açık Kaynak YouTube) devreye giriyor.
- **Çevrimdışı Mod:** İnternet tamamen kesilirse cihaz içine gömülü (Ambient) frekans devreye giriyor, AURA asla susmuyor.
- **Psikolojik Zero-UI:** Kaydırma (Swipe) ve Uzun Basma eylemleri eklendi. Butonsuz tasarım mükemmelleştirildi.