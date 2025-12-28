-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. ENUMS & CONSTANTS
create type public.user_role as enum ('admin', 'owner', 'staff');
create type public.subscription_plan as enum ('free', 'premium', 'ultimate', 'enterprise');
create type public.staff_role as enum ('manager', 'waiter', 'kitchen');
create type public.order_status as enum ('pending', 'preparing', 'served', 'completed', 'cancelled');
create type public.subscription_status as enum ('inactive', 'trialing', 'active', 'past_due', 'canceled');

-- 2. PLAN FEATURES (Centralized Limits)
create table public.plan_features (
  plan public.subscription_plan primary key,
  max_branches int not null,
  max_products int, -- null means unlimited
  max_categories int, -- null means unlimited
  max_staff int, -- Kullanıcı hesabı (owner) başına toplam staff limiti
  allow_images boolean default true,
  allow_ordering boolean default false
);

-- Enable RLS
alter table public.plan_features enable row level security;
create policy "Everyone can view plan features" on plan_features for select using (true);

-- Populate Defaults
insert into public.plan_features (plan, max_branches, max_products, max_categories, max_staff, allow_images, allow_ordering) values
('free', 1, 20, 5, 5, false, false),
('premium', 1, null, null, null, true, false),
('ultimate', 3, null, null, null, true, true), 
('enterprise', 5, null, null, null, true, true);

-- 2.1 TRIGGER: Check Image Permission (Feature Gating)
-- Planın resim yükleme izni yoksa DB seviyesinde engelle.
create or replace function public.check_image_permission()
returns trigger as $$
declare
  allowed boolean;
  owner_uuid uuid;
  image_val text;
  target_branch_id uuid;
begin
  -- Optimization: Skip if update and image value hasn't changed
  if TG_OP = 'UPDATE' then
    if TG_TABLE_NAME = 'branches' and new.cover_image_url is not distinct from old.cover_image_url then
      return new;
    elsif TG_TABLE_NAME = 'profiles' and new.logo_url is not distinct from old.logo_url then
      return new;
    elsif (TG_TABLE_NAME = 'categories' or TG_TABLE_NAME = 'products') and new.image_url is not distinct from old.image_url then
      return new;
    end if;
  end if;

  -- Tabloya göre hangi kolona bakılacağını ve owner'ı belirle
  if TG_TABLE_NAME = 'branches' then
    image_val := new.cover_image_url;
    owner_uuid := new.owner_id;
  elsif TG_TABLE_NAME = 'profiles' then
    image_val := new.logo_url;
    -- 1. Check: Only owner can upload logo
    if new.role <> 'owner' then
      raise exception 'ONLY_OWNER_CAN_UPLOAD_LOGO';
    end if;
    owner_uuid := new.id;
  else
    image_val := new.image_url;
    target_branch_id := new.branch_id;
    select owner_id into owner_uuid from public.branches where id = target_branch_id;
  end if;

  -- Güvenlik: Owner bulunamazsa işlem yapma (Data integrity)
  if owner_uuid is null then
    raise exception 'OWNER_NOT_FOUND';
  end if;

  -- Resim yoksa (null) izin ver
  if image_val is null then
    return new;
  end if;

  -- Owner'ın plan özelliklerini kontrol et
  select pf.allow_images
  into allowed
  from public.profiles p
  join public.plan_features pf on pf.plan = p.subscription_plan
  where p.id = owner_uuid;

  if allowed is null then
    raise exception 'PLAN_NOT_FOUND_FOR_OWNER';
  end if;

  if allowed is not true then
    raise exception 'IMAGE_UPLOAD_NOT_ALLOWED_FOR_PLAN';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- 3. PROFILES (Extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text,
  company_name text, -- Şirket/İşletme Adı
  phone text, -- İletişim numarası
  phone_verified boolean default false, -- Telefon onayı
  address text, -- Adres
  city text, -- Şehir
  country text, -- Ülke
  logo_url text, -- Şirket Logosu (Tüm şubelerde bu görünür - Anti-Reseller)
  is_onboarded boolean default false, -- Kurulum tamamlandı mı?
  role public.user_role default 'owner', -- ENUM: 'admin', 'owner', 'staff'
  subscription_plan public.subscription_plan default 'free', -- ENUM: 'free', 'premium', 'ultimate'
  subscription_status public.subscription_status default 'inactive',
  subscription_started_at timestamp with time zone,
  subscription_ends_at timestamp with time zone,
  purchased_branch_limit int default 0, -- Paket harici satın alınan ek şube hakkı
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for profiles
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id );

