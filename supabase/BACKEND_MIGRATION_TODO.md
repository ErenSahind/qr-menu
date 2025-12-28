# Backend'e Taşınacak DB Trigger/Function/Business Logic Listesi

Bu dosya, Supabase'den çıkarılıp Next.js API/backend katmanına taşınması gereken (veya taşınan) tüm iş kurallarını ve trigger/fonksiyonları listeler.

## 1. Sipariş Kuralları (Ordering Logic)

- **check_ordering_enabled** (trigger & function)
  - Şube ordering açık mı?
  - Kullanıcı GPS/location kontrolü
  - QR scan timeout/session kontrolü
  - Abonelik süresi kontrolü
  - Hata mesajı yönetimi

## 2. Plan Limitleri

- **check_branch_limit** (trigger & function)
  - Kullanıcının açabileceği şube sayısı (plan + ek satın alma)
- **check_content_image_limit** (trigger & function)
  - Planına göre özel görsel yükleme hakkı
- **check_content_count_limit** (trigger & function)
  - Planına göre ürün/kategori adedi limiti
- **check_staff_limit** (trigger & function)
  - Şubeye eklenebilecek personel limiti
- **check_ordering_plan_limit** (trigger & function)
  - Sadece belirli planlarda ordering açılabilmesi

## 3. Notlar

- Bu kuralların tamamı API/Backend katmanında merkezi olarak uygulanmalı.
- Stripe, kampanya, A/B test, logging, analytics gibi advanced logicler için backend zorunlu.
- DB'de sadece veri bütünlüğü (constraint, foreign key, unique, vs.) ve deterministik otomasyonlar (ör: sıralama, toplam hesaplama) kalmalı.

---

**Bu dosya, migration/teknik borç takibi için tutulmaktadır.**
