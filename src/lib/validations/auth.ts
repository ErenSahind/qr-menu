import { z } from "zod";

export const createLoginSchema = (t: (key: string) => string) =>
  z.object({
    email: z.string().email({
      message: t("email_required"),
    }),
    password: z.string().min(6, {
      message: t("password_min"),
    }),
  });

export type LoginSchema = z.infer<ReturnType<typeof createLoginSchema>>;

export const createRegisterSchema = (t: (key: string) => string) =>
  z
    .object({
      full_name: z.string().min(2, {
        message: t("full_name_required"),
      }),
      email: z.string().email({
        message: t("email_required"),
      }),
      password: z.string().min(6, {
        message: t("password_min"),
      }),
      confirmPassword: z.string(),
    })
    .refine((data) => data.password === data.confirmPassword, {
      message: t("password_mismatch"),
      path: ["confirmPassword"],
    });

export type RegisterSchema = z.infer<ReturnType<typeof createRegisterSchema>>;