-- 3.1 TRIGGER: Protect Sensitive Profile Fields
-- Kullanıcıların kendi abonelik bilgilerini veya rollerini değiştirmesini engeller.
-- NOT: RLS politikası (Users can update own profile) güncellemeye izin verse bile,
-- bu trigger belirli alanların (plan, rol, vb.) değiştirilmesini bilinçli olarak engeller.
create or replace function public.protect_profile_fields()
returns trigger as $$
begin
  -- Sadece normal kullanıcı oturumlarında çalışır (service_role ve postgres hariç)
  -- current_setting('role') kontrolü daha güvenlidir.
  if current_setting('role', true) not in ('service_role', 'postgres') then
    if (new.subscription_plan is distinct from old.subscription_plan) or
       (new.subscription_status is distinct from old.subscription_status) or
       (new.subscription_started_at is distinct from old.subscription_started_at) or
       (new.subscription_ends_at is distinct from old.subscription_ends_at) or
       (new.purchased_branch_limit is distinct from old.purchased_branch_limit) or
       (new.role is distinct from old.role) then
       
       raise exception 'UNAUTHORIZED_FIELD_UPDATE';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_profile_update_protect
  before update on public.profiles
  for each row execute procedure public.protect_profile_fields();

-- Trigger: Check Image Permission for Profiles (Logo)
create trigger check_profile_logo
  before insert or update on public.profiles
  for each row execute procedure public.check_image_permission();

-- 3.2 SYSTEM SETTINGS (Admin Only)
-- Fiyatları ve sistem ayarlarını yönetmek için tek satırlık tablo.
-- NOT: handle_new_user trigger'ından önce tanımlanmalı.
create table public.system_settings (
  id int primary key default 1, -- Tek satır olacak (Singleton)
  -- Yeni Üye Ayarları (Kampanyalar için buradan değiştirilebilir)
  default_signup_plan public.subscription_plan default 'free',
  default_trial_days int default 14, -- 0 ise süresiz
  -- Paketlerin Yıllık Taban Fiyatları (Enterprise güncellendi)
  plan_prices jsonb default '{"free": 0, "premium": 4000, "ultimate": 6000, "enterprise": 9000}', -- SADECE UI İÇİN
  -- Paket Başına Ek Şube Fiyatları (Her paketin ek şube maliyeti farklı olabilir)
  extra_branch_prices jsonb default '{"free": 0, "premium": 2000, "ultimate": 1500, "enterprise": 1400}',
  currency text default 'TRY',
  maintenance_mode boolean default false, -- Bakım modu (Tüm sistemi kapatmak için)
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_by uuid references public.profiles(id),
  constraint single_row_check check (id = 1)
);

-- Enable RLS
alter table public.system_settings enable row level security;

-- Sadece ADMIN güncelleyebilir ve görebilir (Public erişim view üzerinden)
create policy "Admins can view system settings."
  on system_settings for select
  using ( 
    exists ( select 1 from public.profiles where id = auth.uid() and role = 'admin' )
  );

-- Sadece ADMIN güncelleyebilir
create policy "Admins can update system settings."
  on system_settings for update
  using ( 
    exists ( select 1 from public.profiles where id = auth.uid() and role = 'admin' )
  );

-- İlk ayarları ekle (Eğer yoksa)
insert into public.system_settings (id) values (1) on conflict do nothing;

-- 3.3 VIEW: Public Pricing Settings (Hides sensitive system settings)
create view public.pricing_settings as
select plan_prices, extra_branch_prices, currency
from public.system_settings;

grant select on public.pricing_settings to anon, authenticated;

