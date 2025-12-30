import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  try {
    const { email, password, full_name } = await req.json();

    if (!email || !password) {
      return NextResponse.json({ error: "missing_fields" }, { status: 400 });
    }

    const supabase = await createClient();

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name,
        },
      },
    });

    if (error) {
      // 🔹 SADECE email zaten varsa özel ele alıyoruz
      if (error.code === "user_already_exists") {
        return NextResponse.json({ error: "email_in_use" }, { status: 409 });
      }

      // 🔹 diğer tüm hatalar olduğu gibi
      return NextResponse.json(
        { error: error.code || "registration_failed" },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { success: true, user: data.user },
      { status: 201 }
    );
  } catch (error) {
    return NextResponse.json(
      { error: "internal_server_error" },
      { status: 500 }
    );
  }
}
