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
          role: string | null
          user_id: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          role?: string | null
          user_id: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          is_active?: boolean | null
          role?: string | null
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
          logo_url: string | null
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
          logo_url?: string | null
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
          logo_url?: string | null
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
          name: Json
          sort_order: number | null
        }
        Insert: {
          branch_id: string
          created_at?: string
          id?: string
          image_url?: string | null
          name: Json
          sort_order?: number | null
        }
        Update: {
          branch_id?: string
          created_at?: string
          id?: string
          image_url?: string | null
          name?: Json
          sort_order?: number | null
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
          options: Json | null
          order_id: string
          price: number
          product_id: string | null
          quantity: number | null
        }
        Insert: {
          created_at?: string
          id?: string
          options?: Json | null
          order_id: string
          price: number
          product_id?: string | null
          quantity?: number | null
        }
        Update: {
          created_at?: string
          id?: string
          options?: Json | null
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
          customer_session_id: string | null
          id: string
          last_updated_by: string | null
          note: string | null
          status: string | null
          table_id: string
          total_amount: number | null
          updated_at: string
        }
        Insert: {
          branch_id: string
          created_at?: string
          customer_session_id?: string | null
          id?: string
          last_updated_by?: string | null
          note?: string | null
          status?: string | null
          table_id: string
          total_amount?: number | null
          updated_at?: string
        }
        Update: {
          branch_id?: string
          created_at?: string
          customer_session_id?: string | null
          id?: string
          last_updated_by?: string | null
          note?: string | null
          status?: string | null
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
            referencedRelation: "tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
      products: {
        Row: {
          allergens: Json | null
          branch_id: string
          calories: number | null
          category_id: string
          created_at: string
          description: Json | null
          id: string
          image_url: string | null
          is_available: boolean | null
          name: Json
          options: Json | null
          price: number
        }
        Insert: {
          allergens?: Json | null
          branch_id: string
          calories?: number | null
          category_id: string
          created_at?: string
          description?: Json | null
          id?: string
          image_url?: string | null
          is_available?: boolean | null
          name: Json
          options?: Json | null
          price: number
        }
        Update: {
          allergens?: Json | null
          branch_id?: string
          calories?: number | null
          category_id?: string
          created_at?: string
          description?: Json | null
          id?: string
          image_url?: string | null
          is_available?: boolean | null
          name?: Json
          options?: Json | null
          price?: number
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
          avatar_url: string | null
          city: string | null
          company_name: string | null
          country: string | null
          created_at: string
          email: string | null
          full_name: string | null
          id: string
          is_onboarded: boolean | null
          phone: string | null
          phone_verified: boolean | null
          role: string | null
          subscription_end_date: string | null
          subscription_period: string | null
          subscription_plan: string | null
          subscription_start_date: string | null
        }
        Insert: {
          address?: string | null
          avatar_url?: string | null
          city?: string | null
          company_name?: string | null
          country?: string | null
          created_at?: string
          email?: string | null
          full_name?: string | null
          id: string
          is_onboarded?: boolean | null
          phone?: string | null
          phone_verified?: boolean | null
          role?: string | null
          subscription_end_date?: string | null
          subscription_period?: string | null
          subscription_plan?: string | null
          subscription_start_date?: string | null
        }
        Update: {
          address?: string | null
          avatar_url?: string | null
          city?: string | null
          company_name?: string | null
          country?: string | null
          created_at?: string
          email?: string | null
          full_name?: string | null
          id?: string
          is_onboarded?: boolean | null
          phone?: string | null
          phone_verified?: boolean | null
          role?: string | null
          subscription_end_date?: string | null
          subscription_period?: string | null
          subscription_plan?: string | null
          subscription_start_date?: string | null
        }
        Relationships: []
      }
      qr_scans: {
        Row: {
          branch_id: string
          id: string
          scanned_at: string
          table_id: string | null
        }
        Insert: {
          branch_id: string
          id?: string
          scanned_at?: string
          table_id?: string | null
        }
        Update: {
          branch_id?: string
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
            referencedRelation: "tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
      tables: {
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
            foreignKeyName: "tables_branch_id_fkey"
            columns: ["branch_id"]
            isOneToOne: false
            referencedRelation: "branches"
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
            referencedRelation: "tables"
            referencedColumns: ["id", "branch_id"]
          },
        ]
      }
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
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
    Enums: {},
  },
} as const
