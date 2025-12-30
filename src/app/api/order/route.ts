import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  // 2. Sipariş oluşturma işlemleri (örnek)
  // const body = await req.json();
  // ...sipariş oluşturma kodu...

  return NextResponse.json({
    success: true,
    message: "Order created (dummy response)",
  });
}
