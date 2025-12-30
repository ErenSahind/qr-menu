// lib/api/http.ts
type HttpMethod = "GET" | "POST" | "PUT" | "DELETE";

interface RequestOptions {
  body?: unknown;
  headers?: HeadersInit;
}

async function request<T>(
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

  return data;
}

export const http = {
  get: <T>(url: string) => request<T>("GET", url),
  post: <T>(url: string, body?: unknown) => request<T>("POST", url, { body }),
  put: <T>(url: string, body?: unknown) => request<T>("PUT", url, { body }),
  delete: <T>(url: string) => request<T>("DELETE", url),
};
