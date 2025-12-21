import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabasePublicKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLIC_KEY!;

// Standart istemci (Client ve Server'da güvenle kullanılabilir)
// RLS (Row Level Security) kurallarına tabidir.
export const supabase = createClient(supabaseUrl, supabasePublicKey);

// Admin istemcisi (SADECE Server-side kullanılmalı)
// RLS'i bypass eder, her şeyi yapabilir (User silme, tüm datayı okuma vb.)
// DİKKAT: Bu fonksiyonu asla Client Component'lerde kullanmayın!
export const getSupabaseAdmin = () => {
  const supabaseSecretKey = process.env.SUPABASE_SECRET_KEY;

  if (!supabaseSecretKey) {
    // Tarayıcıda çalışırsa secret key undefined olacağı için buraya düşer
    throw new Error(
      "KEY bulunamadı. Bu fonksiyon sadece sunucu tarafında (API Routes, Server Actions) çalıştırılmalıdır."
    );
  }

  return createClient(supabaseUrl, supabaseSecretKey);
};
