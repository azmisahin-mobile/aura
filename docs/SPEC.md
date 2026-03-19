# 🤖 AURA - AI & Human Collaboration Spec

## 1. Proje Felsefesi (The Vision)
AURA; müzik seçme yorgunluğunu bitiren, Zero-UI (Arayüzsüz) bir dijital başkaldırıdır. Kullanıcının cihaz sensörleri (İvme, GPS) okunarak biyolojik bağlamı (Focus, Chill, Energy) tespit edilir ve uygun ses yayını arka planda otomatik başlatılır.

## 2. Çalışma Prensibimiz (Human + AI)
- **Human (Ürün Sahibi):** Sadece fikirlere, vizyona ve kullanıcı deneyimine odaklanır. Kodu alır, derler ve çalıştırır.
- **AI (Senior Mimar):** Hata ayıklar, mimariyi DDD (Clean Architecture) standartlarında kurar, commit mesajlarını hazırlar ve performansı optimize eder.

## 3. Mimari Kurallar
- **Katmanlar:** `domain` (Entity/Interfaces), `data` (API/Sensors), `logic` (BLoC/Cubit), `ui` (Zero-UI screens).
- **Kısıtlamalar:** Ağır UI kütüphaneleri yasaktır. Ekran sadece durum bildirir, buton içermez.
- **State Yönetimi:** BLoC / Cubit.

## 4. Gelecek Yol Haritası (Roadmap)
- [ ] **Piped API Fallback:** Radyo yayınları koptuğunda YouTube Müzik altyapısını arkaplanda çalan bir Provider yazılacak.
- [ ] **Local AI Ambient:** İnternet hiç yoksa cihaz içinde basit bir sinüs dalgası/ritim üreteci ile ses sağlanacak.