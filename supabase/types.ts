export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  public: {
    Tables: {
      branch_staff: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          is_active: boolean | null
          role: Database["public"]["Enums"]["staff_role"] | null
          user_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          role?: Database["public"]["Enums"]["staff_role"] | null
          user_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          role?: Database["public"]["Enums"]["staff_role"] | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "branch_staff_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "branch_staff_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      branches: {
        Row: {
          address: string | null
          cover_image_url: string | null
          created_at: string
          currency: string | null
          id: string
          is_ordering_enabled: boolean | null
          latitude: number | null
          longitude: number | null
          max_distance: number | null
          name: string
          owner_id: string
          phone: string | null
          slug: string
          social_media: Json | null
          working_hours: Json | null
        }
        Insert: {
          address?: string | null
          cover_image_url?: string | null
          created_at?: string
          currency?: string | null
          id?: string
          is_ordering_enabled?: boolean | null
          latitude?: number | null
          longitude?: number | null
          max_distance?: number | null
          name: string
          owner_id: string
          phone?: string | null
          slug: string
          social_media?: Json | null
          working_hours?: Json | null
        }
        Update: {
          address?: string | null
          cover_image_url?: string | null
          created_at?: string
          currency?: string | null
          id?: string
          is_ordering_enabled?: boolean | null
          latitude?: number | null
          longitude?: number | null
          max_distance?: number | null
          name?: string
          owner_id?: string
          phone?: string | null
          slug?: string
          social_media?: Json | null
          working_hours?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "branches_owner_id_fkey"
            columns: ["owner_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      categories: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          image_url: string | null
          is_active: boolean | null
          name: Json
          sort_order: number | null
          type: string | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          name: Json
          sort_order?: number | null
          type?: string | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          image_url?: string | null
          is_active?: boolean | null
          name?: Json
          sort_order?: number | null
          type?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "categories_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string
          id: string
          order_id: string
          price: number
          product_id: string | null
          quantity: number | null
        }
        Insert: {
          created_at?: string
          id?: string
          order_id: string
          price: number
          product_id?: string | null
          quantity?: number | null
        }
        Update: {
          created_at?: string
          id?: string
          order_id?: string
          price?: number
          product_id?: string | null
          quantity?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          branch_id: string
          created_at: string
          customer_session_id: string
          gps_lat: number | null
          gps_lng: number | null
          id: string
          last_updated_by: string | null
          note: string | null
          status: Database["public"]["Enums"]["order_status"] | null
          table_id: string
          total_amount: number | null
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          customer_session_id: string
          gps_lat?: number | null
          gps_lng?: number | null
          id?: string
          last_updated_by?: string | null
          note?: string | null
          status?: Database["public"]["Enums"]["order_status"] | null
          table_id: string
          total_amount?: number | null
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          customer_session_id?: string
          gps_lat?: number | null
          gps_lng?: number | null
          id?: string
          last_updated_by?: string | null
          note?: string | null
          status?: Database["public"]["Enums"]["order_status"] | null
          table_id?: string
          total_amount?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_last_updated_by_fkey"
            columns: ["last_updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "orders_table_id_branch_id_fkey"
            columns: ["table_id", "branch_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
      plan_features: {
        Row: {
          allow_images: boolean | null
          allow_ordering: boolean | null
          max_branches: number
          max_categories: number | null
          max_products: number | null
          max_staff: number | null
          plan: Database["public"]["Enums"]["subscription_plan"]
        }
        Insert: {
          allow_images?: boolean | null
          allow_ordering?: boolean | null
          max_branches: number
          max_categories?: number | null
          max_products?: number | null
          max_staff?: number | null
          plan: Database["public"]["Enums"]["subscription_plan"]
        }
        Update: {
          allow_images?: boolean | null
          allow_ordering?: boolean | null
          max_branches?: number
          max_categories?: number | null
          max_products?: number | null
          max_staff?: number | null
          plan?: Database["public"]["Enums"]["subscription_plan"]
        }
        Relationships: []
      }
      products: {
        Row: {
          allergens: string[] | null
          badges: string[] | null
          branch_id: string
          calories: number | null
          category_id: string
          created_at: string
          description: Json | null
          id: string
          image_url: string | null
          ingredients: Json | null
          is_active: boolean | null
          is_available: boolean | null
          name: Json
          price: number
          sort_order: number | null
        }
        Insert: {
          allergens?: string[] | null
          badges?: string[] | null
          branch_id: string
          calories?: number | null
          category_id: string
          created_at?: string
          description?: Json | null
          id?: string
          image_url?: string | null
          ingredients?: Json | null
          is_active?: boolean | null
          is_available?: boolean | null
          name: Json
          price: number
          sort_order?: number | null
        }
        Update: {
          allergens?: string[] | null
          badges?: string[] | null
          branch_id?: string
          calories?: number | null
          category_id?: string
          created_at?: string
          description?: Json | null
          id?: string
          image_url?: string | null
          ingredients?: Json | null
          is_active?: boolean | null
          is_available?: boolean | null
          name?: Json
          price?: number
          sort_order?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "products_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          address: string | null
          city: string | null
          company_name: string | null
          country: string | null
          created_at: string
          full_name: string | null
          id: string
          is_onboarded: boolean | null
          logo_url: string | null
          phone: string | null
          phone_verified: boolean | null
          purchased_branch_limit: number | null
          role: Database["public"]["Enums"]["user_role"] | null
          subscription_ends_at: string | null
          subscription_plan:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          subscription_started_at: string | null
          subscription_status:
            | Database["public"]["Enums"]["subscription_status"]
            | null
        }
        Insert: {
          address?: string | null
          city?: string | null
          company_name?: string | null
          country?: string | null
          created_at?: string
          full_name?: string | null
          id: string
          is_onboarded?: boolean | null
          logo_url?: string | null
          phone?: string | null
          phone_verified?: boolean | null
          purchased_branch_limit?: number | null
          role?: Database["public"]["Enums"]["user_role"] | null
          subscription_ends_at?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          subscription_started_at?: string | null
          subscription_status?:
            | Database["public"]["Enums"]["subscription_status"]
            | null
        }
        Update: {
          address?: string | null
          city?: string | null
          company_name?: string | null
          country?: string | null
          created_at?: string
          full_name?: string | null
          id?: string
          is_onboarded?: boolean | null
          logo_url?: string | null
          phone?: string | null
          phone_verified?: boolean | null
          purchased_branch_limit?: number | null
          role?: Database["public"]["Enums"]["user_role"] | null
          subscription_ends_at?: string | null
          subscription_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          subscription_started_at?: string | null
          subscription_status?:
            | Database["public"]["Enums"]["subscription_status"]
            | null
        }
        Relationships: []
      }
      qr_scans: {
        Row: {
          branch_id: string
          customer_session_id: string | null
          id: string
          scanned_at: string
          table_id: string | null
        }
        Insert: {
          branch_id: string
          customer_session_id?: string | null
          id?: string
          scanned_at?: string
          table_id?: string | null
        }
        Update: {
          branch_id?: string
          customer_session_id?: string | null
          id?: string
          scanned_at?: string
          table_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "qr_scans_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "qr_scans_table_id_branch_id_fkey"
            columns: ["table_id", "branch_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
      restaurant_tables: {
        Row: {
          branch_id: string
          created_at: string
          id: string
          name: string
          qr_code: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          name: string
          qr_code: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          name?: string
          qr_code?: string
        }
        Relationships: [
          {
            foreignKeyName: "restaurant_tables_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
        ]
      }
      system_settings: {
        Row: {
          currency: string | null
          default_signup_plan:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          default_trial_days: number | null
          extra_branch_prices: Json | null
          id: number
          maintenance_mode: boolean | null
          plan_prices: Json | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          currency?: string | null
          default_signup_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          default_trial_days?: number | null
          extra_branch_prices?: Json | null
          id?: number
          maintenance_mode?: boolean | null
          plan_prices?: Json | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          currency?: string | null
          default_signup_plan?:
            | Database["public"]["Enums"]["subscription_plan"]
            | null
          default_trial_days?: number | null
          extra_branch_prices?: Json | null
          id?: number
          maintenance_mode?: boolean | null
          plan_prices?: Json | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "system_settings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      branch_analytics_daily: {
        Row: {
          branch_id: string | null
          cancelled_orders: number | null
          completed_orders: number | null
          qr_scan_count: number | null
          report_date: string | null
          total_revenue: number | null
        }
        Relationships: []
      }
      pricing_settings: {
        Row: {
          currency: string | null
          extra_branch_prices: Json | null
          plan_prices: Json | null
        }
        Insert: {
          currency?: string | null
          extra_branch_prices?: Json | null
          plan_prices?: Json | null
        }
        Update: {
          currency?: string | null
          extra_branch_prices?: Json | null
          plan_prices?: Json | null
        }
        Relationships: []
      }
      table_analytics_daily: {
        Row: {
          branch_id: string | null
          report_date: string | null
          scan_count: number | null
          table_id: string | null
          table_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "qr_scans_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "qr_scans_table_id_branch_id_fkey"
            columns: ["table_id", "branch_id"]
            isOneToOne: false
            referencedRelation: "restaurant_tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
    }
    Functions: {
      slugify: { Args: { value: string }; Returns: string }
    }
    Enums: {
      order_status:
        | "pending"
        | "preparing"
        | "served"
        | "completed"
        | "cancelled"
      staff_role: "manager" | "waiter" | "kitchen"
      subscription_plan: "free" | "premium" | "ultimate" | "enterprise"
      subscription_status:
        | "inactive"
        | "trialing"
        | "active"
        | "past_due"
        | "canceled"
      user_role: "admin" | "owner" | "staff"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      order_status: [
        "pending",
        "preparing",
        "served",
        "completed",
        "cancelled",
      ],
      staff_role: ["manager", "waiter", "kitchen"],
      subscription_plan: ["free", "premium", "ultimate", "enterprise"],
      subscription_status: [
        "inactive",
        "trialing",
        "active",
        "past_due",
        "canceled",
      ],
      user_role: ["admin", "owner", "staff"],
    },
  },
} as const
