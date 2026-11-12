-- Provisionamento unico dos dois admins indicados pelo responsavel da loja.
-- Somente emails VERIFICADOS pelo Supabase Auth podem ser autorizados.
-- Executa automaticamente apos migracoes de tabelas, quando o GitHub estiver conectado.
-- Se a verificacao ainda nao ocorreu, falha de forma explicita em vez de liberar o acesso.
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
    raise exception 'SF Semijoias: confirme ambos os emails em Authentication > Users ANTES de fazer o deploy. Nao use senha padrao.';
  end if;

  insert into public.admin_users(user_id,display_name,username,must_change_password)
   values(v_fernando,'Fernando','fgoulart',true),(v_sinara,'Sinara','sfelice',true)
  on conflict (user_id) do update
   set display_name=excluded.display_name,
       username=excluded.username,
       must_change_password=true;
end $$;
