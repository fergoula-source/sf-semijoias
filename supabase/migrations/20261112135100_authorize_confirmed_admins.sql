-- Provisionamento unico dos dois admins indicados pelo responsavel da loja.
-- Somente emails VERIFICADOS pelo Supabase Auth podem ser autorizados.
-- Executa automaticamente apos migracoes de tabelas, quando o GitHub estiver conectado.
-- Se ambos os usuarios ainda nao confirmaram email, nao interromper a criacao do banco.
-- O papel so sera atribuido quando ambos estiverem verificados; caso contrario, usar o script manual_setup_admins.sql depois.
do $$
declare
  v_fernando uuid;
  v_sinara uuid;
begin
  select u.id into v_fernando from auth.users u
   where lower(u.email)='fergoula@gmail.com' and u.email_confirmed_at is not null;
  select u.id into v_sinara from auth.users u
   where lower(u.email)='sinarafelice610@gmail.com' and u.email_confirmed_at is not null;

  if v_fernando is null or v_sinara is null or v_fernando=v_sinara then
    raise notice 'SF Semijoias: um ou dois emails ainda nao foram confirmados. Admin nao autorizado nesta etapa.';
    return;
  end if;

  insert into public.admin_users(user_id,display_name,username,must_change_password)
   values(v_fernando,'Fernando','fgoulart',true),(v_sinara,'Sinara','sfelice',true)
  on conflict (user_id) do update
   set display_name=excluded.display_name,
       username=excluded.username,
       must_change_password=true;
end $$;
