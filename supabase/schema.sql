-- ==============================================================================
-- OMEGA QR MENU SAAS - PRODUCTION SCHEMA (FINAL v2.1 - Gold Standard)
-- Security: Private Tables / Public Views Strategy
-- Analytics: Trigger-based Real-time Aggregation
-- ==============================================================================

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
  max_products int, 
  max_categories int, 
  max_staff int, 
  allow_images boolean default true,
  allow_ordering boolean default false
);
alter table public.plan_features enable row level security;
create policy "Everyone can view plan features" on plan_features for select using (true);
insert into public.plan_features (plan, max_branches, max_products, max_categories, max_staff, allow_images, allow_ordering) values
('free', 1, 20, 5, 5, false, false),
('premium', 1, null, null, null, true, false),
('ultimate', 3, null, null, null, true, true), 
('enterprise', 5, null, null, null, true, true);

-- 3. PROFILES (Private Data)
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  full_name text constraint check_fullname_len check (char_length(full_name) <= 100),
  company_name text constraint check_company_len check (char_length(company_name) <= 150),
  phone text constraint check_phone_len check (char_length(phone) <= 20),
  phone_verified boolean default false, 
  address text constraint check_address_len check (char_length(address) <= 300), 
  country text default 'Türkiye', 
  default_currency text default 'TRY', 
  default_languages text[] default '{tr}', 
  logo_url text, 
  is_onboarded boolean default false, 
  role public.user_role default 'owner', 
  subscription_plan public.subscription_plan default 'free', 
  subscription_status public.subscription_status default 'inactive',
  subscription_started_at timestamp with time zone,
  subscription_ends_at timestamp with time zone,
  purchased_branch_limit int default 0, 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.profiles enable row level security;
create policy "Users can view own profile." on profiles for select using ( auth.uid() = id );
create policy "Users can insert their own profile." on profiles for insert with check ( auth.uid() = id );
create policy "Users can update own profile." on profiles for update using ( auth.uid() = id ) with check ( auth.uid() = id );

-- HELPER: Check Image Upload Permission
create or replace function public.fn_can_upload_image(target_owner_id uuid) returns boolean as $$
declare is_allowed boolean;
begin
  select pf.allow_images into is_allowed from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where p.id = target_owner_id;
  return coalesce(is_allowed, false);
end;
$$ language plpgsql security definer set search_path = public;

-- TRIGGER: Modular Image Check
create or replace function public.check_image_permission_trigger() returns trigger as $$
declare owner_uuid uuid; image_val text; target_branch_id uuid;
begin
  if TG_OP = 'UPDATE' then
    if TG_TABLE_NAME = 'branches' and new.cover_image_url is not distinct from old.cover_image_url then return new;
    elsif TG_TABLE_NAME = 'profiles' and new.logo_url is not distinct from old.logo_url then return new;
    elsif (TG_TABLE_NAME = 'categories' or TG_TABLE_NAME = 'products') and new.image_url is not distinct from old.image_url then return new;
    end if;
  end if;
  if TG_TABLE_NAME = 'branches' then image_val := new.cover_image_url; owner_uuid := new.owner_id;
  elsif TG_TABLE_NAME = 'profiles' then image_val := new.logo_url; if new.role <> 'owner' then raise exception 'ONLY_OWNER_CAN_UPLOAD_LOGO'; end if; owner_uuid := new.id;
  else image_val := new.image_url; target_branch_id := new.branch_id; select owner_id into owner_uuid from public.branches where id = target_branch_id; end if;

  if image_val is null then return new; end if;
  if owner_uuid is null then raise exception 'OWNER_NOT_FOUND'; end if;
  if not public.fn_can_upload_image(owner_uuid) then raise exception 'IMAGE_UPLOAD_NOT_ALLOWED_FOR_PLAN'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger on_profile_logo_check before insert or update on public.profiles for each row execute procedure public.check_image_permission_trigger();

-- TRIGGER: Protect Profile Fields
create or replace function public.protect_profile_fields() returns trigger as $$
begin
  if current_setting('role', true) not in ('service_role', 'postgres') then
    if (new.subscription_plan is distinct from old.subscription_plan) or (new.role is distinct from old.role) then
       raise exception 'UNAUTHORIZED_FIELD_UPDATE';
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger on_profile_update_protect before update on public.profiles for each row execute procedure public.protect_profile_fields();

