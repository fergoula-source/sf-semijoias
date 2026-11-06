import {createClient} from '@supabase/supabase-js'
const url=import.meta.env.VITE_SUPABASE_URL || ''
const anon=import.meta.env.VITE_SUPABASE_ANON_KEY || ''
export const connected=Boolean(url&&anon&&url.startsWith('https://')&&!url.includes('SEU-PROJETO'))
export const supabase=connected?createClient(url,anon,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null
export const isDemo=!connected // Demonstração pública isolada: somente dados fictícios, nunca produção
export const checkoutConfigured=import.meta.env.VITE_CHECKOUT_ENABLED==='true'
