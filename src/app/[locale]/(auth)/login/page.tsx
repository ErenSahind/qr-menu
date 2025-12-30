"use client";

import { useState } from "react";
import Image from "next/image";
import { useForm, FormProvider } from "react-hook-form";
import { useTranslations } from "next-intl";
import { zodResolver } from "@hookform/resolvers/zod";
import { Mail, Lock, Eye, EyeOff, Loader2 } from "lucide-react";

import { CustomLink } from "@/components/custom-link";
import { Button } from "@/components/ui/button";
import { FormInput } from "@/components/form/form-input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { ThemeToggle } from "@/components/theme-toggle";
import { createLoginSchema, type LoginSchema } from "@/lib/validations/auth";
import { http } from "@/lib/api/http";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { CurrentUser } from "@/app/api/login/route";

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const t = useTranslations("Login");
  const tValidations = useTranslations("Validations");
  const router = useRouter();
  const loginSchema = createLoginSchema(tValidations);

  const methods = useForm<LoginSchema>({
    defaultValues: {
      email: "",
      password: "",
    },
    resolver: zodResolver(loginSchema),
    mode: "all",
  });
  const {
    handleSubmit,
    formState: { isSubmitting },
  } = methods;

  const onSubmit = async (data: LoginSchema) => {
    try {
      const response = await http.post("/api/login", data);
      const user = response.user as CurrentUser;
      toast.success(t("login_success"), {
        description: t("welcome_back", { name: user.full_name.split(" ")[0] }),
      });
      console.log(response);
      router.push("/dashboard");
    } catch (err: any) {
      toast.error(t("login_failed"));
    }
  };

  return (
    <div className="flex min-h-screen w-full bg-background text-foreground">
      {/* Left Side - Form */}
      <div className="flex w-full flex-col justify-between p-8 lg:w-1/3 lg:px-12 xl:w-3/7">
        <div className="flex items-center justify-between">
          <CustomLink href="/" className="flex items-center gap-2">
            <div className="block dark:hidden">
              <Image
                src="/images/logos/dark-logo.svg"
                alt="logo"
                width={174}
                height={64}
                priority
              />
            </div>
            <div className="hidden dark:block">
              <Image
                src="/images/logos/light-logo.svg"
                alt="logo"
                width={174}
                height={64}
                priority
              />
            </div>
          </CustomLink>
          <ThemeToggle />
        </div>

        <div className="flex flex-1 flex-col xl:px-20 justify-center space-y-6">
          <div className="text-center">
            <h1 className="text-3xl font-bold tracking-tight">
              {t("welcome_title")}
            </h1>
            <p className="text-muted-foreground">{t("welcome_subtitle")}</p>
          </div>

          <FormProvider {...methods}>
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <FormInput
                name="email"
                label={t("email_label")}
                startAdornment={<Mail />}
                placeholder={t("email_placeholder")}
              />

              <FormInput
                name="password"
                label={t("password_label")}
                type={showPassword ? "text" : "password"}
                startAdornment={<Lock />}
                endAdornment={
                  <Button
                    variant={"ghost"}
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </Button>
                }
              />

              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <Checkbox id="remember" />
                  <Label htmlFor="remember" className="text-sm font-normal">
                    {t("remember_me")}
                  </Label>
                </div>
              </div>

              <Button
                type="submit"
                className="w-full"
                size="lg"
                disabled={isSubmitting}
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    {t("title")}
                  </>
                ) : (
                  t("title")
                )}
              </Button>

              <div className="relative py-2">
                <div className="absolute inset-0 flex items-center">
                  <span className="w-full border-t" />
                </div>
                <div className="relative flex justify-center text-xs uppercase">
                  <span className="bg-background px-2 text-muted-foreground">
                    {t("or")}
                  </span>
                </div>
              </div>
              <div className="text-center">
                <CustomLink
                  href="/login"
                  className="text-sm font-medium text-primary hover:underline"
                >
                  {t("forgot_password")}
                </CustomLink>
              </div>
              <div className="text-center text-sm">
                <span className="text-muted-foreground">
                  {t("no_account")}{" "}
                </span>
                <CustomLink
                  href="/register"
                  className="font-medium text-primary hover:underline"
                >
                  {t("register")}
                </CustomLink>
              </div>
            </form>
          </FormProvider>
        </div>
      </div>

      {/* Right Side - Image */}
      <div className="relative hidden w-full lg:block lg:w-2/3 xl:w-4/7">
        <div className="absolute inset-0 bg-gradient-to-br from-[#d2f1df] via-[#d3d7fa] to-[#bad8f4] opacity-30 animate-gradient" />
        <div className="flex h-full items-center justify-center">
          <div className="relative h-[450px] w-[676px]">
            <Image
              src="/images/backgrounds/user-login.png"
              alt="Login Background"
              fill
              className="object-contain"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
