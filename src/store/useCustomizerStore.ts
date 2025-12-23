import { create } from "zustand";
import { persist } from "zustand/middleware";

const config = {
  activeDir: "ltr", // This can be ltr or rtl
  activeTheme: "BLUE_THEME", // BLUE_THEME, GREEN_THEME, AQUA_THEME, PURPLE_THEME, ORANGE_THEME
  activeLayout: "vertical", // This can be vertical or horizontal
  isLayout: "boxed", // This can be full or boxed
  isSidebarHover: false,
  isCollapse: "full-sidebar",
  isCardShadow: true,
  isMobileSidebar: false,
  isHorizontal: false,
  isBorderRadius: 10,
  sidebarWidth: 256,
  miniSidebarWidth: 75,
  topbarHeight: 64,
};

interface CustomizerState {
  activeDir: string;
  activeTheme: string;
  activeLayout: string;
  isCardShadow: boolean;
  isLayout: string;
  isBorderRadius: number;
  isCollapse: string;
  isSidebarHover: boolean;
  isMobileSidebar: boolean;
  setActiveDir: (dir: string) => void;
  setActiveTheme: (theme: string) => void;
  setActiveLayout: (layout: string) => void;
  setIsCardShadow: (shadow: boolean) => void;
  setIsLayout: (layout: string) => void;
  setIsBorderRadius: (radius: number) => void;
  setIsCollapse: (collapse: string) => void;
  setIsSidebarHover: (isHover: boolean) => void;
  setIsMobileSidebar: (isMobileSidebar: boolean) => void;
}

export const useCustomizerStore = create<CustomizerState>()(
  persist(
    (set) => ({
      activeDir: config.activeDir,
      activeTheme: config.activeTheme,
      activeLayout: config.activeLayout,
      isCardShadow: config.isCardShadow,
      isLayout: config.isLayout,
      isBorderRadius: config.isBorderRadius,
      isCollapse: config.isCollapse,
      isSidebarHover: config.isSidebarHover,
      isMobileSidebar: config.isMobileSidebar,

      setActiveDir: (dir) => {
        set({ activeDir: dir });
        document.documentElement.setAttribute("dir", dir);
      },
      setActiveTheme: (theme) => {
        set({ activeTheme: theme });
        document.documentElement.setAttribute("data-color-theme", theme);
      },
      setActiveLayout: (layout) => {
        set({ activeLayout: layout });
        document.documentElement.setAttribute("data-layout", layout);
      },
      setIsCardShadow: (shadow) => set({ isCardShadow: shadow }),
      setIsLayout: (layout) => {
        set({ isLayout: layout });
        document.documentElement.setAttribute("data-boxed-layout", layout);
      },
      setIsBorderRadius: (radius) => set({ isBorderRadius: radius }),
      setIsCollapse: (collapse) => {
        set({ isCollapse: collapse });
        document.documentElement.setAttribute("data-sidebar-type", collapse);
      },
      setIsSidebarHover: (isHover) => set({ isSidebarHover: isHover }),
      setIsMobileSidebar: (isMobileSidebar) =>
        set({ isMobileSidebar: isMobileSidebar }),
    }),
    {
      name: "customizer-storage",
    }
  )
);
