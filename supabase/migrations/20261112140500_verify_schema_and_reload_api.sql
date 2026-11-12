-- Verifica o esquema-base da SF Semijoias antes de disponibilizar acesso.
-- A criacao efetiva de tabelas fica nas migrations anteriores.
do $$
begin
  if to_regclass('public.categories') is null
     or to_regclass('public.products') is null
     or to_regclass('public.admin_users') is null
     or to_regclass('public.store_settings') is null
     or to_regclass('public.shopper_profiles') is null then
    raise exception 'SF Semijoias: esquema incompleto, confira os logs de migrate no Supabase';
  end if;
end $$;
-- Atualiza o cache do PostgREST apos as migracoes.
notify pgrst, 'reload schema';
