"use client";

import React, { useEffect, useState } from "react";
import { IconButton, Box } from "@mui/material";
import { IconMoon, IconSun } from "@tabler/icons-react";
import { useTheme } from "next-themes";

const DarkLightMode = () => {
  const { resolvedTheme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const toggleMode = () => {
    const newMode = resolvedTheme === "light" ? "dark" : "light";
    setTheme(newMode);
    console.log("Theme changed to:", newMode);
  };

  if (!mounted) {
    return (
      <Box>
        <IconButton aria-label="theme-toggle" color="inherit" size="large">
          <IconMoon size={20} />
        </IconButton>
      </Box>
    );
  }

  return (
    <Box>
      <IconButton
        aria-label="theme-toggle"
        color="inherit"
        onClick={toggleMode}
        size="large"
      >
        {resolvedTheme === "light" ? (
          <IconMoon size={20} />
        ) : (
          <IconSun size={20} />
        )}
      </IconButton>
    </Box>
  );
};

export default DarkLightMode;
