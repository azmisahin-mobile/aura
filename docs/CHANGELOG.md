# Changelog

## [1.8.0] - Aura Neural Matrix & Dead-Air Shield (2026-03-19)
### Added
- **Aura Neural Matrix (Local AI):** Cihaz içinde %100 offline çalışan "Reinforcement Learning" (Pekiştirmeli Öğrenme) katmanı eklendi. Kullanıcının dinleme süresine göre (+Puan) ve geçme/beğenmeme (Dislike) hızına göre (-Puan) türleri öğrenen beyin aktif edildi.
- **Blacklist (Karaliste) Filtresi:** Puanı kritik eşiğin (40 puan) altına düşen müzik türleri AURA'nın evreninden tamamen silinir; ne "Favori" ne de "Keşif" olarak kullanıcıya bir daha sunulmaz.
- **Dead-Air Shield (Sessizlik Kalkanı):** Yayıncı taraflı sessiz kalan veya sonsuz yükleme döngüsüne giren radyolar için 8 saniyelik "Anti-Sessizlik" zamanlayıcısı eklendi. Ses gelmiyorsa AURA sessizliği bozar ve otomatik atlar.
- **Fast-Track GPS:** Uygulama açılışında uyduları beklemek yerine "Son Bilinen Konum" (Last Known) üzerinden 0. milisaniyede ülke tespiti yapılır.

### Fixed
- **Logic Loop Fix:** Kullanıcının nefret ettiği türlerin "Keşif Modu" adı altında tekrar sunulması (Aptal Merak hatası) karaliste sistemiyle giderildi.
- **Auto-Heal V2:** Sadece bağlantı hatalarında değil, veri akışının durduğu (Source error) her senaryoda oto-atlama stabilize edildi.

## [1.7.2] - Fast-Track GPS & Auto-Heal (2026-03-19)
### Added
- **Fast-Track GPS:** Uygulama ilk açıldığında GPS uydularını beklemek yerine cihazın son bilinen (Last Known) lokasyonunu kullanarak 0. saniyede ülkeyi tespit eden algoritma eklendi.
- **ISO Country Code (Kültürel Keskinlik):** Radio-Browser'ın arama API'si `countrycode` parametresine (Örn: TR, DE, US) geçirildi. Arama doğruluğu %100'e çıkarıldı.
- **Oto-İyileşme (Auto-Heal):** Kırık linkli veya çökmüş bir açık kaynak radyoya denk gelindiğinde sessiz kalmak yerine milisaniyeler içinde sıradaki radyoya atlayan sistem (`playbackEventStream` error handling) eklendi.

### Fixed
- Metadata spam'ı engellendi. Sadece radyo istasyonu gerçekten değiştiğinde terminale ve UI'a sinyal gidiyor (`distinct()` ve `url` check mekanizması).

## [1.7.1] - Hotfix: Audio Provider Signatures (2026-03-19)
### Fixed
- Kültürel lokasyon eklentisi sırasında `MasterAudioRepository` ve alt provider'larda oluşan metod imza (Syntax) hataları giderildi.
- YouTube (Piped/Invidious) motorlarına kültürel string bükücü eklendi.

## [1.7.0] - AURA Phase 3 (Intelligence & Stability)
### Added
- **Kültürel Lokasyon Zekası (Reverse Geocoding):** Kullanıcının GPS koordinatından bulunduğu ülkeyi anlayan ve o ülkeye özgü (Örn: Türkiye için Anatolian, Sufi, Pop) frekansları seçen motor eklendi.
- **Akıllı Buffer (Önbellekleme):** İnternet kopmalarına karşı sıradaki 10 ila 60 saniyelik ses verisini cihaz hafızasında tutan yapı `just_audio` üzerinden aktif edildi.
- **Playlist Bağlamı (Kilit Ekranı Desteği):** Bulunan frekanslar tek bir ses dosyası yerine bir oynatma listesi (`ConcatenatingAudioSource`) olarak cihaza yüklendi. Artık ekran kapalıyken (Lock Screen) kulaklık tuşuyla veya ekrandan müzik değiştirilebiliyor.

### Fixed
- **Sensör Çıldırması (Hysteresis):** Koşu veya yürüme anında anlık sensör sapmalarından dolayı durumun sürekli değişip ekranın titremesine neden olan hata, 5-frame okuma filtresi (Hysteresis) ile düzeltildi.
- **API Tag Eşleşmesi:** Ülkelere göre atanan spesifik etiketler, Radio-Browser altyapısında karşılığı olan geniş etiketlerle güncellendi.

## [1.6.0] - Phase 2 (Fluid UI & Weather)
### Added
- Fluid Mesh Gradient (Sıvı Arka Plan).
- Hava Durumu (Weather Context) bazlı müzik seçimi ve renk değişimi.
- Haptic Feedback eklendi.
- Kilit ekranında çalabilmesi için Foreground Service entegre edildi.

## [1.6.0] - 2026-03-19
### Added
- **Fluid Mesh Gradient (Sıvı Arka Plan):** AURA'nın durumu (Enerji, Odak, Chill) ve Hava Durumuna (Güneşli, Yağmurlu) göre renk değiştiren, sıvı gibi akan organik ve nefes alan görsel arayüz tasarımı eklendi.
- **Dinamik Hız Optimizasyonu:** Müzik "Energy" moduna geçtiğinde arka plandaki renklerin dalgalanma hızı matematiksel olarak artırıldı.

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
