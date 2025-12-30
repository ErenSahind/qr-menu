import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
export interface CurrentUser {
  id: string;
  email?: string;
  full_name: string;
  company_name?: string;
  phone?: string | null;
  phone_verified?: boolean | null;
  address?: string | null;
  role: "admin" | "owner" | "staff"; // Enum değerlerini buraya yazarsan type-safe olur
  subscription_plan: "free" | "premium" | "ultimate" | "enterprise";
  subscription_status?:
    | "active"
    | "trialing"
    | "past_due"
    | "canceled"
    | "inactive"
    | null;
  subscription_started_at?: string | null;
  subscription_ends_at?: string | null;
  logo_url?: string | null;
  is_onboarded?: boolean | null;
}
export async function POST(req: Request) {
  try {
    const { email, password } = await req.json();

    if (!email || !password) {
      return NextResponse.json({ error: "missing_fields" }, { status: 400 });
    }

    const supabase = await createClient();

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      // 🔴 Email doğrulanmamış
      if (
        error.message?.toLowerCase().includes("confirm") ||
        error.code === "email_not_confirmed"
      ) {
        return NextResponse.json(
          { error: "email_not_confirmed" },
          { status: 403 }
        );
      }

      return NextResponse.json(
        { error: "invalid_credentials" },
        { status: 401 }
      );
    }

    // 2. Adım: Profil Verisini Çekme (Planı öğrenmek için)
    // Auth'dan dönen user.id'yi kullanıyoruz.
    const { data: profileData, error: profileError } = await supabase
      .from("profiles")
      .select(
        "subscription_plan, role, full_name, phone, phone_verified,  subscription_status, subscription_started_at, subscription_ends_at, logo_url, is_onboarded,company_name"
      ) // İhtiyacın olan alanları seç
      .eq("id", data.user.id)
      .single();

    // 3. Adım: Auth User verisi ile Profile verisini birleştirip dönme
    return NextResponse.json({
      success: true,
      user: {
        id: data.user.id,
        email: data.user.email,
        // Profil tablosundan gelen kritik veriler:
        full_name: profileData?.full_name || data.user.user_metadata.full_name,
        company_name: profileData?.company_name,
        phone: profileData?.phone,
        phone_verified: profileData?.phone_verified,
        role: profileData?.role || "staff", // 'admin', 'owner' vs. (Sidebar'ı buna göre çizeceksin)
        subscription_plan: profileData?.subscription_plan || "free", // (Limit uyarılarını buna göre vereceksin)
        subscription_status: profileData?.subscription_status,
        subscription_started_at: profileData?.subscription_started_at,
        subscription_ends_at: profileData?.subscription_ends_at,
        logo_url: profileData?.logo_url,
        is_onboarded: profileData?.is_onboarded, // (Onboarding'e mi yollayayım dashboard'a mı?)
      },
    });
  } catch (e) {
    return NextResponse.json(
      { error: "internal_server_error" },
      { status: 500 }
    );
  }
}