-- SYSTEM SETTINGS
create table public.system_settings (
  id int primary key default 1, 
  default_signup_plan public.subscription_plan default 'free',
  default_trial_days int default 14, 
  plan_prices jsonb default '{"free": 0, "premium": 4000, "ultimate": 6000, "enterprise": 9000}', 
  extra_branch_prices jsonb default '{"free": 0, "premium": 2000, "ultimate": 1500, "enterprise": 1400}',
  currency text default 'TRY',
  maintenance_mode boolean default false, 
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_by uuid references public.profiles(id),
  constraint single_row_check check (id = 1)
);
alter table public.system_settings enable row level security;
create policy "Admins can view system settings." on system_settings for select using ( exists ( select 1 from public.profiles where id = auth.uid() and role = 'admin' ) );
create policy "Admins can update system settings." on system_settings for update using ( exists ( select 1 from public.profiles where id = auth.uid() and role = 'admin' ) );
insert into public.system_settings (id) values (1) on conflict do nothing;
create view public.pricing_settings as select plan_prices, extra_branch_prices, currency from public.system_settings;
grant select on public.pricing_settings to anon, authenticated;

-- 4. BRANCHES (Private Table / Public View)
create table public.branches (
  id uuid default uuid_generate_v4() primary key,
  owner_id uuid references public.profiles(id) on delete cascade not null,
  name text not null constraint check_branch_name_len check (char_length(name) <= 100),
  slug text unique not null, 
  address text constraint check_branch_address_len check (char_length(address) <= 300),
  country text default 'Türkiye',
  city text constraint check_city_len check (char_length(city) <= 50),
  district text constraint check_district_len check (char_length(district) <= 50),
  timezone text default 'Europe/Istanbul', 
  languages text[] default '{tr}', 
  wifi_info jsonb constraint check_wifi_len check (char_length(wifi_info::text) <= 500),
  phone text constraint check_branch_phone_len check (char_length(phone) <= 20),
  cover_image_url text,
  social_media jsonb, 
  working_hours jsonb, 
  currency text default 'TRY', 
  is_ordering_enabled boolean default false,
  latitude decimal(10,8),
  longitude decimal(11,8),
  max_distance int default 500, 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.branches enable row level security;
-- 🔒 SECURITY: Table is NOT public. Only Owner/Staff.
create policy "Owner/Staff can view branches" on branches for select using ( auth.uid() = owner_id or exists ( select 1 from public.branch_staff bs where bs.branch_id = branches.id and bs.user_id = auth.uid() and bs.is_active = true ) );
create policy "Users can insert their own branches." on branches for insert with check ( auth.uid() = owner_id );
create policy "Users can delete their own branches." on branches for delete using ( auth.uid() = owner_id );
create policy "Users can update own branches." on branches for update using ( auth.uid() = owner_id ); 
create trigger check_branch_image before insert or update on public.branches for each row execute procedure public.check_image_permission_trigger();

-- ✅ PUBLIC VIEW: Safe Branch Data for QR Menu
create or replace view public.public_branches as
select id, slug, name, address, city, district, country, wifi_info, working_hours, cover_image_url, social_media, phone, currency, languages, is_ordering_enabled, latitude, longitude
from public.branches;
grant select on public.public_branches to anon, authenticated;

create or replace function public.check_branch_limit() returns trigger as $$
declare count int; max_b int;
begin
  perform pg_advisory_xact_lock(hashtext(new.owner_id::text)); 
  select pf.max_branches into max_b from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where p.id = new.owner_id;
  if max_b is null then return new; end if;
  select count(*) into count from public.branches where owner_id = new.owner_id;
  if count >= max_b then raise exception 'BRANCH_LIMIT_EXCEEDED'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger enforce_branch_limit before insert on public.branches for each row execute procedure public.check_branch_limit();

-- 5. BRANCH STAFF
create table public.branch_staff (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role public.staff_role default 'waiter',
  is_active boolean default true, 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, user_id)
);
alter table public.branch_staff enable row level security;
create policy "Owner can manage all staff" on branch_staff for all using ( exists ( select 1 from public.branches where branches.id = branch_staff.branch_id and branches.owner_id = auth.uid() ) );
create policy "Staff can view branch colleagues" on branch_staff for select using ( auth.uid() = user_id or exists ( select 1 from public.branch_staff bs where bs.user_id = auth.uid() and bs.branch_id = branch_staff.branch_id and bs.is_active = true ) );

