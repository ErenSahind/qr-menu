import { defineRouting } from "next-intl/routing";

export const locales = ["tr", "en"] as const;
export type Locale = (typeof locales)[number];

export const routing = defineRouting({
  locales,
  defaultLocale: "tr",
  localePrefix: "always",

  // Lokalize pathnames - her dil kendi dilinde URL kullanır
  pathnames: {
    "/": "/",

    // Değer Kaybı Hesaplama - SEO için önemli sayfa
    "/deger-kaybi-hesaplama": {
      tr: "/deger-kaybi-hesaplama",
      en: "/depreciation-calculator",
    },
  },
});
