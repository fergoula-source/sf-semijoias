-- SF Semijoias: atualizar apenas o Instagram anterior incorreto.
-- Nao sobrescreve uma configuracao personalizada feita no painel.
update public.store_settings
set instagram = 'sinara_felice'
where id = 1
  and lower(trim(instagram)) in ('sinara.felice', '@sinara.felice', 'https://www.instagram.com/sinara.felice');
