// Notificação Orders API: validar HMAC, CONSULTAR order no MP e processar uma única vez.
import {createClient} from 'https://esm.sh/@supabase/supabase-js@2'
const db=createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false}})
const mpToken=Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')!
const signingKey=Deno.env.get('MERCADOPAGO_WEBHOOK_SECRET')!
const plain=(message:string,status=200)=>new Response(message,{status})
const hex=(a:Uint8Array)=>[...a].map(x=>x.toString(16).padStart(2,'0')).join('')
async function verify(signature:string,requestId:string,dataId:string){
 const match=Object.fromEntries(signature.split(',').map(x=>x.trim().split('=')))
 if(!match.ts||!match.v1||!/^[0-9a-f]{64}$/i.test(match.v1)||!/^\d+$/.test(match.ts)||Math.abs(Date.now()-Number(match.ts))>300000)return false
 // MP assina template: id:[data.id];request-id:[x-request-id];ts:[ts];
 const template=`id:${dataId.toLowerCase()};request-id:${requestId};ts:${match.ts};`
 const key=await crypto.subtle.importKey('raw',new TextEncoder().encode(signingKey),{name:'HMAC',hash:'SHA-256'},false,['sign'])
 const hmac=hex(new Uint8Array(await crypto.subtle.sign('HMAC',key,new TextEncoder().encode(template))))
 let diff=0;for(let i=0;i<hmac.length;i++)diff|=hmac.charCodeAt(i)^match.v1.toLowerCase().charCodeAt(i)
 return diff===0
}
Deno.serve(async(req)=>{
 if(req.method!=='POST')return plain('Método não permitido',405)
 if(!mpToken||!signingKey)return plain('Webhook não configurado',503)
 let payload:{data?:{id?:string};type?:string}
 try{payload=await req.json()}catch{return plain('JSON inválido',400)}
 if(payload.type!=='order')return plain('Evento ignorado')
 const url=new URL(req.url)
 const id=url.searchParams.get('data.id')||url.searchParams.get('data_id')||''
 const sig=req.headers.get('x-signature')||''
 const rid=req.headers.get('x-request-id')||''
 if(!id||!rid||!sig||id.toLowerCase()!==payload.data?.id?.toLowerCase()||!await verify(sig,rid,id))return plain('Assinatura inválida',401)
 try{
  // O corpo do webhook NÃO determina pagamento; consultar API oficial com token secreto.
  const response=await fetch(`https://api.mercadopago.com/v1/orders/${encodeURIComponent(id)}`,{headers:{Authorization:`Bearer ${mpToken}`}})
  if(!response.ok)return plain('Falha ao consultar order',503)
  const mp=await response.json()
  if(mp.id!==id||mp.status!=='processed'||mp.status_detail!=='accredited')return plain('Pagamento não confirmado')
  if(mp.currency!=='BRL'||!mp.external_reference||!Number.isFinite(Number(mp.total_paid_amount)))return plain('Dados de pagamento inesperados',422)
  const {data:local,error:e}=await db.from('online_orders').select('id,total,preference_id,status').eq('id',mp.external_reference).maybeSingle()
  if(e||!local||local.preference_id!==id)return plain('Pedido não encontrado ou referência divergente',422)
  if(Math.round(Number(local.total)*100)!==Math.round(Number(mp.total_paid_amount)*100))return plain('Pagamento diverge do pedido',422)
  const {data,error}=await db.rpc('finalize_online_order',{p_order_id:local.id,p_payment_id:id,p_amount:Number(mp.total_paid_amount)})
  if(error)return plain('Falha ao registrar pedido',503)
  return plain(`OK: ${data}`)
 }catch{return plain('Falha temporária',503)}
})
