-- Execute DEPOIS de 001_schema.sql. Crie administradores manualmente por convite.
-- Cadastro de clientes por e-mail/senha com confirmação de e-mail ativada no Supabase Auth.

alter table public.admin_users
  add column if not exists username text unique,
  add column if not exists must_change_password boolean not null default true;

create table if not exists public.shopper_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  created_at timestamptz not null default now()
);
alter table public.shopper_profiles enable row level security;
create policy shopper_read_own on public.shopper_profiles for select to authenticated using (user_id=(select auth.uid()));
create policy shopper_insert_own on public.shopper_profiles for insert to authenticated with check (user_id=(select auth.uid()) and not (select public.is_admin()));
create policy shopper_update_own on public.shopper_profiles for update to authenticated using (user_id=(select auth.uid()) and not (select public.is_admin())) with check (user_id=(select auth.uid()) and not (select public.is_admin()));
grant select,insert,update on public.shopper_profiles to authenticated;
revoke all on public.shopper_profiles from anon;

alter table public.online_orders add column if not exists shopper_user_id uuid references auth.users(id) on delete set null;
create index if not exists online_orders_shopper_idx on public.online_orders(shopper_user_id);
create policy shopper_read_own_orders on public.online_orders for select to authenticated
  using (shopper_user_id=(select auth.uid()));
create policy shopper_read_own_order_items on public.online_order_items for select to authenticated
  using (exists(select 1 from public.online_orders o
    where o.id=order_id and o.shopper_user_id=(select auth.uid())));

-- Admins só podem ser configurados via SQL Editor / service_role, nunca pelo usuário da aplicação.
-- O usuário autenticado consegue marcar apenas SUA própria troca de senha como concluída.
create or replace function public.complete_initial_password_change()
returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.is_admin() then raise exception 'Acesso negado'; end if;
  update public.admin_users set must_change_password=false where user_id=(select auth.uid());
end $$;
revoke all on function public.complete_initial_password_change() from public, anon;
grant execute on function public.complete_initial_password_change() to authenticated;

-- No SQL Editor, APÓS convidar/confirmar as duas contas em Authentication > Users,
-- vincule os UUIDs reais. Não use senha admin e jamais coloque senha no git:
-- insert into public.admin_users(user_id,display_name,username,must_change_password) values
-- ('SEU-UUID-REAL'::uuid,'Fernando','fgoulart',true),
-- ('UUID-REAL-DA-SINARA'::uuid,'Sinara','sfelice',true);
