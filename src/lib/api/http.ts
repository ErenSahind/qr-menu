type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

interface RequestOptions {
  body?: unknown;
  headers?: HeadersInit;
}

// 👇 ÖNEMLİ DEĞİŞİKLİK 1: Varsayılan bir Genel Tip (GeneralResponse) tanımlayalım
interface GeneralResponse {
  success: boolean;
  message?: string;
  error?: string;
  [key: string]: any; // İçinde başka her şey olabilir
}

// 👇 ÖNEMLİ DEĞİŞİKLİK 2: <T = GeneralResponse>
// Yani: "Bana tip verilirse onu kullan, verilmezse GeneralResponse kabul et."
async function request<T = GeneralResponse>(
  method: HttpMethod,
  url: string,
  options?: RequestOptions
): Promise<T> {
  const res = await fetch(url, {
    method,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
    body: options?.body ? JSON.stringify(options.body) : undefined,
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(data.error ?? "Bir hata oluştu");
  }

  return data as T;
}

// 👇 ÖNEMLİ DEĞİŞİKLİK 3: Buradaki fonksiyonlara da varsayılanı ekliyoruz
export const http = {
  get: <T = GeneralResponse>(url: string) => request<T>("GET", url),
  post: <T = GeneralResponse>(url: string, body?: unknown) =>
    request<T>("POST", url, { body }),
  put: <T = GeneralResponse>(url: string, body?: unknown) =>
    request<T>("PUT", url, { body }),
  delete: <T = GeneralResponse>(url: string) => request<T>("DELETE", url),
};
