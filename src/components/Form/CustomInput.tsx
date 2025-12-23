"use client";

import React from "react";
import {
  InputAdornment,
  OutlinedInputProps,
  FormHelperText,
} from "@mui/material";
import { Controller, useFormContext } from "react-hook-form";
import CustomFormLabel from "./CustomFormLabel";
import CustomTextField from "./CustomTextField";

interface CustomInputProps extends OutlinedInputProps {
  name: string;
  label?: string;
  icon?: React.ReactNode;
  helperText?: string;
}

const CustomInput: React.FC<CustomInputProps> = ({
  name,
  label,
  icon,
  helperText,
  autoComplete,
  ...props
}) => {
  const { control } = useFormContext();

  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState }) => (
        <>
          {label && <CustomFormLabel htmlFor={name}>{label}</CustomFormLabel>}
          <CustomTextField
            {...field}
            {...props}
            error={!!fieldState.error}
            autoComplete={autoComplete}
            startAdornment={
              icon ? (
                <InputAdornment position="start">{icon}</InputAdornment>
              ) : (
                props.startAdornment
              )
            }
          />
          {(!!fieldState.error || helperText) && (
            <FormHelperText sx={{ px: 1 }} error={!!fieldState.error}>
              {fieldState.error?.message || helperText}
            </FormHelperText>
          )}
        </>
      )}
    />
  );
};

export default CustomInput;