create or replace function public.check_staff_limit() returns trigger as $$
declare staff_count int; max_allowed int; owner_uuid uuid; is_increase boolean := false;
begin
  if (TG_OP = 'INSERT' and new.is_active = true) then is_increase := true;
  elsif (TG_OP = 'UPDATE' and old.is_active = false and new.is_active = true) then is_increase := true; end if;
  if not is_increase then return new; end if;
  select owner_id into owner_uuid from public.branches where id = new.branch_id;
  if owner_uuid is null then raise exception 'BRANCH_NOT_FOUND'; end if;
  perform pg_advisory_xact_lock(hashtext(owner_uuid::text));
  select pf.max_staff into max_allowed from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where p.id = owner_uuid;
  if max_allowed is null then return new; end if; 
  select count(distinct bs.user_id) into staff_count from public.branch_staff bs join public.branches b on b.id = bs.branch_id where b.owner_id = owner_uuid and bs.is_active = true and (TG_OP = 'INSERT' or bs.id <> new.id);
  if staff_count >= max_allowed then raise exception 'STAFF_LIMIT_EXCEEDED'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger enforce_staff_limit before insert or update on public.branch_staff for each row execute procedure public.check_staff_limit();

-- 6. RESTAURANT TABLES (Private Table / Public View)
create table public.restaurant_tables (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name text not null constraint check_table_name_len check (char_length(name) <= 50),
  qr_code text unique not null, 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(branch_id, name),
  unique(id, branch_id)
);
alter table public.restaurant_tables enable row level security;
-- 🔒 SECURITY: Table is NOT public.
create policy "Owner/Manager manage tables" on restaurant_tables for all using ( exists ( select 1 from public.branches where branches.id = restaurant_tables.branch_id and branches.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff where branch_staff.branch_id = restaurant_tables.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true ) );
-- Waiter needs to see tables to take orders
create policy "Staff view tables" on restaurant_tables for select using ( exists ( select 1 from public.branch_staff bs where bs.branch_id = restaurant_tables.branch_id and bs.user_id = auth.uid() and bs.is_active = true ) );

-- ✅ PUBLIC VIEW: Safe Data for QR Scan Resolution
create or replace view public.public_tables as
select id, branch_id, name, qr_code
from public.restaurant_tables;
grant select on public.public_tables to anon, authenticated;

-- 7. QR SCANS
create table public.qr_scans (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid, 
  customer_session_id uuid, 
  scanned_at timestamp with time zone default timezone('utc'::text, now()) not null,
  foreign key (table_id, branch_id) references public.restaurant_tables(id, branch_id) on delete set null
);
alter table public.qr_scans enable row level security;
create policy "Anyone can insert qr scans." on qr_scans for insert with check ( true );
create policy "Branch owners and staff can view scans." on qr_scans for select using ( exists ( select 1 from public.branches where branches.id = qr_scans.branch_id and branches.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff where branch_staff.branch_id = qr_scans.branch_id and branch_staff.user_id = auth.uid() and branch_staff.is_active = true ) );

-- 8. CATEGORIES (Private Table / Public View)
create table public.categories (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  name jsonb not null constraint check_cat_name_len check (char_length(name::text) <= 500), 
  image_url text,
  sort_order int default 0,
  is_active boolean default true, 
  type text default 'standard' check (type in ('standard', 'campaign')), 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint check_name_valid check (jsonb_typeof(name) = 'object' and name <> '{}'::jsonb)
);
create trigger check_category_image before insert or update on public.categories for each row execute procedure public.check_image_permission_trigger();
alter table public.categories enable row level security;
create policy "Owner/Staff can manage categories" on categories for all using ( exists ( select 1 from public.branches where branches.id = categories.branch_id and branches.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff where branch_staff.branch_id = categories.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true ) );

-- ✅ PUBLIC VIEW: Only Active Categories
create or replace view public.public_categories as
select id, branch_id, name, image_url, sort_order, type
from public.categories
where is_active = true;
grant select on public.public_categories to anon, authenticated;

