-- SF Semijoias - EXECUTAR MANUALMENTE no Supabase SQL Editor,
-- somente depois de aplicar as migracoes e criar/confirmar os dois usuarios via Authentication > Users.
-- Nao adicione este arquivo em supabase/migrations: ele depende de usuarios Auth ja existentes.
-- Nenhuma senha e definida ou revelada aqui.

do $$
declare v_fernando uuid; v_sinara uuid;
begin
  select id into v_fernando
  from auth.users
  where lower(email)='fergoula@gmail.com' and email_confirmed_at is not null;
  select id into v_sinara
  from auth.users
  where lower(email)='sinarafelice610@gmail.com' and email_confirmed_at is not null;

  if v_fernando is null or v_sinara is null then
    raise exception 'Crie e confirme os dois usuarios no Authentication > Users antes de executar este script.';
  end if;
  if v_fernando=v_sinara then
    raise exception 'As contas administrativas devem ser distintas.';
  end if;

  insert into public.admin_users(user_id,display_name,username,must_change_password)
  values
    (v_fernando,'Fernando','fgoulart',true),
    (v_sinara,'Sinara','sfelice',true)
  on conflict(user_id) do update
  set display_name=excluded.display_name,
      username=excluded.username,
      must_change_password=true;
end $$;

-- Conferir SEM retornar senha:
select a.username, a.display_name, u.email, u.email_confirmed_at is not null as email_confirmado
from public.admin_users a
join auth.users u on u.id=a.user_id
where a.username in ('fgoulart','sfelice')
order by a.username;
