// Checkout Pro moderno (Orders API). Não armazenar tokens neste arquivo.
import {createClient} from 'https://esm.sh/@supabase/supabase-js@2'

const url=Deno.env.get('SUPABASE_URL')!
const secretKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const mpToken=Deno.env.get('MERCADOPAGO_ACCESS_TOKEN')!
const storeUrl=Deno.env.get('PUBLIC_STORE_URL')!
const allowedOrigins=(Deno.env.get('ALLOWED_ORIGINS')||storeUrl).split(',').map(s=>s.trim()).filter(Boolean)
const db=createClient(url,secretKey,{auth:{persistSession:false}})
const respond=(body:Record<string,unknown>,status=200,origin='')=>new Response(JSON.stringify(body),{status,headers:{'Content-Type':'application/json','Access-Control-Allow-Origin':allowedOrigins.includes(origin)?origin:allowedOrigins[0]||'',Vary:'Origin','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'}})
const round=(n:number)=>Math.round(n*100)/100
const integer=(n:unknown)=>Number.isInteger(n)&&Number(n)>0&&Number(n)<=50
const okUuid=(s:unknown)=>typeof s==='string'&&/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
Deno.serve(async(req)=>{
 const origin=req.headers.get('Origin')||''
 if(!allowedOrigins.includes(origin))return respond({error:'Origem não autorizada'},403,origin)
 if(req.method==='OPTIONS')return respond({},200,origin)
 if(req.method!=='POST')return respond({error:'Método não permitido'},405,origin)
 try{
  if(!mpToken||!storeUrl)throw Error('Checkout não configurado')
  // Somente compradores autenticados com e-mail verificado podem pagar online.
  const authorization=req.headers.get('Authorization')||''
  if(!authorization.startsWith('Bearer '))return respond({error:'Entre na sua conta para finalizar a compra'},401,origin)
  const jwt=authorization.slice(7)
  const {data:identity,error:authError}=await db.auth.getUser(jwt)
  const user=identity?.user
  if(authError||!user)return respond({error:'Sessão inválida. Entre novamente.'},401,origin)
  if(!user.email_confirmed_at&&!user.phone_confirmed_at)return respond({error:'Confirme seu e-mail antes de comprar'},403,origin)
  const {items,buyer}=await req.json()
  if(!Array.isArray(items)||!items.length||items.length>15||!items.every((i:{id:unknown;qty:unknown})=>okUuid(i.id)&&integer(i.qty)))throw Error('Carrinho inválido')
  const ids=new Set(items.map((i:{id:string})=>i.id))
  if(ids.size!==items.length)throw Error('Há itens repetidos no carrinho')
  const name=String(buyer?.name||'').trim(),phone=String(buyer?.phone||'').replace(/\D/g,''),email=String(buyer?.email||'').trim().toLowerCase()
  if(name.length<3||name.length>120||phone.length<10||phone.length>13||!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>254)throw Error('Dados do comprador inválidos')
  if(!user.email||email!==user.email.toLowerCase())throw Error('Use o mesmo e-mail da sua conta verificada')
  const mode=buyer?.shipping_mode==='entrega'?'entrega':'retirada'
  const zip=String(buyer?.zip_code||'').replace(/\D/g,''),address=String(buyer?.address||'').trim()
  if(mode==='entrega'&&(zip.length!==8||address.length<15||address.length>500))throw Error('Endereço de entrega inválido')
  const {data:settings,error:sErr}=await db.from('store_settings').select('checkout_enabled,shipping_enabled,shipping_flat').eq('id',1).single()
  if(sErr||!settings?.checkout_enabled)throw Error('Pagamento online indisponível')
  if(mode==='entrega'&&!settings.shipping_enabled)throw Error('Entrega online não habilitada')
  const {data:products,error:pErr}=await db.from('products').select('id,name,sale_price,stock,active').in('id',[...ids])
  if(pErr||!products||products.length!==items.length)throw Error('Um dos produtos não está mais disponível')
  let subtotal=0
  const lines=items.map((i:{id:string;qty:number})=>{
    const p=products.find(p=>p.id===i.id)
    if(!p?.active||p.stock<i.qty||p.sale_price<=0)throw Error('Produto esgotado ou indisponível')
    const unit=round(Number(p.sale_price));subtotal=round(subtotal+unit*i.qty)
    return {product_id:p.id,name_snapshot:p.name,quantity:i.qty,unit_price:unit}
  })
  const shipping=mode==='entrega'?round(Number(settings.shipping_flat)):0
  const total=round(subtotal+shipping)
  if(!Number.isFinite(total)||total<=0||total>100000)throw Error('Valor de pedido inválido')
  const {data:order,error:oErr}=await db.from('online_orders').insert({shopper_user_id:user.id,buyer_name:name,buyer_phone:phone,buyer_email:email,address:mode==='entrega'?address:null,zip_code:mode==='entrega'?zip:null,shipping_mode:mode,shipping_amount:shipping,subtotal,total,status:'aguardando_pagamento'}).select('id').single()
  if(oErr||!order)throw oErr||Error('Erro ao cadastrar pedido')
  const {error:iErr}=await db.from('online_order_items').insert(lines.map(x=>({...x,order_id:order.id})))
  if(iErr){await db.from('online_orders').update({status:'cancelado'}).eq('id',order.id);throw iErr}
  const mpItems=lines.map(x=>({title:x.name_snapshot.slice(0,250),quantity:x.quantity,unit_price:x.unit_price.toFixed(2),external_code:x.product_id}))
  if(shipping>0)mpItems.push({title:'Frete fixo',quantity:1,unit_price:shipping.toFixed(2),external_code:'frete'})
  // Não confiamos nos preços do navegador. Este total é recalculado no servidor.
  const mp=await fetch('https://api.mercadopago.com/v1/orders',{
    method:'POST',headers:{'Authorization':`Bearer ${mpToken}`,'Content-Type':'application/json','X-Idempotency-Key':order.id},
    body:JSON.stringify({type:'online',processing_mode:'manual',total_amount:total.toFixed(2),external_reference:order.id,
      payer:{email},description:`SF Semijoias | pedido ${order.id.slice(0,8)}`,items:mpItems,
      config:{online:{success_url:`${storeUrl}?resultado=sucesso`,failure_url:`${storeUrl}?resultado=falha`,pending_url:`${storeUrl}?resultado=pendente`,auto_return:'approved'}}})
  })
  const result=await mp.json()
  if(!mp.ok||!result?.checkout_url||!/^https:\/\/(www\.)?mercadopago\.(com\.br|com)(\/|$)/.test(result.checkout_url)){
    await db.from('online_orders').update({status:'cancelado'}).eq('id',order.id)
    throw Error('Não foi possível gerar o pagamento no Mercado Pago')
  }
  await db.from('online_orders').update({preference_id:String(result.id)}).eq('id',order.id)
  return respond({url:result.checkout_url,order_id:order.id},200,origin)
 }catch(e){return respond({error:e instanceof Error?e.message:'Erro no checkout'},400,origin)}
})
