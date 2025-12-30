import {
  Tables,
  TablesInsert,
  TablesUpdate,
  Enums,
} from "@/lib/supabase/types";

// --- Tablo Satır Tipleri (Okuma / Select işlemleri için) ---
export type Branch = Tables<"branches">;
export type Category = Tables<"categories">;
export type Product = Tables<"products">;
export type Order = Tables<"orders">;
export type OrderItem = Tables<"order_items">;
export type Profile = Tables<"profiles">;
export type RestaurantTable = Tables<"restaurant_tables">;
export type QrScan = Tables<"qr_scans">;
export type BranchStaff = Tables<"branch_staff">;
export type PlanFeature = Tables<"plan_features">;

// --- Ekleme Tipleri (Insert işlemleri için) ---
// Supabase bu tiplerde 'id' veya 'created_at' gibi otomatik alanları opsiyonel yapar.
export type BranchInsert = TablesInsert<"branches">;
export type CategoryInsert = TablesInsert<"categories">;
export type ProductInsert = TablesInsert<"products">;
export type OrderInsert = TablesInsert<"orders">;
export type OrderItemInsert = TablesInsert<"order_items">;
export type ProfileInsert = TablesInsert<"profiles">;

// --- Güncelleme Tipleri (Update işlemleri için) ---
// Tüm alanlar opsiyoneldir.
export type BranchUpdate = TablesUpdate<"branches">;
export type CategoryUpdate = TablesUpdate<"categories">;
export type ProductUpdate = TablesUpdate<"products">;
export type OrderUpdate = TablesUpdate<"orders">;

// --- Enum Tipleri ---
export type UserRole = Enums<"user_role">;
export type OrderStatus = Enums<"order_status">;
export type SubscriptionPlan = Enums<"subscription_plan">;