-- 4. BRANCHES (Stores restaurant branches)
create table public.branches (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  slug text unique not null, -- For URL: qr-menu.com/qr/[slug]
  address text,
  phone text,
  -- logo_url text, -- KALDIRILDI: Logo artık profile (şirket) seviyesinde.
  cover_image_url text,
  social_media jsonb, -- Örn: {"instagram": "...", "website": "..."}
  working_hours jsonb, -- Örn: {"monday": {"open": "09:00", "close": "22:00"}}
  currency text default 'TRY', -- 'TRY', 'USD', 'EUR'
  is_ordering_enabled boolean default false,
  -- Location & Security
  latitude decimal(10,8),
  longitude decimal(11,8),
  max_distance int default 500, -- Metre (Sipariş için maksimum mesafe)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for branches
alter table public.branches enable row level security;

create policy "Branches are viewable by everyone."
  on branches for select
  using ( true );

create policy "Users can insert their own branches."
  on branches for insert
  with check ( auth.uid() = owner_id );

create policy "Users can delete their own branches."
  on branches for delete
  using ( auth.uid() = owner_id );

-- Trigger: Check Image Permission for Branches
create trigger check_branch_image
  before insert or update on public.branches
  for each row execute procedure public.check_image_permission();

-- 5. BRANCH STAFF (Waiters, Managers)
create table public.branch_staff (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role public.staff_role default 'waiter',
  is_active boolean default true, -- Personel aktif mi? (İşten ayrılırsa false yapılır)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, user_id)
);

-- Enable RLS for branch_staff
alter table public.branch_staff enable row level security;

create policy "Branch owners can manage their staff."
  on branch_staff for all
  using ( exists ( select 1 from public.branches where branches.id = branch_staff.branch_id and branches.owner_id = auth.uid() ) )
  with check ( exists ( select 1 from public.branches where branches.id = branch_staff.branch_id and branches.owner_id = auth.uid() ) );

create policy "Staff can view their own records."
  on branch_staff for select
  using ( auth.uid() = user_id );

-- Moved here because it references branch_staff which is created above
create policy "Branch owners and managers can update branches."
  on branches for update
  using ( 
    auth.uid() = owner_id 
    or 
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = branches.id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- 5.1 TRIGGER: Enforce Staff Limit
create or replace function public.check_staff_limit()
returns trigger as $$
declare
  staff_count int;
  max_allowed int;
  owner_uuid uuid;
  is_already_staff boolean;
  target_branch_id uuid;
  target_user_id uuid;
  target_record_id uuid;
begin
  -- 2. Check: Handle UPDATE
  if TG_OP = 'UPDATE' then
    -- Guard Logic: Sadece "Pasif -> Aktif" geçişlerinde limit kontrolü yapılmalı.
    -- Eğer personel zaten aktifse (old.is_active = true) veya yeni durum pasifse (new.is_active = false),
    -- limit kontrolüne gerek yoktur.
    if old.is_active = true or new.is_active = false then
      return new;
    end if;
  end if;

  target_branch_id := new.branch_id;
  target_user_id := new.user_id;
  target_record_id := new.id;

  -- Eklenen personelin hangi şubeye ait olduğunu ve o şubenin sahibini bul
  select owner_id into owner_uuid
  from public.branches
  where id = target_branch_id;

  if owner_uuid is null then
    raise exception 'BRANCH_NOT_FOUND';
  end if;

  -- Concurrency Fix: Global Staff Pool Race Condition
  perform pg_advisory_xact_lock(hashtext(owner_uuid::text));

  -- Plan limitini çek
  select pf.max_staff into max_allowed
  from public.profiles p
  join public.plan_features pf on pf.plan = p.subscription_plan
  where p.id = owner_uuid;

  -- Eğer limit yoksa (NULL) direkt çık
  if max_allowed is null then
    return new;
  end if;

  -- Bu kullanıcı (user_id) zaten bu patronun (owner_id) herhangi bir şubesinde AKTİF olarak çalışıyor mu?
  -- Eğer çalışıyorsa, limit kotasından düşülmüştür (Global Pool), tekrar saymaya gerek yok.
  select exists (
    select 1
    from public.branch_staff bs
    join public.branches b on b.id = bs.branch_id
    where b.owner_id = owner_uuid
      and bs.user_id = target_user_id
      and bs.is_active = true
      and bs.id <> target_record_id -- Update durumunda kendi kaydını hariç tut
  ) into is_already_staff;

  if is_already_staff then
    return new;
  end if;

  -- Kullanıcı yeni ise, mevcut BENZERSİZ (Unique) personel sayısını kontrol et
  select count(distinct bs.user_id) into staff_count
  from public.branch_staff bs
  join public.branches b on b.id = bs.branch_id
  where b.owner_id = owner_uuid
    and bs.is_active = true;

  if max_allowed is not null and staff_count >= max_allowed then
    raise exception 'STAFF_LIMIT_EXCEEDED';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger enforce_staff_limit
  before insert or update on public.branch_staff
  for each row execute procedure public.check_staff_limit();

-- 6. RESTAURANT TABLES (QR Codes for specific tables)
create table public.restaurant_tables (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name text not null,
  qr_code text unique not null, -- NanoID (5 chars) for secure URL
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, name),
  unique(id, branch_id) -- Composite key for foreign key integrity in orders
);

