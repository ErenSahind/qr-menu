import { create } from "zustand";

interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  role: "owner" | "manager" | "waiter" | "admin";
  company_name?: string;
  avatar_url?: string;
}

interface AuthState {
  user: UserProfile | null;
  isLoading: boolean;
  setUser: (user: UserProfile | null) => void;
  setLoading: (loading: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  setUser: (user) => set({ user }),
  setLoading: (loading) => set({ isLoading: loading }),
  logout: () => set({ user: null }),
}));
