-- SF Semijoias - execute uma vez no SQL Editor de um projeto Supabase NOVO.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Administradora',
  created_at timestamptz not null default now()
);
create or replace function public.is_admin() returns boolean language sql stable security definer
set search_path = '' as $$
  select exists(select 1 from public.admin_users a where a.user_id = (select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create table public.categories (
 id uuid primary key default gen_random_uuid(), name text not null unique check(length(trim(name)) between 2 and 80),
 enabled boolean not null default true, sort_order integer not null default 0
);
create table public.products (
 id uuid primary key default gen_random_uuid(), name text not null check(length(trim(name)) between 2 and 160),
 sku text, description text, category_id uuid references public.categories(id) on delete set null,
 cost_price numeric(12,2) not null default 0 check(cost_price>=0),
 sale_price numeric(12,2) not null default 0 check(sale_price>=0),
 stock integer not null default 0 check(stock>=0), min_stock integer not null default 2 check(min_stock>=0),
 photo_urls text[] not null default '{}', active boolean not null default true, supplier text,
 created_at timestamptz not null default now()
);
create index products_category_idx on public.products(category_id);
create table public.customers (
 id uuid primary key default gen_random_uuid(), name text not null check(length(trim(name))>=2),
 phone text, email text, notes text, created_at timestamptz not null default now()
);
create table public.sales (
 id uuid primary key default gen_random_uuid(), customer_id uuid references public.customers(id) on delete set null,
 origin text not null default 'balcao' check(origin in ('balcao','online')),
 status text not null default 'concluida', subtotal numeric(12,2) not null default 0,
 discount numeric(12,2) not null default 0, total numeric(12,2) not null default 0,
 payment_method text not null default 'pix', installments integer not null default 1 check(installments between 1 and 24),
 notes text, stock_applied boolean not null default false, created_at timestamptz not null default now()
);
create table public.sale_items (
 id uuid primary key default gen_random_uuid(), sale_id uuid not null references public.sales(id) on delete cascade,
 product_id uuid references public.products(id) on delete set null,
 name_snapshot text not null, quantity integer not null check(quantity>0),
 unit_price numeric(12,2) not null, unit_cost numeric(12,2) not null
);
create table public.receivables (
 id uuid primary key default gen_random_uuid(), sale_id uuid not null references public.sales(id) on delete cascade,
 customer_id uuid references public.customers(id) on delete set null,
 amount numeric(12,2) not null check(amount>=0), paid_amount numeric(12,2) not null default 0 check(paid_amount>=0 and paid_amount<=amount),
 due_date date not null, installment_number integer not null default 1,
 status text not null default 'pendente' check(status in ('pendente','pago','cancelado')),
 created_at timestamptz not null default now()
);
create index receivables_due_idx on public.receivables(due_date);
create table public.cash_entries (
 id uuid primary key default gen_random_uuid(), kind text not null check(kind in ('entrada','saida')),
 category text not null, description text not null, amount numeric(12,2) not null check(amount>0),
 occurred_at timestamptz not null default now(),
 sale_id uuid references public.sales(id) on delete set null,
 receivable_id uuid references public.receivables(id) on delete set null
);
create table public.stock_movements (
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 kind text not null check(kind in ('compra','ajuste')),
 quantity integer not null, unit_cost numeric(12,2), notes text, created_at timestamptz not null default now()
);
create table public.store_settings (
 id smallint primary key default 1 check(id=1),
 store_name text not null default 'SF Semijoias', tagline text not null default 'Escolha brilhar. Sempre.',
 about_text text not null default '', whatsapp text not null default '5555991391527',
 whatsapp_second text not null default '5555991158282', instagram text not null default 'sinara.felice',
 hero_title text not null default 'O brilho que combina com você.', hero_subtitle text not null default '',
 shipping_enabled boolean not null default false, shipping_flat numeric(12,2) not null default 0 check(shipping_flat>=0),
 checkout_enabled boolean not null default false,
 shipping_policy text not null default 'Consulte as opções de retirada e entrega antes de confirmar o pedido. Os prazos e a cobertura de transporte devem ser confirmados com nossa equipe.',
 return_policy text not null default 'Compras pela internet têm direito de arrependimento no prazo legal de 7 dias após recebimento. Solicite atendimento pelo WhatsApp da loja.',
 privacy_policy text not null default 'Os dados de contato e entrega são utilizados no processamento de pedidos. Pagamentos são processados pelo Mercado Pago, com dados de pedidos guardados no Supabase. Entre em contato para informações e solicitações sobre dados pessoais.',
 business_info text not null default ''
);
insert into public.store_settings(id,about_text,hero_subtitle) values
 (1,'Sou Sinara, apaixonada por semijoias, moda e pela alegria de ajudar cada mulher a encontrar peças que combinam com sua essência. A SF Semijoias nasceu de um sonho que hoje estou transformando em realidade, com carinho, dedicação e vontade de crescer. Cada escolha aqui é feita pensando em você.','Semijoias, moda e detalhes escolhidos com carinho para acompanhar seus melhores momentos.')
on conflict (id) do nothing;
create table public.online_orders (
 id uuid primary key default gen_random_uuid(), buyer_name text not null, buyer_phone text not null,
 buyer_email text not null, address text, zip_code text, shipping_mode text not null check(shipping_mode in ('retirada','entrega')),
 shipping_amount numeric(12,2) not null default 0, subtotal numeric(12,2) not null,
 total numeric(12,2) not null, status text not null default 'aguardando_pagamento'
 check(status in ('aguardando_pagamento','pago','revisao_estoque','cancelado')),
 payment_id text unique, preference_id text, created_at timestamptz not null default now()
);
create table public.online_order_items (
 id uuid primary key default gen_random_uuid(), order_id uuid not null references public.online_orders(id) on delete cascade,
 product_id uuid not null references public.products(id), name_snapshot text not null,
 quantity integer not null check(quantity>0), unit_price numeric(12,2) not null check(unit_price>=0)
);

-- Proteção real: tabela de produtos (incluindo custo e fornecedor) é privada.
-- O visitante enxerga somente as colunas da view catalog_products.
create view public.catalog_products with (security_invoker=false) as
select id,name,sku,description,category_id,sale_price,stock,min_stock,photo_urls,active,created_at
from public.products where active=true;

-- RLS em todas as tabelas. Somente os dois UUIDs colocados em admin_users terão acesso privado.
do $$ declare t text; begin
 foreach t in array array['admin_users','categories','products','customers','sales','sale_items','receivables','cash_entries','stock_movements','store_settings','online_orders','online_order_items'] loop
  execute format('alter table public.%I enable row level security',t);
 end loop;
end $$;
create policy admin_self on public.admin_users for select to authenticated using (user_id=(select auth.uid()));
create policy admin_all_categories on public.categories for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy categories_public on public.categories for select to anon, authenticated using (enabled);
create policy admin_all_products on public.products for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_customers on public.customers for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_sales on public.sales for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_sale_items on public.sale_items for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_receivables on public.receivables for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_cash_entries on public.cash_entries for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_stock_movements on public.stock_movements for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_store_settings on public.store_settings for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy settings_public on public.store_settings for select to anon, authenticated using (true);
create policy admin_all_online_orders on public.online_orders for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));
create policy admin_all_online_order_items on public.online_order_items for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()));

