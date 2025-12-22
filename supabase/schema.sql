-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROFILES (Extends auth.users)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  full_name text,
  company_name text, -- Şirket/İşletme Adı
  phone text, -- İletişim numarası
  phone_verified boolean default false, -- Telefon onayı
  address text, -- Adres
  city text, -- Şehir
  country text, -- Ülke
  avatar_url text, -- Profil fotoğrafı
  is_onboarded boolean default false, -- Kurulum tamamlandı mı?
  role text default 'owner', -- 'admin' (sistem yöneticisi), 'owner' (mekan sahibi), 'staff' (personel)
  subscription_plan text default 'free', -- 'free', 'premium', 'ultimate'
  subscription_period text, -- 'monthly', 'yearly'
  subscription_start_date timestamp with time zone,
  subscription_end_date timestamp with time zone,
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
  using ( auth.uid() = id );

-- 2. BRANCHES (Stores restaurant branches)
create table public.branches (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  slug text unique not null, -- For URL: qr-menu.com/qr/[slug]
  address text,
  phone text,
  logo_url text,
  cover_image_url text,
  social_media jsonb, -- Örn: {"instagram": "...", "website": "..."}
  working_hours jsonb, -- Örn: {"monday": {"open": "09:00", "close": "22:00"}}
  currency text default 'TRY', -- 'TRY', 'USD', 'EUR'
  is_ordering_enabled boolean default false,
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

create policy "Users can update their own branches."
  on branches for update
  using ( auth.uid() = owner_id );

create policy "Users can delete their own branches."
  on branches for delete
  using ( auth.uid() = owner_id );

-- 2.5. BRANCH STAFF (Waiters, Managers)
create table public.branch_staff (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role text default 'waiter', -- 'manager', 'waiter'
  is_active boolean default true, -- Personel aktif mi? (İşten ayrılırsa false yapılır)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, user_id)
);

-- Enable RLS for branch_staff
alter table public.branch_staff enable row level security;

create policy "Branch owners can manage their staff."
  on branch_staff for all
  using ( exists ( select 1 from public.branches where branches.id = branch_staff.branch_id and branches.owner_id = auth.uid() ) );

create policy "Staff can view their own records."
  on branch_staff for select
  using ( auth.uid() = user_id );

-- 3. TABLES (QR Codes for specific tables)
create table public.tables (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name text not null,
  qr_code text unique not null, -- NanoID (5 chars) for secure URL
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, name),
  unique(id, branch_id) -- Composite key for foreign key integrity in orders
);

-- Enable RLS for tables
alter table public.tables enable row level security;

create policy "Tables are viewable by everyone."
  on tables for select
  using ( true );

create policy "Users can manage tables for their branches."
  on tables for all
  using ( exists ( select 1 from public.branches where branches.id = tables.branch_id and branches.owner_id = auth.uid() ) );

-- 3.5. QR SCANS (Analytics)
create table public.qr_scans (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid, -- Masa QR'ı ise dolu, Şube QR'ı ise boş olabilir
  scanned_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Veri bütünlüğü: Eğer masa ID varsa, o masa mutlaka o şubeye ait olmalı
  foreign key (table_id, branch_id) references public.tables(id, branch_id) on delete set null
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

-- 4. CATEGORIES (Menu categories)
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name jsonb not null, -- Örn: {"tr": "İçecekler", "en": "Drinks"}
  image_url text,
  sort_order int default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for categories
alter table public.categories enable row level security;

create policy "Categories are viewable by everyone."
  on categories for select
  using ( true );

create policy "Users can manage categories for their branches."
  on categories for all
  using ( exists ( select 1 from public.branches where branches.id = categories.branch_id and branches.owner_id = auth.uid() ) );

-- 5. PRODUCTS (Menu items)
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete cascade not null,
  name jsonb not null, -- Örn: {"tr": "Mercimek Çorbası", "en": "Lentil Soup"}
  description jsonb, -- Örn: {"tr": "Sıcak çorba", "en": "Hot soup"}
  price decimal(10,2) not null,
  image_url text,
  allergens jsonb, -- Örn: [{"code": "gluten", "label": {"tr": "Gluten", "en": "Gluten"}}]
  calories int,
  options jsonb, -- Örn: [{"name": "Porsiyon", "values": ["1", "1.5"]}]
  is_available boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for products
alter table public.products enable row level security;

create policy "Products are viewable by everyone."
  on products for select
  using ( true );

create policy "Users can manage products for their branches."
  on products for all
  using ( exists ( select 1 from public.branches where branches.id = products.branch_id and branches.owner_id = auth.uid() ) );

-- 6. TRIGGER: Handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 7. ORDERS (Table sessions/orders)
create table public.orders (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid not null,
  customer_session_id text, -- Browser fingerprint or local storage ID for anonymous user tracking
  status text default 'pending' check (status in ('pending', 'preparing', 'served', 'completed', 'cancelled')),
  total_amount decimal(10,2) default 0,
  note text, -- Müşteri notu
  last_updated_by uuid references public.profiles(id), -- Siparişi en son güncelleyen personel/sahip
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  foreign key (table_id, branch_id) references public.tables(id, branch_id) on delete cascade
);

-- Enable RLS for orders
alter table public.orders enable row level security;

-- Müşteriler sipariş oluşturabilir (Public)
create policy "Anyone can create orders."
  on orders for insert
  with check ( true );

-- Müşteriler SADECE kendi session ID'lerine ait siparişleri görebilir (Header: x-customer-session-id)
create policy "Customers can view their own orders."
  on orders for select
  using ( customer_session_id = (current_setting('request.headers', true)::json->>'x-customer-session-id') );

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

-- 8. ORDER ITEMS (Products inside an order)
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete set null, -- Ürün silinse bile raporda kalsın
  quantity int default 1,
  price decimal(10,2) not null, -- O anki fiyatı kaydetmeliyiz (Fiyat değişirse geçmiş bozulmasın)
  options jsonb, -- Seçilen opsiyonlar snapshot
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for order items
alter table public.order_items enable row level security;

create policy "Anyone can create order items."
  on order_items for insert
  with check ( true );

-- Müşteriler SADECE kendi siparişlerinin detaylarını görebilir
create policy "Customers can view their own order items."
  on order_items for select
  using ( exists ( select 1 from public.orders where orders.id = order_items.order_id and orders.customer_session_id = (current_setting('request.headers', true)::json->>'x-customer-session-id') ) );

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

-- 9. INDEXES (Performance optimization)
create index idx_orders_customer_session on public.orders(customer_session_id);
create index idx_orders_branch_id on public.orders(branch_id);
create index idx_products_branch_id on public.products(branch_id);
create index idx_products_category_id on public.products(category_id);

-- 10. TRIGGER: Auto-calculate Order Total
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
$$ language plpgsql security definer;

create trigger on_order_item_change
  after insert or update or delete on public.order_items
  for each row execute procedure public.update_order_total();

-- 11. ANALYTICS VIEW (Reporting)
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

-- 12. TABLE ANALYTICS VIEW (Table usage stats)
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
join public.tables t on s.table_id = t.id
where s.table_id is not null
group by s.branch_id, s.table_id, t.name, date(s.scanned_at);

-- Grant access to the view
grant select on public.table_analytics_daily to authenticated;

