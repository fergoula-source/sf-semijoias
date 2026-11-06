/// <reference types="vite/client" />
interface ImportMetaEnv {
  readonly BASE_URL: string
  readonly DEV: boolean
  readonly VITE_SUPABASE_URL?: string
  readonly VITE_SUPABASE_ANON_KEY?: string
  readonly VITE_CHECKOUT_ENABLED?: string
  readonly VITE_ADMIN_FGOULART_EMAIL?: string
  readonly VITE_ADMIN_SFELICE_EMAIL?: string
}
interface ImportMeta { readonly env: ImportMetaEnv }