create or replace function public.check_category_limit() returns trigger as $$
declare count int; max_c int; owner_uuid uuid;
begin
  select owner_id into owner_uuid from public.branches where id = new.branch_id;
  perform pg_advisory_xact_lock(hashtext(owner_uuid::text));
  select pf.max_categories into max_c from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where p.id = owner_uuid;
  if max_c is null then return new; end if;
  select count(*) into count from public.categories c join public.branches b on b.id = c.branch_id where b.owner_id = owner_uuid;
  if count >= max_c then raise exception 'CATEGORY_LIMIT_EXCEEDED'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger enforce_category_limit before insert on public.categories for each row execute procedure public.check_category_limit();

-- 9. PRODUCTS (Private Table / Public View)
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete cascade not null,
  name jsonb not null constraint check_prod_name_len check (char_length(name::text) <= 500), 
  description jsonb constraint check_prod_desc_len check (char_length(description::text) <= 2000), 
  price decimal(10,2) not null,
  image_url text,
  allergens text[] default '{}', 
  ingredients jsonb constraint check_prod_ing_len check (char_length(ingredients::text) <= 1000), 
  calories int,
  is_available boolean default true, 
  is_active boolean default true, 
  sort_order int default 0, 
  badges text[] default '{}', 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
create trigger check_product_image before insert or update on public.products for each row execute procedure public.check_image_permission_trigger();
alter table public.products enable row level security;
create policy "Owner/Staff can manage products" on products for all using ( exists ( select 1 from public.branches where branches.id = products.branch_id and branches.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff where branch_staff.branch_id = products.branch_id and branch_staff.user_id = auth.uid() and branch_staff.role = 'manager' and branch_staff.is_active = true ) );

-- ✅ PUBLIC VIEW: Only Active & Available Products
create or replace view public.public_products as
select id, branch_id, category_id, name, description, price, image_url, allergens, ingredients, calories, badges, sort_order
from public.products
where is_active = true and is_available = true;
grant select on public.public_products to anon, authenticated;

create or replace function public.check_product_limit() returns trigger as $$
declare count int; max_p int; owner_uuid uuid;
begin
  select owner_id into owner_uuid from public.branches where id = new.branch_id;
  perform pg_advisory_xact_lock(hashtext(owner_uuid::text));
  select pf.max_products into max_p from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where p.id = owner_uuid;
  if max_p is null then return new; end if;
  select count(*) into count from public.products pr join public.branches b on b.id = pr.branch_id where b.owner_id = owner_uuid;
  if count >= max_p then raise exception 'PRODUCT_LIMIT_EXCEEDED'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger enforce_product_limit before insert on public.products for each row execute procedure public.check_product_limit();

-- 10. NEW USER HANDLER
create or replace function public.handle_new_user() returns trigger as $$
declare def_plan public.subscription_plan; def_days int;
begin
  select default_signup_plan, default_trial_days into def_plan, def_days from public.system_settings where id = 1 limit 1;
  if def_plan is null then def_plan := 'free'; def_days := 0; end if;
  insert into public.profiles (id, full_name, subscription_plan, subscription_ends_at)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''), def_plan, case when def_days > 0 then (now() + (def_days || ' days')::interval) else null end);
  return new;
end;
$$ language plpgsql security definer set search_path = public;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- 11. ORDERS
create table public.orders (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  table_id uuid not null,
  customer_session_id uuid not null check (length(customer_session_id::text) = 36), 
  status public.order_status default 'pending',
  total_amount decimal(10,2) default 0,
  note text constraint check_order_note_len check (char_length(note) <= 250), 
  gps_lat decimal(10,8), 
  gps_lng decimal(11,8),
  last_updated_by uuid references public.profiles(id), 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  foreign key (table_id, branch_id) references public.restaurant_tables(id, branch_id) on delete cascade
);
create or replace function public.touch_updated_at() returns trigger as $$ begin new.updated_at := now(); return new; end; $$ language plpgsql;
create trigger on_orders_touch_updated before update on public.orders for each row execute procedure public.touch_updated_at();
create or replace function public.set_last_updated_by() returns trigger as $$ begin new.last_updated_by := auth.uid(); return new; end; $$ language plpgsql security definer set search_path = public;
create trigger on_orders_set_last_updated_by before update on public.orders for each row execute procedure public.set_last_updated_by();

create or replace function public.check_ordering_permission() returns trigger as $$
declare allowed boolean;
begin
  select pf.allow_ordering into allowed from public.branches b join public.profiles p on p.id = b.owner_id join public.plan_features pf on pf.plan = p.subscription_plan where b.id = new.branch_id;
  if allowed is not true then raise exception 'ORDERING_NOT_ALLOWED_FOR_PLAN'; end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger check_ordering_permission_trigger before insert on public.orders for each row execute procedure public.check_ordering_permission();

