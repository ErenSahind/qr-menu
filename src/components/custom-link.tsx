"use client";

import Link from "next/link";
import { useLocale } from "next-intl";
import { ComponentProps } from "react";

type Props = ComponentProps<typeof Link>;

export function CustomLink({ href, ...props }: Props) {
  const locale = useLocale();

  const localizedHref =
    typeof href === "string" &&
    href.startsWith("/") &&
    !href.startsWith(`/${locale}`)
      ? `/${locale}${href}`
      : href;

  return <Link href={localizedHref} {...props} />;
}