-- Enable RLS for tables
alter table public.restaurant_tables enable row level security;

create policy "Tables are viewable by everyone."
  on restaurant_tables for select
  using ( true );

create policy "Branch owners and managers can manage tables."
  on restaurant_tables for all
  using ( 
    exists ( select 1 from public.branches where branches.id = restaurant_tables.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = restaurant_tables.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- 7. QR SCANS (Analytics)
create table public.qr_scans (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid, -- Masa QR'ı ise dolu, Şube QR'ı ise boş olabilir
  customer_session_id uuid, -- Kimin taradığını takip etmek için (Session Timeout)
  scanned_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Veri bütünlüğü: Eğer masa ID varsa, o masa mutlaka o şubeye ait olmalı
  foreign key (table_id, branch_id) references public.restaurant_tables(id, branch_id) on delete set null
);

-- Enable RLS for qr_scans
alter table public.qr_scans enable row level security;

create policy "Anyone can insert qr scans."
  on qr_scans for insert
  with check ( true );

create policy "Branch owners and staff can view scans."
  on qr_scans for select
  using ( 
    exists ( select 1 from public.branches where branches.id = qr_scans.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = qr_scans.branch_id and branch_staff.user_id = auth.uid() and branch_staff.is_active = true )
  );

-- 8. CATEGORIES (Menu categories)
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name jsonb not null, -- Örn: {"tr": "İçecekler", "en": "Drinks"}
  image_url text,
  sort_order int default 0,
  is_active boolean default true, -- Menüde görünür mü?
  type text default 'standard' check (type in ('standard', 'campaign')), -- 'campaign': Özel tasarım/öne çıkarılmış kategori
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint check_name_valid check (jsonb_typeof(name) = 'object' and name <> '{}'::jsonb)
);

-- Trigger: Check Image Permission for Categories
create trigger check_category_image
  before insert or update on public.categories
  for each row execute procedure public.check_image_permission();

-- Enable RLS for categories
alter table public.categories enable row level security;

create policy "Categories are viewable by everyone."
  on categories for select
  using ( true );

create policy "Branch owners and managers can manage categories."
  on categories for all
  using ( 
    exists ( select 1 from public.branches where branches.id = categories.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = categories.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- 9. PRODUCTS (Menu items)
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete cascade not null,
  name jsonb not null, -- Örn: {"tr": "Mercimek Çorbası", "en": "Lentil Soup"}
  description jsonb, -- Örn: {"tr": "Sıcak çorba", "en": "Hot soup"}
  price decimal(10,2) not null,
  image_url text,
  allergens text[] default '{}', -- Örn: ['gluten', 'dairy']
  ingredients jsonb, -- Örn: {"tr": "Domates, Biber, Soğan", "en": "Tomato, Pepper, Onion"}
  calories int,
  is_available boolean default true, -- Stok durumu (Var/Yok)
  is_active boolean default true, -- Menüde görünür mü? (Silmeden gizlemek için)
  sort_order int default 0, -- Menü mühendisliği için manuel sıralama
  badges text[] default '{}', -- Örn: ['chef_choice', 'bestseller', 'vegan', 'new']
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Trigger: Check Image Permission for Products
create trigger check_product_image
  before insert or update on public.products
  for each row execute procedure public.check_image_permission();

-- Enable RLS for products
alter table public.products enable row level security;

create policy "Products are viewable by everyone."
  on products for select
  using ( true );

create policy "Branch owners and managers can manage products."
  on products for all
  using ( 
    exists ( select 1 from public.branches where branches.id = products.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = products.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- 10. TRIGGER: Handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
declare
  def_plan public.subscription_plan;
  def_days int;
begin
  -- Sistem ayarlarından varsayılan planı ve süreyi çek
  select default_signup_plan, default_trial_days 
  into def_plan, def_days
  from public.system_settings
  where id = 1
  limit 1;

  if def_plan is null then
    def_plan := 'free';
    def_days := 0;
  end if;

  insert into public.profiles (
    id, 
    full_name,
    subscription_plan,
    subscription_ends_at
  )
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name',
    def_plan, -- Ayarlardan gelen plan (Örn: 'premium')
    case 
      when def_days > 0 then (now() + (def_days || ' days')::interval)
      else null -- Süresiz (Free gibi)
    end
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 11. ORDERS (Table sessions/orders)
-- GÜVENLİK NOTU: customer_session_id public header'dan gelir. 
-- Production ortamında bu ID'nin tahmin edilemez (UUID) olması ve tercihen imzalı/süreli olması önerilir.
create table public.orders (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid not null,
  customer_session_id uuid not null check (length(customer_session_id::text) = 36), -- Browser fingerprint or local storage ID for anonymous user tracking
  status public.order_status default 'pending',
  total_amount decimal(10,2) default 0,
  note text, -- Müşteri notu
  gps_lat decimal(10,8), -- Güvenlik: Sipariş anındaki konum
  gps_lng decimal(11,8),
  last_updated_by uuid references public.profiles(id), -- Siparişi en son güncelleyen personel/sahip
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  foreign key (table_id, branch_id) references public.restaurant_tables(id, branch_id) on delete cascade
);

-- 11.0 TRIGGER: Auto-update updated_at
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger on_orders_touch_updated
  before update on public.orders
  for each row execute procedure public.touch_updated_at();

-- 11.0.1 TRIGGER: Auto-set last_updated_by
create or replace function public.set_last_updated_by()
returns trigger as $$
begin
  new.last_updated_by := auth.uid();
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_orders_set_last_updated_by
  before update on public.orders
  for each row execute procedure public.set_last_updated_by();

-- 11.1 TRIGGER: Check Ordering Permission (Feature Gating)
-- Free planda sipariş özelliği kapalıysa DB seviyesinde engelle.
create or replace function public.check_ordering_permission()
returns trigger as $$
declare
  allowed boolean;
begin
  select pf.allow_ordering into allowed
  from public.branches b
  join public.profiles p on p.id = b.owner_id
  join public.plan_features pf on pf.plan = p.subscription_plan
  where b.id = new.branch_id;

  if allowed is not true then
    raise exception 'ORDERING_NOT_ALLOWED_FOR_PLAN';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger check_ordering_permission_trigger
  before insert on public.orders
  for each row execute procedure public.check_ordering_permission();

-- 11.2 TRIGGER: Rate Limit Orders (Anti-Spam)
create or replace function public.limit_order_frequency()
returns trigger as $$
declare
  target_session_id uuid;
  target_branch_id uuid;
begin
  target_session_id := new.customer_session_id;
  target_branch_id := new.branch_id;

  -- 4. Race Condition Fix: Advisory Lock
  -- Branch + Session bazlı kilitleme (Aynı şubeye aynı anda spam yapılmasın)
  perform pg_advisory_xact_lock(hashtext(target_session_id::text || '-' || target_branch_id::text));

  if exists (
    select 1 from public.orders
    where customer_session_id = target_session_id
    and branch_id = target_branch_id -- Sadece ilgili şube için kontrol et
    and created_at >= now() - interval '5 seconds'
  ) then
    raise exception 'ORDER_RATE_LIMIT';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger check_order_frequency
  before insert on public.orders
  for each row execute procedure public.limit_order_frequency();

-- 11.3 TRIGGER: Protect Immutable Order Fields
create or replace function public.protect_order_fields()
returns trigger as $$
begin
  if new.total_amount is distinct from old.total_amount
     or new.branch_id is distinct from old.branch_id
     or new.customer_session_id is distinct from old.customer_session_id then
    raise exception 'ORDER_IMMUTABLE_FIELDS';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger protect_orders_update
  before update on public.orders
  for each row execute procedure public.protect_order_fields();

-- Enable RLS for orders
alter table public.orders enable row level security;

-- Müşteriler sipariş oluşturabilir (Public)
create policy "Anyone can create orders."
  on orders for insert
  with check ( customer_session_id is not null );

-- Müşteriler SADECE kendi session ID'lerine ait siparişleri görebilir (Header: x-customer-session-id)
create policy "Customers can view their own orders."
  on orders for select
  using ( customer_session_id::text = (current_setting('request.headers', true)::json->>'x-customer-session-id') );

-- Restoran sahipleri VE Personel kendi şubelerindeki siparişleri görebilir
create policy "Branch owners and staff can view their branch orders."
  on orders for select
  using ( 
    exists ( select 1 from public.branches where branches.id = orders.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = orders.branch_id and branch_staff.user_id = auth.uid() and branch_staff.is_active = true )
  );

-- Restoran sahibi VE Manager siparişi güncelleyebilir
create policy "Branch owners and managers can update orders."
  on orders for update
  using ( 
    exists ( select 1 from public.branches where branches.id = orders.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = orders.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- Restoran sahibi VE Manager siparişi silebilir
create policy "Branch owners and managers can delete orders."
  on orders for delete
  using ( 
    exists ( select 1 from public.branches where branches.id = orders.branch_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.branch_staff where branch_staff.branch_id = orders.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );



-- 12. ORDER ITEMS (Products inside an order)
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete set null, -- Ürün silinse bile raporda kalsın
  quantity int default 1 check (quantity > 0),
  price decimal(10,2) not null check (price >= 0), -- O anki fiyatı kaydetmeliyiz (Fiyat değişirse geçmiş bozulmasın)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for order items
alter table public.order_items enable row level security;

create policy "Anyone can create order items."
  on order_items for insert
  with check (
    exists (
      select 1 from public.orders
      where orders.id = order_items.order_id
      and orders.customer_session_id::text = (current_setting('request.headers', true)::json->>'x-customer-session-id')
    )
  );

-- Müşteriler SADECE kendi siparişlerinin detaylarını görebilir
create policy "Customers can view their own order items."
  on order_items for select
  using ( exists ( select 1 from public.orders where orders.id = order_items.order_id and orders.customer_session_id::text = (current_setting('request.headers', true)::json->>'x-customer-session-id') ) );

-- Restoran sahipleri VE Personel şubelerindeki sipariş detaylarını görebilir
create policy "Branch owners and staff can view their branch order items."
  on order_items for select
  using ( 
    exists ( select 1 from public.orders join public.branches on branches.id = orders.branch_id where orders.id = order_items.order_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.orders join public.branch_staff on branch_staff.branch_id = orders.branch_id where orders.id = order_items.order_id and branch_staff.user_id = auth.uid() and branch_staff.is_active = true )
  );

-- Restoran sahibi VE Manager sipariş detaylarını güncelleyebilir (Miktar değişimi vs)
create policy "Branch owners and managers can update order items."
  on order_items for update
  using ( 
    exists ( select 1 from public.orders join public.branches on branches.id = orders.branch_id where orders.id = order_items.order_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.orders join public.branch_staff on branch_staff.branch_id = orders.branch_id where orders.id = order_items.order_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- Restoran sahibi VE Manager sipariş detayını silebilir (Ürün iptali)
create policy "Branch owners and managers can delete order items."
  on order_items for delete
  using ( 
    exists ( select 1 from public.orders join public.branches on branches.id = orders.branch_id where orders.id = order_items.order_id and branches.owner_id = auth.uid() )
    or
    exists ( select 1 from public.orders join public.branch_staff on branch_staff.branch_id = orders.branch_id where orders.id = order_items.order_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true )
  );

-- 12.1 TRIGGER: Protect Immutable Order Item Fields
create or replace function public.protect_order_item_price()
returns trigger as $$
begin
  if new.price is distinct from old.price then
    raise exception 'ORDER_ITEM_PRICE_IMMUTABLE';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger protect_order_item_update
  before update on public.order_items
  for each row execute procedure public.protect_order_item_price();

-- 13. INDEXES (Performance optimization)
create index idx_orders_customer_session on public.orders(customer_session_id);
create index idx_orders_branch_id on public.orders(branch_id);
create index idx_products_branch_id on public.products(branch_id);
create index idx_products_category_id on public.products(category_id);
-- 5. Missing Indexes
create index idx_branch_staff_owner on public.branch_staff(user_id, is_active);
create index idx_branches_owner on public.branches(owner_id);
create index idx_orders_branch_status on public.orders(branch_id, status);
create index idx_qr_scans_branch_date on public.qr_scans(branch_id, scanned_at);
create index idx_orders_session_time on public.orders(customer_session_id, created_at desc);

-- 14. TRIGGER: Auto-calculate Order Total
create or replace function public.update_order_total()
returns trigger as $$
declare
  target_order_id uuid;
begin
  if (TG_OP = 'DELETE') then
    target_order_id := old.order_id;
  else
    target_order_id := new.order_id;
  end if;

  update public.orders
  set total_amount = (
    select coalesce(sum(price * quantity), 0)
    from public.order_items
    where order_id = target_order_id
  )
  where id = target_order_id;
  
  return null;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_order_item_change
  after insert or update or delete on public.order_items
  for each row execute procedure public.update_order_total();

-- 15. ANALYTICS VIEW (Reporting)
create or replace view public.branch_analytics_daily
with (security_invoker = true)
as
with daily_orders as (
  select
    branch_id,
    date(created_at) as report_date,
    count(*) filter (where status = 'completed') as completed_orders,
    count(*) filter (where status = 'cancelled') as cancelled_orders,
    coalesce(sum(total_amount) filter (where status = 'completed'), 0) as total_revenue
  from public.orders
  group by branch_id, date(created_at)
),
daily_scans as (
  select
    branch_id,
    date(scanned_at) as report_date,
    count(*) as qr_scan_count
  from public.qr_scans
  group by branch_id, date(scanned_at)
)
select
  coalesce(o.branch_id, s.branch_id) as branch_id,
  coalesce(o.report_date, s.report_date) as report_date,
  coalesce(o.completed_orders, 0) as completed_orders,
  coalesce(o.cancelled_orders, 0) as cancelled_orders,
  coalesce(o.total_revenue, 0) as total_revenue,
  coalesce(s.qr_scan_count, 0) as qr_scan_count
from daily_orders o
full outer join daily_scans s on o.branch_id = s.branch_id and o.report_date = s.report_date;

-- Grant access to the view
grant select on public.branch_analytics_daily to authenticated;

-- 16. TABLE ANALYTICS VIEW (Table usage stats)
create or replace view public.table_analytics_daily
with (security_invoker = true)
as
select
  s.branch_id,
  t.name as table_name,
  s.table_id,
  date(s.scanned_at) as report_date,
  count(*) as scan_count
from public.qr_scans s
join public.restaurant_tables t on s.table_id = t.id
where s.table_id is not null
group by s.branch_id, s.table_id, t.name, date(s.scanned_at);

-- Grant access to the view
grant select on public.table_analytics_daily to authenticated;

-- 17. TRIGGER: Auto-calculate Sort Order
-- Yeni bir kategori veya ürün eklendiğinde, otomatik olarak listenin en sonuna ekler.
create or replace function public.handle_sort_order()
returns trigger as $$
declare
  max_order int;
  target_branch_id uuid;
  target_category_id uuid;
begin
  -- Eğer sort_order manuel olarak gönderildiyse (0'dan büyük), dokunma.
  -- Sadece default (0) geldiğinde otomatik hesapla.
  if new.sort_order > 0 then
    return new;
  end if;

  if TG_TABLE_NAME = 'categories' then
    target_branch_id := new.branch_id;
    perform pg_advisory_xact_lock(hashtext(target_branch_id::text));
    select coalesce(max(sort_order), 0) into max_order
    from public.categories
    where branch_id = target_branch_id;
  elsif TG_TABLE_NAME = 'products' then
    target_category_id := new.category_id;
    perform pg_advisory_xact_lock(hashtext(target_category_id::text));
    select coalesce(max(sort_order), 0) into max_order
    from public.products
    where category_id = target_category_id;
  end if;

  new.sort_order := max_order + 1;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_category_created
  before insert on public.categories
  for each row execute procedure public.handle_sort_order();

create trigger on_product_created
  before insert on public.products
  for each row execute procedure public.handle_sort_order();



-- 18. FUNCTION: Slugify (Türkçe karakter uyumlu URL oluşturucu)
-- Not: Sadece Türkçe ve İngilizce karakterleri destekler. İleride genişletilmesi gerekebilir.
create or replace function public.slugify(value text)
returns text as $$
begin
  -- 1. Küçük harfe çevir
  value := lower(value);
  -- 2. Türkçe karakterleri değiştir
  value := replace(value, 'ı', 'i');
  value := replace(value, 'ğ', 'g');
  value := replace(value, 'ü', 'u');
  value := replace(value, 'ş', 's');
  value := replace(value, 'ö', 'o');
  value := replace(value, 'ç', 'c');
  -- 3. Alfanümerik olmayan karakterleri sil (tire ve boşluk hariç)
  value := regexp_replace(value, '[^a-z0-9\s-]', '', 'g');
  -- 4. Boşlukları tire ile değiştir
  value := regexp_replace(value, '\s+', '-', 'g');
  -- 5. Baştaki ve sondaki tireleri temizle
  value := trim(both '-' from value);
  
  return value;
end;
$$ language plpgsql stable;

-- 19. TRIGGER: Auto-generate Branch Slug (Anti-Reseller URL)
-- Şube adı "Kadıköy" olsa bile, URL "sirket-adi-kadikoy" olur.
create or replace function public.handle_branch_slug()
returns trigger as $$
declare
  c_name text;
  base_slug text;
  final_slug text;
  counter int := 0;
  target_owner_id uuid;
  target_record_id uuid;
begin
  target_owner_id := new.owner_id;
  target_record_id := new.id;

  -- Şirket ismini çek (Yoksa isim soyisim kullan)
  select coalesce(company_name, full_name) into c_name
  from public.profiles
  where id = target_owner_id;

  -- Slug oluştur: sirket-adi + sube-adi
  -- Sadece INSERT işleminde veya İsim değiştiğinde çalışsın
  if (TG_OP = 'INSERT') or (new.name <> old.name) then
    base_slug := public.slugify(c_name || '-' || new.name);
    
    -- Concurrency Fix: Advisory Lock (Race condition önlemek için)
    perform pg_advisory_xact_lock(hashtext(base_slug));

    -- Unique kontrolü (Aynı isimde şube varsa sonuna -1, -2 ekle)
    final_slug := base_slug;
    while exists (select 1 from public.branches where slug = final_slug and id <> target_record_id) loop
      counter := counter + 1;
      final_slug := base_slug || '-' || counter;
    end loop;

    new.slug := final_slug;
  end if;
  
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_branch_create_slug
  before insert or update on public.branches
  for each row execute procedure public.handle_branch_slug();

-- 21. STORAGE POLICIES (Supabase Storage)
-- Not: 'storage' şeması Supabase tarafından yönetilir. Bu politika bucket oluşturulduktan sonra çalışır.
-- Amaç: Free kullanıcıların storage'ı doldurmasını engellemek.
-- Not: Storage quota enforcement application-side

create policy "Paid users can upload images"
on storage.objects for insert
with check (
  bucket_id = 'images'
  and auth.uid() in (
    select id from public.profiles p
    join public.plan_features pf on pf.plan = p.subscription_plan
    where pf.allow_images = true
  )
  -- 2. Path Security: images/{owner_id}/... (Biri başkasının klasörüne yazamaz)
  -- Frontend tarafında dosya yolu mutlaka 'images/' + user.id + '/' + fileName formatında olmalıdır.
  and (split_part(name, '/', 2))::uuid = auth.uid()
);

-- Not: Metadata kontrolü client-side manipüle edilebilir (Soft Protection / UX Barrier).
-- Gerçek güvenlik için: Bucket Max Size limiti ve Upload sonrası Edge Function validation şarttır.
-- WARNING: Multiple INSERT policies are AND-combined in Supabase.
create policy "Restrict file size to 200KB"
on storage.objects for insert
with check (
  (metadata->>'size')::int <= 204800 -- 200KB (200 * 1024 bytes)
  and (metadata->>'mimetype') like 'image/%'
);