-- Permissões: nenhuma escrita pública nas tabelas; views para o catálogo.
revoke all on public.admin_users,public.products,public.customers,public.sales,public.sale_items,public.receivables,public.cash_entries,public.stock_movements,public.online_orders,public.online_order_items from anon;
grant select on public.catalog_products,public.categories,public.store_settings to anon,authenticated;
-- Nunca conceder DML na VIEW pública: views com security_invoker=false podem
-- contornar a RLS da tabela de origem se forem atualizáveis.
grant select,insert,update,delete on
  public.admin_users,public.categories,public.products,public.customers,public.sales,
  public.sale_items,public.receivables,public.cash_entries,public.stock_movements,
  public.store_settings,public.online_orders,public.online_order_items
  to authenticated;
revoke insert,update,delete on public.catalog_products from public,anon,authenticated;
-- remove permissões automáticas indevidas do PUBLIC para funções internas abaixo.

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('product-images','product-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy product_images_public_read on storage.objects for select to public using(bucket_id='product-images');
create policy product_images_admin_insert on storage.objects for insert to authenticated
with check(bucket_id='product-images' and (select public.is_admin()));
create policy product_images_admin_update on storage.objects for update to authenticated
using(bucket_id='product-images' and (select public.is_admin())) with check(bucket_id='product-images' and (select public.is_admin()));
create policy product_images_admin_delete on storage.objects for delete to authenticated
using(bucket_id='product-images' and (select public.is_admin()));

-- Registrar uma venda presencial e baixar o estoque no mesmo COMMIT.
-- O preço vem do banco, não de dados adulteráveis do navegador.
create or replace function public.register_sale(
 p_customer_id uuid,p_lines jsonb,p_discount numeric,p_paid numeric,p_installments integer,
 p_method text,p_notes text default null,p_first_due_date date default current_date
) returns uuid language plpgsql security definer set search_path='' as $$
declare v_sale_id uuid; v_line jsonb; v_product public.products%rowtype;
 v_subtotal numeric(12,2):=0; v_total numeric(12,2); v_remaining numeric(12,2);
 v_part numeric(12,2); v_i integer; v_paid_rest numeric(12,2);
begin
 if not public.is_admin() then raise exception 'Sem permissão'; end if;
 if jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 or jsonb_array_length(p_lines)>100 then raise exception 'Carrinho inválido'; end if;
 if p_installments not between 1 and 24 then raise exception 'Parcelamento inválido'; end if;
 if p_discount<0 or p_paid<0 then raise exception 'Valores inválidos'; end if;
 -- bloquear sempre em ordem definida para reduzir chance de deadlock.
 for v_product in select * from public.products where id in (select (a.value->>'id')::uuid from jsonb_array_elements(p_lines) a) order by id for update loop
   null;
 end loop;
 for v_line in select value from jsonb_array_elements(p_lines) loop
   select * into v_product from public.products where id=(v_line->>'id')::uuid;
   if not found or (v_line->>'qty')::integer<=0 or (v_line->>'qty')::integer>v_product.stock then raise exception 'Produto sem estoque suficiente'; end if;
   v_subtotal:=v_subtotal+v_product.sale_price*(v_line->>'qty')::integer;
 end loop;
 v_total:=round(v_subtotal-p_discount,2);
 if v_total<=0 or p_paid>v_total then raise exception 'Desconto ou pagamento inválido'; end if;
 v_remaining:=v_total-p_paid;
 insert into public.sales(customer_id,origin,status,subtotal,discount,total,payment_method,installments,notes,stock_applied)
 values(p_customer_id,'balcao',case when v_remaining=0 then 'concluida' else 'parcial' end,
 v_subtotal,p_discount,v_total,left(coalesce(p_method,'outro'),60),p_installments,p_notes,true) returning id into v_sale_id;
 for v_line in select value from jsonb_array_elements(p_lines) loop
   select * into v_product from public.products where id=(v_line->>'id')::uuid;
   insert into public.sale_items(sale_id,product_id,name_snapshot,quantity,unit_price,unit_cost)
   values(v_sale_id,v_product.id,v_product.name,(v_line->>'qty')::integer,v_product.sale_price,v_product.cost_price);
   update public.products set stock=stock-(v_line->>'qty')::integer where id=v_product.id;
 end loop;
 if p_paid>0 then
   insert into public.cash_entries(kind,category,description,amount,sale_id)
   values('entrada','Venda presencial','Recebimento na venda',p_paid,v_sale_id);
 end if;
 if v_remaining>0 then
  v_paid_rest:=v_remaining;
  for v_i in 1..p_installments loop
   v_part:=case when v_i=p_installments then v_paid_rest else round(v_remaining/p_installments,2) end;
   insert into public.receivables(sale_id,customer_id,amount,paid_amount,due_date,installment_number)
   values(v_sale_id,p_customer_id,v_part,0,(p_first_due_date+(v_i-1)*interval '1 month')::date,v_i);
   v_paid_rest:=v_paid_rest-v_part;
  end loop;
 end if;
 return v_sale_id;
end $$;
revoke all on function public.register_sale(uuid,jsonb,numeric,numeric,integer,text,text,date) from public,anon;
grant execute on function public.register_sale(uuid,jsonb,numeric,numeric,integer,text,text,date) to authenticated;

create or replace function public.record_payment(p_receivable_id uuid,p_amount numeric)
returns void language plpgsql security definer set search_path='' as $$
declare v_r public.receivables%rowtype;
begin
 if not public.is_admin() then raise exception 'Sem permissão'; end if;
 select * into v_r from public.receivables where id=p_receivable_id for update;
 if not found or v_r.status='cancelado' or p_amount<=0 or p_amount>v_r.amount-v_r.paid_amount then raise exception 'Pagamento inválido'; end if;
 update public.receivables set paid_amount=paid_amount+p_amount,
 status=case when paid_amount+p_amount>=amount then 'pago' else 'pendente' end where id=v_r.id;
 insert into public.cash_entries(kind,category,description,amount,sale_id,receivable_id)
 values('entrada','Cobrança','Recebimento de parcela',p_amount,v_r.sale_id,v_r.id);
 if not exists(select 1 from public.receivables where sale_id=v_r.sale_id and status='pendente') then
  update public.sales set status='concluida' where id=v_r.sale_id;
 end if;
end $$;
revoke all on function public.record_payment(uuid,numeric) from public,anon;
grant execute on function public.record_payment(uuid,numeric) to authenticated;

create or replace function public.register_purchase(p_product_id uuid,p_quantity integer,p_unit_cost numeric,p_paid boolean,p_notes text default null)
returns void language plpgsql security definer set search_path='' as $$
declare v_name text;
begin
 if not public.is_admin() then raise exception 'Sem permissão'; end if;
 if p_quantity<=0 or p_quantity>100000 or p_unit_cost<0 then raise exception 'Compra inválida'; end if;
 update public.products set stock=stock+p_quantity,cost_price=p_unit_cost where id=p_product_id returning name into v_name;
 if v_name is null then raise exception 'Produto não encontrado'; end if;
 insert into public.stock_movements(product_id,kind,quantity,unit_cost,notes)
 values(p_product_id,'compra',p_quantity,p_unit_cost,p_notes);
 if p_paid and p_unit_cost*p_quantity>0 then
 insert into public.cash_entries(kind,category,description,amount)
 values('saida','Compra de estoque','Reposição: '||v_name,p_unit_cost*p_quantity);
 end if;
end $$;
revoke all on function public.register_purchase(uuid,integer,numeric,boolean,text) from public,anon;
grant execute on function public.register_purchase(uuid,integer,numeric,boolean,text) to authenticated;

create or replace function public.finalize_online_order(p_order_id uuid,p_payment_id text,p_amount numeric)
returns text language plpgsql security definer set search_path='' as $$
declare v_order public.online_orders%rowtype; v_item record; v_sale uuid; v_stock int;
begin
 select * into v_order from public.online_orders where id=p_order_id for update;
 if not found or v_order.status='cancelado' then raise exception 'Pedido não encontrado'; end if;
 if v_order.status='pago' then return 'ja_pago'; end if;
 if p_amount<>v_order.total then raise exception 'Valor de pagamento divergente'; end if;
 for v_item in select product_id,quantity from public.online_order_items where order_id=p_order_id order by product_id loop
  select stock into v_stock from public.products where id=v_item.product_id for update;
  if v_stock is null or v_stock<v_item.quantity then
    update public.online_orders set status='revisao_estoque',payment_id=p_payment_id where id=p_order_id;
    return 'revisao_estoque';
  end if;
 end loop;
 insert into public.sales(origin,status,subtotal,discount,total,payment_method,installments,notes,stock_applied)
 values('online','concluida',v_order.subtotal+v_order.shipping_amount,0,v_order.total,'Mercado Pago',1,'Pedido online '||p_order_id::text,true) returning id into v_sale;
 for v_item in select * from public.online_order_items where order_id=p_order_id loop
  insert into public.sale_items(sale_id,product_id,name_snapshot,quantity,unit_price,unit_cost)
  select v_sale,p.id,v_item.name_snapshot,v_item.quantity,v_item.unit_price,p.cost_price from public.products p where p.id=v_item.product_id;
  update public.products set stock=stock-v_item.quantity where id=v_item.product_id;
 end loop;
 insert into public.cash_entries(kind,category,description,amount,sale_id)
 values('entrada','Venda online','Mercado Pago - bruto antes de taxas e frete',v_order.total,v_sale);
 update public.online_orders set status='pago',payment_id=p_payment_id where id=p_order_id;
 return 'pago';
end $$;
revoke all on function public.finalize_online_order(uuid,text,numeric) from public,anon,authenticated;
grant execute on function public.finalize_online_order(uuid,text,numeric) to service_role;

-- Segurança extra: conta não autorizada não entra no painel mesmo se conseguir se cadastrar.
-- Desabilite Sign Up público nas opções de Authentication do Supabase.
-- Adicione as contas por Authentication > Users > Add user, copie os UUIDs e execute:
-- insert into public.admin_users(user_id,display_name) values
-- ('UUID_DA_SINARA'::uuid,'Sinara'),('SEU_UUID'::uuid,'Fernando');
