"use client";

import * as React from "react";
import { useFormContext, Controller } from "react-hook-form";

import { cn } from "@/lib/utils";
import { Label } from "@/components/ui/label";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group";

interface FormInputProps extends React.ComponentProps<"input"> {
  name: string;
  label?: string;
  startAdornment?: React.ReactNode;
  endAdornment?: React.ReactNode;
}

export function FormInput({
  name,
  label,
  startAdornment,
  endAdornment,
  className,
  id,
  ...props
}: FormInputProps) {
  const { control } = useFormContext();

  return (
    <Controller
      control={control}
      name={name}
      render={({
        field,
        fieldState: { error, isTouched },
        formState: { isSubmitted },
      }) => {
        const showError = !!error && (isTouched || isSubmitted);
        const inputId = id || name;

        return (
          <div className="space-y-2">
            {label && (
              <Label
                htmlFor={inputId}
                className={cn(showError && "text-destructive")}
              >
                {label}
              </Label>
            )}
            <InputGroup
              className={cn(
                showError && "border-destructive ring-destructive/20",
                showError &&
                  "has-[[data-slot=input-group-control]:focus-visible]:ring-destructive"
              )}
            >
              {startAdornment && (
                <InputGroupAddon>
                  {showError && React.isValidElement(startAdornment)
                    ? React.cloneElement(
                        startAdornment as React.ReactElement<any>,
                        {
                          className: cn(
                            (startAdornment.props as any).className,
                            "text-destructive"
                          ),
                        }
                      )
                    : startAdornment}
                </InputGroupAddon>
              )}
              <InputGroupInput
                id={inputId}
                className={cn(className)}
                aria-invalid={showError}
                {...props}
                {...field}
              />
              {endAdornment && (
                <InputGroupAddon align={"inline-end"}>
                  {showError && React.isValidElement(endAdornment)
                    ? React.cloneElement(
                        endAdornment as React.ReactElement<any>,
                        {
                          className: cn(
                            (endAdornment.props as any).className,
                            "text-destructive"
                          ),
                        }
                      )
                    : endAdornment}
                </InputGroupAddon>
              )}
            </InputGroup>
            {showError && (
              <p className="text-sm font-medium text-destructive">
                {error.message as string}
              </p>
            )}
          </div>
        );
      }}
    />
  );
}