create or replace function public.limit_order_frequency() returns trigger as $$
declare target_session_id uuid; target_branch_id uuid;
begin
  target_session_id := new.customer_session_id; target_branch_id := new.branch_id;
  perform pg_advisory_xact_lock(hashtext(target_session_id::text || '-' || target_branch_id::text));
  if exists ( select 1 from public.orders where customer_session_id = target_session_id and branch_id = target_branch_id and created_at >= now() - interval '5 seconds' ) then
    raise exception 'ORDER_RATE_LIMIT';
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
create trigger check_order_frequency before insert on public.orders for each row execute procedure public.limit_order_frequency();

create or replace function public.protect_order_fields() returns trigger as $$ begin if new.total_amount is distinct from old.total_amount or new.branch_id is distinct from old.branch_id or new.customer_session_id is distinct from old.customer_session_id then raise exception 'ORDER_IMMUTABLE_FIELDS'; end if; return new; end; $$ language plpgsql security definer set search_path = public;
create trigger protect_orders_update before update on public.orders for each row execute procedure public.protect_order_fields();

-- 🛡️ ORDERS RLS (Hardened)
alter table public.orders enable row level security;
create policy "Anyone can create orders" on orders for insert with check ( customer_session_id is not null );
create policy "Customers view own orders" on orders for select using ( customer_session_id::text = coalesce(current_setting('request.headers', true)::json->>'x-customer-session-id', 'no-session') );
create policy "Staff view branch orders" on orders for select using ( exists ( select 1 from public.branches b where b.id = orders.branch_id and b.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff bs where bs.branch_id = orders.branch_id and bs.user_id = auth.uid() and bs.is_active = true ) );
create policy "Management update orders" on orders for update using ( exists ( select 1 from public.branches b where b.id = orders.branch_id and b.owner_id = auth.uid() ) or exists ( select 1 from public.branch_staff bs where bs.branch_id = orders.branch_id and bs.user_id = auth.uid() and bs.role = 'manager' and bs.is_active = true ) );

