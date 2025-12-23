"use client";

import { useState } from "react";
import { useRouter, useParams } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import {
  Button,
  Typography,
  Box,
  Grid,
  Avatar,
  Divider,
  Stack,
  FormGroup,
  FormControlLabel,
  styled,
} from "@mui/material";
import { useCustomizerStore } from "@/store/useCustomizerStore";
import { IconMail, IconPassword } from "@tabler/icons-react";
import CustomInput from "@/components/Form/CustomInput";
import { MyFormContainer } from "@/components/Form/MyFormContainer";
import { useForm } from "react-hook-form";
import CustomCheckbox from "@/components/Form/CustomCheckbox";
import DarkLightMode from "@/components/Theme/DarkLightMode";
import { useTranslations } from "next-intl";
import { useTheme } from "next-themes";

export default function LoginPage() {
  const router = useRouter();
  const { resolvedTheme, setTheme } = useTheme();
  const t = useTranslations("Login");
  const isCollapse = useCustomizerStore((state) => state.isCollapse);
  const isSidebarHover = useCustomizerStore((state) => state.isSidebarHover);

  const methods = useForm({
    defaultValues: {
      email: "",
      password: "",
    },
    mode: "all",
  });

  const onSubmitHandler = async (data: FormData) => {
    try {
    } catch (error) {}
  };

  const LinkStyled = styled(Link)(() => ({
    height: "64px",
    width: isCollapse == "mini-sidebar" && !isSidebarHover ? "40px" : "180px",
    overflow: "hidden",
    display: "block",
  }));
  return (
    <Grid
      container
      spacing={0}
      justifyContent="center"
      sx={{
        height: "100vh",
        backgroundColor: "white",
        "html.dark &": {
          backgroundColor: "#1c222e",
        },
      }}
    >
      <Grid
        size={{
          xs: 12,
          sm: 12,
          lg: 3,
          xl: 4,
        }}
        height={1}
      >
        <Box px={3} sx={{ display: "flex", justifyContent: "space-between" }}>
          <LinkStyled
            href="/"
            style={{
              display: "flex",
              alignItems: "center",
            }}
          >
            <Box
              component="span"
              sx={{
                display: "block",
                "html.dark &": { display: "none" },
              }}
            >
              <Image
                src="/images/logos/dark-logo.svg"
                alt="logo"
                width={174}
                height={64}
                priority
              />
            </Box>
            <Box
              component="span"
              sx={{
                display: "none",
                "html.dark &": { display: "block" },
              }}
            >
              <Image
                src="/images/logos/light-logo.svg"
                alt="logo"
                width={174}
                height={64}
                priority
              />
            </Box>
          </LinkStyled>
          <DarkLightMode />
        </Box>
        <Grid
          container
          justifyContent="center"
          alignItems="center"
          height="calc(100% - 64px)"
        >
          <Grid
            size={{
              xs: 12,
              lg: 8,
            }}
          >
            <Box display="flex" flexDirection="column">
              <Box p={4}>
                <MyFormContainer
                  methods={methods}
                  onSubmitHandler={onSubmitHandler}
                >
                  <Typography
                    fontWeight="700"
                    variant="h3"
                    mb={1}
                    textAlign="center"
                  >
                    Welcome to X
                  </Typography>
                  <Typography
                    variant="subtitle1"
                    color="textSecondary"
                    mb={1}
                    textAlign="center"
                  >
                    Your personal QR Menu system.
                  </Typography>
                  {/* <AuthSocialButtons /> */}
                  {/* <Box mt={3}>
                    <Divider>
                      <Typography
                        component="span"
                        variant="h6"
                        fontWeight="400"
                        position="relative"
                        px={2}
                      >
                        or sign in with
                      </Typography>
                    </Divider>
                  </Box> */}
                  <Stack>
                    <CustomInput
                      name="email"
                      label="Email Address"
                      fullWidth
                      icon={<IconMail width={20} />}
                    />

                    <CustomInput
                      name="password"
                      label="Password"
                      type="password"
                      fullWidth
                      icon={<IconPassword width={20} />}
                    />
                    <Stack
                      justifyContent="space-between"
                      direction="row"
                      alignItems="center"
                      my={2}
                    >
                      <FormGroup>
                        <FormControlLabel
                          control={<CustomCheckbox defaultChecked />}
                          label="Remeber this Device"
                        />
                      </FormGroup>
                      <Typography
                        component={Link}
                        href="/forgot-password"
                        fontWeight="500"
                        sx={{
                          textDecoration: "none",
                          color: "primary.main",
                        }}
                      >
                        Forgot Password ?
                      </Typography>
                    </Stack>
                  </Stack>
                  <Box>
                    <Button
                      color="primary"
                      variant="contained"
                      size="large"
                      fullWidth
                      type="submit"
                    >
                      {t("title")}
                    </Button>
                  </Box>
                </MyFormContainer>
              </Box>
            </Box>
          </Grid>
        </Grid>
      </Grid>
      <Grid
        sx={{
          position: "relative",
          "&:before": {
            content: '""',
            background: "radial-gradient(#d2f1df,#d3d7fa,#bad8f4)",
            backgroundSize: "400% 400%",
            animation: "gradient 15s ease infinite",
            position: "absolute",
            height: "100%",
            width: "100%",
            opacity: "0.3",
          },
        }}
        size={{
          xs: 12,
          sm: 12,
          lg: 9,
          xl: 8,
        }}
      >
        <Box position="relative">
          <Box
            alignItems="center"
            justifyContent="center"
            height={"calc(100vh - 75px)"}
            sx={{
              display: {
                xs: "none",
                lg: "flex",
              },
            }}
          >
            <Avatar
              src="/images/backgrounds/user-login.png"
              alt="bg"
              sx={{
                borderRadius: 0,
                width: "100%",
                height: "100%",
                maxWidth: "676px",
                maxHeight: "450px",
              }}
            />
          </Box>
        </Box>
      </Grid>
    </Grid>
  );
}
