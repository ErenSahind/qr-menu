# QR Menu Project Architecture

## 1. Sorularınızın Cevapları ve Mantık

### A. Masa Sayısına Göre QR Oluşturma ve URL Güvenliği
**Soru:** Table URL'de olursa müşteriler editleyebilir, bu sıkıntı olur mu?
**Cevap:** Evet, tahmin edilebilir ID'ler risklidir.
**Çözüm:** Masa numaralarını URL'de "ID" olarak değil, **NanoID** benzeri kısa ama tahmin edilemez stringler (7-10 karakter) olarak tutacağız.
- **Kötü:** `domain.com/tr/m/cafe-adi/1`
- **İyi:** `domain.com/tr/m/cafe-adi/x7Ka2bP9`
Bu sayede URL hem kısa kalır hem de güvenli olur.

### B. Tek QR / Masa Numarası İstemeyenler
**Soru:** User masa numarası kullanmak istemezse?
**Cevap:** Sistemde her restoranın en az 1 "Default" masası olur.
- Eğer kullanıcı "Masa kullanmıyorum" derse, arka planda 1 adet masa oluştururuz ve adını "Genel" koyarız.
- QR kod bu "Genel" masaya yönlendirir.
- Yani mantık değişmez: `Table Count >= 1`.

### C. Onboarding (Kurulum) Süreci
User register olduktan sonra dashboard'a erişmeden önce zorunlu bir `/setup` sayfasına yönlendirilecek. Burada:
1. Şirket Adı
2. Slug (URL'de görünecek kısım: `qr-menu.com/m/starbucks` gibi)
3. Masa Sayısı
bilgileri alınacak. Bu bilgiler olmadan dashboard açılamaz.

---

## 2. Dosya Yapısı (Next.js App Router + i18n)

Bu yapı `src/app/[locale]` altında kurgulanmıştır. Tüm rotalar dil parametresi (`tr`, `en` vb.) ile başlar.

### `[locale]/(auth)` Grubu
Login ve Register işlemleri için.
- `src/app/[locale]/(auth)/login/page.tsx`
- `src/app/[locale]/(auth)/register/page.tsx`

### `[locale]/setup` (Onboarding)
Kayıt sonrası ilk yönlendirilecek yer.
- `src/app/[locale]/setup/page.tsx`: Şirket adı ve masa sayısı formu.

### `[locale]/(dashboard)` Grubu
Restoran sahibinin yönetim paneli.
- `src/app/[locale]/(dashboard)/layout.tsx`: Setup kontrolü burada yapılır.
- `src/app/[locale]/(dashboard)/dashboard/page.tsx`: Genel bakış.
- `src/app/[locale]/(dashboard)/qr-management/page.tsx`: QR kodlarını listeleme.

### `[locale]/(admin)` Grubu
Sizin (Super Admin) tüm userları göreceğiniz yer.
- `src/app/[locale]/(admin)/admin-panel/page.tsx`

### `[locale]/(public)` Grubu
Müşterilerin göreceği menü ekranı.
- `src/app/[locale]/(public)/m/[slug]/[tableId]/page.tsx`:
  - `slug`: Restoranı bulmak için.
  - `tableId`: Hangi masada oturulduğunu anlamak için (NanoID - 7-10 karakter).

---

## 3. Veritabanı Modeli (Özet)

**User**
- id, email, password, role (admin/user), plan (free/premium/ultimate)

**Restaurant**
- id, userId, name, slug, logo

**Table**
- id (UUID - URL'de bu kullanılacak), restaurantId, name (Masa 1, Bahçe 2 vb.), qrCodeUrl
