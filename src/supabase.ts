import {createClient} from '@supabase/supabase-js'
const url=import.meta.env.VITE_SUPABASE_URL || ''
const anon=import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || import.meta.env.VITE_SUPABASE_ANON_KEY || ''
export const connected=Boolean(url&&anon&&url.startsWith('https://')&&!url.includes('SEU-PROJETO'))
export const supabase=connected?createClient(url,anon,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null
// Demonstração permitida somente no desenvolvimento local; nunca em hospedagem pública.
export const isDemo=!connected && import.meta.env.DEV && ['localhost','127.0.0.1'].includes(window.location.hostname)
export const checkoutConfigured=import.meta.env.VITE_CHECKOUT_ENABLED==='true'
