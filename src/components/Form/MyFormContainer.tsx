import React from "react";
import { UseFormReturn, FieldErrors, FormProvider } from "react-hook-form";

interface FormContainerProps {
  children: React.ReactNode;
  methods: UseFormReturn<any>;
  onSubmitHandler: (data: any) => void;
  maxWidth?: number | string;
  extraButton?: any;
  isActiveButton?: boolean;
  saveButtonLabel?: string;
  loadingEffect?: boolean;
}

export const MyFormContainer = ({
  children,
  methods,
  onSubmitHandler,
}: FormContainerProps) => {
  const { handleSubmit } = methods;

  const onInvalid = (errors: FieldErrors) => {
    const firstErrorFieldName = Object.keys(errors)[0];
    // Hata alan ilk inputa scroll yap
    const errorElement = document.querySelector(
      `[name="${firstErrorFieldName}"]`
    );
    if (errorElement) {
      errorElement.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  };

  return (
    <FormProvider {...methods}>
      <form
        noValidate
        onSubmit={handleSubmit(onSubmitHandler, onInvalid)}
        style={{ width: "100%" }}
      >
        {children}
      </form>
    </FormProvider>
  );
};