-- 12. ORDER ITEMS
create table public.order_items (
  id uuid default uuid_generate_v4() primary key,
  order_id uuid references public.orders(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete set null, 
  quantity int default 1 check (quantity > 0),
  price decimal(10,2) not null check (price >= 0), 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);
alter table public.order_items enable row level security;
create policy "Anyone create items" on order_items for insert with check ( exists ( select 1 from public.orders o where o.id = order_items.order_id and o.customer_session_id::text = coalesce(current_setting('request.headers', true)::json->>'x-customer-session-id', 'no-session') ) );
create policy "Customer view items" on order_items for select using ( exists ( select 1 from public.orders o where o.id = order_items.order_id and o.customer_session_id::text = coalesce(current_setting('request.headers', true)::json->>'x-customer-session-id', 'no-session') ) );
create policy "Staff view items" on order_items for select using ( exists ( select 1 from public.orders o join public.branches b on b.id = o.branch_id where o.id = order_items.order_id and b.owner_id = auth.uid() ) or exists ( select 1 from public.orders o join public.branch_staff bs on bs.branch_id = o.branch_id where o.id = order_items.order_id and bs.user_id = auth.uid() and bs.is_active = true ) );
create policy "Management update items" on order_items for update using ( exists ( select 1 from public.orders o join public.branches b on b.id = o.branch_id where o.id = order_items.order_id and b.owner_id = auth.uid() ) or exists ( select 1 from public.orders o join public.branch_staff bs on bs.branch_id = o.branch_id where o.id = order_items.order_id and bs.user_id = auth.uid() and bs.role = 'manager' ) );

create or replace function public.protect_order_item_price() returns trigger as $$ begin if new.price is distinct from old.price then raise exception 'ORDER_ITEM_PRICE_IMMUTABLE'; end if; return new; end; $$ language plpgsql security definer set search_path = public;
create trigger protect_order_item_update before update on public.order_items for each row execute procedure public.protect_order_item_price();

-- 13. INDEXES & UTILITIES
create index idx_orders_customer_session on public.orders(customer_session_id);
create index idx_orders_branch_id on public.orders(branch_id);
create index idx_products_branch_id on public.products(branch_id);
create index idx_products_category_id on public.products(category_id);
create index idx_branch_staff_owner on public.branch_staff(user_id, is_active);
create index idx_branches_owner on public.branches(owner_id);
create index idx_orders_branch_status on public.orders(branch_id, status);
create index idx_orders_branch_created_at on public.orders(branch_id, created_at desc);
create index idx_qr_scans_branch_date on public.qr_scans(branch_id, scanned_at);
create index idx_orders_session_time on public.orders(customer_session_id, created_at desc);

create or replace function public.update_order_total() returns trigger as $$ declare target_order_id uuid; begin if (TG_OP = 'DELETE') then target_order_id := old.order_id; else target_order_id := new.order_id; end if; update public.orders set total_amount = ( select coalesce(sum(price * quantity), 0) from public.order_items where order_id = target_order_id ) where id = target_order_id; return null; end; $$ language plpgsql security definer set search_path = public;
create trigger on_order_item_change after insert or update or delete on public.order_items for each row execute procedure public.update_order_total();

create or replace function public.handle_sort_order() returns trigger as $$ declare max_order int; target_branch_id uuid; target_category_id uuid; begin if new.sort_order > 0 then return new; end if; if TG_TABLE_NAME = 'categories' then target_branch_id := new.branch_id; perform pg_advisory_xact_lock(hashtext(target_branch_id::text)); select coalesce(max(sort_order), 0) into max_order from public.categories where branch_id = target_branch_id; elsif TG_TABLE_NAME = 'products' then target_category_id := new.category_id; perform pg_advisory_xact_lock(hashtext(target_category_id::text)); select coalesce(max(sort_order), 0) into max_order from public.products where category_id = target_category_id; end if; new.sort_order := max_order + 1; return new; end; $$ language plpgsql security definer set search_path = public;
create trigger on_category_created before insert on public.categories for each row execute procedure public.handle_sort_order();
create trigger on_product_created before insert on public.products for each row execute procedure public.handle_sort_order();

create or replace function public.slugify(value text) returns text as $$ begin value := lower(value); value := replace(value, 'ı', 'i'); value := replace(value, 'ğ', 'g'); value := replace(value, 'ü', 'u'); value := replace(value, 'ş', 's'); value := replace(value, 'ö', 'o'); value := replace(value, 'ç', 'c'); value := regexp_replace(value, '[^a-z0-9\s-]', '', 'g'); value := regexp_replace(value, '\s+', '-', 'g'); value := trim(both '-' from value); return value; end; $$ language plpgsql stable;
create or replace function public.handle_branch_slug() returns trigger as $$ declare c_name text; base_slug text; final_slug text; counter int := 0; target_owner_id uuid; target_record_id uuid; begin target_owner_id := new.owner_id; target_record_id := new.id; select coalesce(company_name, full_name) into c_name from public.profiles where id = target_owner_id; if (TG_OP = 'INSERT') or (new.name <> old.name) then base_slug := public.slugify(c_name || '-' || new.name); perform pg_advisory_xact_lock(hashtext(base_slug)); final_slug := base_slug; while exists (select 1 from public.branches where slug = final_slug and id <> target_record_id) loop counter := counter + 1; final_slug := base_slug || '-' || counter; end loop; new.slug := final_slug; end if; return new; end; $$ language plpgsql security definer set search_path = public;
create trigger on_branch_create_slug before insert or update on public.branches for each row execute procedure public.handle_branch_slug();

-- STORAGE POLICIES
create policy "Paid users can upload images" on storage.objects for insert with check ( bucket_id = 'images' and auth.uid() in ( select id from public.profiles p join public.plan_features pf on pf.plan = p.subscription_plan where pf.allow_images = true ) and (split_part(name, '/', 2))::uuid = auth.uid() );
create policy "Restrict file size to 200KB" on storage.objects for insert with check ( ((metadata->>'size')::int <= 204800 or metadata->>'size' is null) and (metadata->>'mimetype') like 'image/%' );

-- ==========================================
-- 15. HYBRID ANALYTICS (The "Smart" Way)
-- ==========================================

-- 15.1 Physical Table (SADECE CİRO VE SİPARİŞLER)
-- QR Scan ve Visitor gibi "High Velocity" dataları buradan çıkardık. Lock şişmesini önledik.
create table public.daily_revenue_stats (
  id uuid default uuid_generate_v4() primary key,
  branch_id uuid references public.branches(id) on delete cascade not null,
  date date default current_date not null,

  -- Sadece Finansal ve Operasyonel Kritik Data
  orders_count int not null default 0,
  orders_completed int not null default 0,
  orders_cancelled int not null default 0,
  
  gross_revenue decimal(10,2) not null default 0,
  net_revenue decimal(10,2) not null default 0,

  updated_at timestamp with time zone default timezone('utc'::text, now()),
  unique(branch_id, date)
);

alter table public.daily_revenue_stats enable row level security;
-- Policy: Owner sadece kendi cirosunu görür
create policy "Owner view revenue" on daily_revenue_stats for select using ( exists ( select 1 from public.branches b where b.id = daily_revenue_stats.branch_id and b.owner_id = auth.uid() ) );


-- 15.2 TRIGGER: Order Analytics (ROBUST STATE MACHINE)
-- State değişimlerini daha güvenli hale getirdik.
create or replace function public.update_revenue_stats() returns trigger as $$
declare
  -- Değişim miktarlarını tutacak değişkenler
  delta_count int := 0;
  delta_completed int := 0;
  delta_cancelled int := 0;
  delta_gross decimal(10,2) := 0;
  delta_net decimal(10,2) := 0;
begin
  -- 1. INSERT (Yeni Sipariş)
  if (TG_OP = 'INSERT') then
    delta_count := 1;
  end if;

  -- 2. UPDATE (Durum Değişimi)
  if (TG_OP = 'UPDATE') then
    -- Para kazandıran durum: Tamamlandı
    if (new.status = 'completed' and old.status <> 'completed') then
      delta_completed := 1;
      delta_gross := new.total_amount;
      delta_net := new.total_amount;
    end if;

    -- Para kaybettiren durum: Tamamlanmış sipariş iptal edildi (İade)
    if (old.status = 'completed' and new.status = 'cancelled') then
      delta_completed := -1;
      delta_cancelled := 1;
      delta_gross := -1 * old.total_amount; -- Brüt düşer
      delta_net := -1 * old.total_amount;   -- Net düşer
    end if;

    -- Nötr İptal: Hazırlanırken iptal edildi (Para henüz sayılmamıştı)
    if (old.status <> 'completed' and old.status <> 'cancelled' and new.status = 'cancelled') then
      delta_cancelled := 1;
    end if;
  end if;

  -- 3. UPSERT (Atomic Update)
  -- Eğer hiçbir değişim yoksa işlem yapma (Db yükünü azalt)
  if (delta_count = 0 and delta_completed = 0 and delta_cancelled = 0 and delta_gross = 0) then
    return null;
  end if;

  insert into public.daily_revenue_stats (branch_id, date, orders_count, orders_completed, orders_cancelled, gross_revenue, net_revenue, updated_at)
  values (new.branch_id, date(new.created_at), delta_count, delta_completed, delta_cancelled, delta_gross, delta_net, now())
  on conflict (branch_id, date) 
  do update set 
    orders_count = daily_revenue_stats.orders_count + excluded.orders_count,
    orders_completed = daily_revenue_stats.orders_completed + excluded.orders_completed,
    orders_cancelled = daily_revenue_stats.orders_cancelled + excluded.orders_cancelled,
    gross_revenue = daily_revenue_stats.gross_revenue + excluded.gross_revenue,
    net_revenue = daily_revenue_stats.net_revenue + excluded.net_revenue,
    updated_at = now();

  return null;
end;
$$ language plpgsql security definer;

create trigger on_order_revenue_change 
after insert or update on public.orders 
for each row execute procedure public.update_revenue_stats();


-- ==========================================
-- 15.3 NO TRIGGER FOR QR SCANS! (Direct Live View)
-- QR Scan'ler için trigger kullanmıyoruz. View kullanacağız.
-- ==========================================


-- ==========================================
-- 16. UNIFIED ANALYTICS VIEW (Frontend'in Tek Muhatabı)
-- ==========================================
-- Bu View:
-- 1. Revenue bilgisini "daily_revenue_stats" tablosundan alır (HIZLI)
-- 2. Scan bilgisini "qr_scans" tablosundan canlı sayar (GÜVENLİ)
-- 3. Unique Visitor'ı canlı sayar (DOĞRU)

create or replace view public.analytics_dashboard_daily
with (security_invoker = true)
as
select
  -- Temel Bilgiler
  coalesce(r.branch_id, s.branch_id) as branch_id,
  coalesce(r.date, s.scan_date) as report_date,

  -- Ciro ve Siparişler (Fiziksel Tablodan - O(1) Hızında)
  coalesce(r.gross_revenue, 0) as gross_revenue,
  coalesce(r.net_revenue, 0) as net_revenue,
  coalesce(r.orders_count, 0) as orders_count,
  coalesce(r.orders_completed, 0) as orders_completed,
  coalesce(r.orders_cancelled, 0) as orders_cancelled,

  -- Trafik (Canlı Hesaplanır - Index ile Hızlıdır)
  coalesce(s.qr_scans, 0) as qr_scans,
  coalesce(s.unique_visitors, 0) as unique_visitors

from 
  -- 1. Source: Revenue Stats
  public.daily_revenue_stats r

full outer join (
  -- 2. Source: Live Aggregation of Scans
  -- Bu sorgu indexli olduğu için gün bazında çok hızlıdır.
  select 
    branch_id, 
    date(scanned_at) as scan_date, 
    count(*) as qr_scans,
    count(distinct customer_session_id) as unique_visitors -- İşte gerçek Unique Visitor!
  from public.qr_scans
  group by branch_id, date(scanned_at)
) s on r.branch_id = s.branch_id and r.date = s.scan_date;

-- Frontend Kullanımı:
-- supabase.from('analytics_dashboard_daily').select('*').eq('branch_id', '...').limit(30)

-- ==========================================
-- 17. DETAILED ANALYTICS VIEWS (Reporting Layer)
-- ==========================================

-- 📊 1. AYLIK GÖRÜNÜM (GÜNCELLENDİ)
-- Eski 'daily_branch_analytics' yerine yeni 'daily_revenue_stats' tablosunu kullanıyor.
-- Ciro verisi fiziksel tablodan gelir (HIZLI).
-- Scan verisi canlı hesaplanır (GÜNCEL).

create or replace view public.view_analytics_monthly
with (security_invoker = true)
as
select 
  -- Temel Bilgiler
  coalesce(r.branch_id, s.branch_id) as branch_id,
  
  -- Tarih (Ayın ilk günü olarak grupla)
  date_trunc('month', coalesce(r.date, s.scan_date))::date as report_month,
  
  -- Finansal Veriler (Hızlı Tablodan)
  sum(coalesce(r.net_revenue, 0)) as revenue,
  sum(coalesce(r.orders_completed, 0)) as completed_orders,
  sum(coalesce(r.orders_cancelled, 0)) as cancelled_orders,
  
  -- Trafik Verisi (Canlı Tablodan)
  sum(coalesce(s.scan_count, 0)) as qr_scans

from public.daily_revenue_stats r
-- QR Scan verisini aylık bazda birleştiriyoruz
full outer join (
  select 
    branch_id, 
    date(scanned_at) as scan_date, 
    count(*) as scan_count 
  from public.qr_scans 
  group by branch_id, date(scanned_at)
) s on r.branch_id = s.branch_id and r.date = s.scan_date

group by coalesce(r.branch_id, s.branch_id), date_trunc('month', coalesce(r.date, s.scan_date));


-- 🏆 2. MASALARIN PERFORMANSI (AYNEN KALIYOR)
-- Hangi masadan ne kadar ciro gelmiş?
create or replace view public.view_table_performance 
with (security_invoker = true) 
as
select 
  t.branch_id, 
  t.name as table_name, 
  count(distinct s.id) as scan_count, 
  count(distinct o.id) filter (where o.status = 'completed') as order_count, 
  coalesce(sum(o.total_amount) filter (where o.status = 'completed'), 0) as total_revenue 
from public.restaurant_tables t 
left join public.qr_scans s on s.table_id = t.id 
left join public.orders o on o.table_id = t.id 
group by t.branch_id, t.id, t.name;


-- 🍔 3. EN ÇOK SATAN ÜRÜNLER (AYNEN KALIYOR)
-- Hangi ürün kaç tane satmış?
create or replace view public.view_top_products 
with (security_invoker = true) 
as
select 
  o.branch_id, 
  p.name as product_name, 
  count(oi.id) as quantity_sold, 
  sum(oi.price * oi.quantity) as revenue_generated 
from public.order_items oi 
join public.orders o on o.id = oi.order_id 
join public.products p on p.id = oi.product_id 
where o.status = 'completed' 
group by o.branch_id, p.id, p.name;