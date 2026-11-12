# SF Semijoias 💎

Site de vendas e sistema administrativo da SF Semijoias, pensado para funcionar no **celular e no computador**. Identidade visual inspirada na marca original (turquesa, branco e detalhes dourados). Fotos fornecidas pela própria família.

**ATENÇÃO (novembro/2026):** a publicação pública sem Supabase é somente uma vitrine de preparação, **sem painel de demonstração e sem cadastros reais**. O modo de teste com dados locais ficou restrito a `npm run dev` em `localhost`, e o login administrativo real é acessado em `/#gestao` após configurar o Supabase. Sem backend configurado, não use o site para gerir vendas. Para a loja comercial, hospede a aplicação em um serviço apropriado; os termos do GitHub Pages não permitem hospedar uma operação de e-commerce.

**O que existe no sistema**

- Vitrine pública, pesquisa, categorias dinâmicas, carrinho e pedido por WhatsApp.
- Painel privado com login para pessoas autorizadas.
- Produtos com até 5 fotos, código, descrição, categoria, custo, preço, fornecedor, estoque e estoque mínimo.
- Calculadora de ganho bruto por unidade, markup (lucro dividido pelo custo) e margem (lucro dividido pela venda).
- Venda presencial: carrinho, desconto em R$ ou %, meio de pagamento, parcelas e entrada recebida.
- Cobranças por cliente, com saldos, vencimentos, recebimento parcial e registro em caixa.
- Lista de compras: estoque baixo, quantidade sugerida e reposição que soma estoque.
- Financeiro: entradas, saídas, despesas avulsas, saldo de movimentações e exportação CSV.
- Dashboard com vendas do mês, dinheiro recebido, despesas, a receber, alertas e evolução do caixa.
- Pedidos online e estrutura para pagamento pelo **Mercado Pago Checkout Pro (Orders API)** via funções no servidor.
- Página "Nossa história" com fotos fornecidas, texto editável e contatos.

## Situação atual e integração de produção (12/11/2026)

Projeto Supabase vinculado por referência: `lydxjkgnlvqmezjhzxhl` (URL pública `https://lydxjkgnlvqmezjhzxhl.supabase.co`).

Apenas conectar Supabase e GitHub **não instala as tabelas nem ativa o frontend automaticamente**. Confira no Supabase em **Project Settings > Integrations > GitHub**: repositório `fergoula-source/sf-semijoias`, diretório de trabalho `.`, branch `main`, opção **Deploy to production** habilitada. Veja os logs de migração para confirmar. O código agora usa migrações com timestamps e configura `[remotes.production]` no `config.toml`.

O GitHub Pages já recebeu a URL do projeto Supabase e a chave pública `VITE_SUPABASE_PUBLISHABLE_KEY` no workflow e no `.env.production` em 12/11/2026. Não é necessário enviar essa chave novamente. Ela é pública; pode ser substituída por variável de repositório em **Settings > Secrets and variables > Actions > Variables** caso seja rotacionada. A chave publishable é pública, mas **NUNCA coloque `sb_secret_` ou `service_role` em variáveis VITE**, nem no navegador. Configure também `VITE_ADMIN_FGOULART_EMAIL` e `VITE_ADMIN_SFELICE_EMAIL` para permitir login pelos nomes de usuário.

Crie as duas contas por **Supabase > Authentication > Users > Add user** e atribua cada UUID à tabela `public.admin_users` após as migrações. As senhas são individuais; o primeiro acesso exige troca, sem senhas iniciais públicas. Mantenha checkout desativado até configurar Mercado Pago e fazer testes de pagamento, reembolso, frete e estoque.

**Clientes externos:** manter Sign ups por e-mail e Confirm email ativados, configurar SMTP próprio para e-mails a clientes de fora da equipe. O SMTP padrão limita envios e não é adequado a produção. Compreender que a vitrine no GitHub Pages é somente teste — o serviço não deve hospedar a operação comercial.

## Ativação dos administradores `fgoulart` e `sfelice`

Os e-mails `fergoula@gmail.com` e `sinarafelice610@gmail.com` estão configurados no build do site. **Isso não cria as contas automaticamente**.

1. Confirme que as migrações de `supabase/migrations` foram aplicadas ao projeto de produção.
2. No Supabase > Authentication > Users, crie uma conta para cada e-mail. Configure senha inicial única e forte por processo seguro; não compartilhe senhas em GitHub nem em conversas. Confirme que ambos os e-mails estão verificados.
3. No SQL Editor, execute o arquivo `supabase/manual_setup_admins.sql` (arquivo manual, **não é migração**). Ele só concede o papel se as DUAS contas existirem e estiverem com e-mail confirmado.
4. No site, acesse `/#gestao`, faça login com `fgoulart` ou `sfelice` e a senha inicial correspondente. No primeiro acesso, cada um deverá trocar sua senha por uma senha forte.

Se não existir nenhuma tabela, a integração GitHub pode não ter feito deploy; consulte Project Settings > Integrations > GitHub e logs de deployments. **Não execute migrations já aplicadas outra vez pelo SQL Editor.**

## Mercado Pago: necessário para habilitar venda online

1. A Sinara precisa de sua conta Mercado Pago regularizada e apta a receber pagamentos.
2. Em Mercado Pago Developers, crie uma aplicação Checkout Pro e, primeiro, faça os testes de pagamento no ambiente de teste.
3. Configure o `MERCADOPAGO_ACCESS_TOKEN` privado e `MERCADOPAGO_WEBHOOK_SECRET` em Supabase > Edge Functions > Secrets. Nunca em `.env.production`, variáveis `VITE_` ou arquivos do GitHub.
4. Configure no Supabase `PUBLIC_STORE_URL` (URL HTTPS da hospedagem comercial definitiva) e `ALLOWED_ORIGINS` (origem HTTPS correspondente). No painel Mercado Pago, configure o webhook para `https://lydxjkgnlvqmezjhzxhl.supabase.co/functions/v1/mercadopago-webhook`.
5. Verifique que `create-checkout` e `mercadopago-webhook` foram de fato implantadas. Faça testes de aprovação, recusa, atraso, pagamento duplicado, cancelamento, estorno e falta de estoque antes de habilitar `VITE_CHECKOUT_ENABLED=true` e `store_settings.checkout_enabled=true`.

Enquanto isso, a loja pode usar o atendimento por WhatsApp sem processar pagamento online.

## 1. Testar no seu computador (sem banco real)

Instale [Node.js 22](https://nodejs.org/) e execute na pasta do projeto:

```bash
npm install
npm run dev
```

Abra o endereço exibido no terminal, normalmente `http://localhost:5173`. Se **não** houver `.env`, o modo de desenvolvimento usa uma demonstração local com dados **fictícios**, que ficam salvos apenas no navegador. Acesse `http://localhost:5173/#gestao` para abrir o painel de demonstração. Teste cadastro, vendas, contas, estoque e despesas. Esse modo é intencionalmente **desativado nas versões de produção**.

### Importante sobre a demonstração

Nunca use dados de clientes reais na demonstração: ela não tem autenticação, não está criptografada no navegador e pode ser apagada ao limpar os dados do navegador. Fotos na demonstração também ocupam espaço no armazenamento local. O banco de verdade exige a próxima etapa.

## 2. Criar o banco seguro (Supabase)

1. Acesse [supabase.com](https://supabase.com), crie conta, depois **New project**.
2. Escolha nome `sf-semijoias`, uma senha forte do banco e a região mais próxima disponível. Guarde a senha em local seguro.
3. **Se a integração GitHub > Deploy to production estiver ligada**, as migrações `supabase/migrations/20261106080000_initial_schema.sql` e `supabase/migrations/20261106080100_customer_accounts.sql` são aplicadas automaticamente. **Não execute essas migrações novamente no SQL Editor** (isso pode criar conflito no histórico). Se optar por instalação totalmente manual, execute-as na ordem correta somente em um projeto NOVO, sem histórico de migrações GitHub.
4. Vá até **Authentication > Users > Add user** e crie uma conta para a Sinara e outra para você. Não coloque senhas dentro do repositório.
5. Em **Authentication**, **mantenha cadastro por e-mail habilitado para compradores** e ative **Confirm email**. O acesso administrativo é protegido pela tabela `admin_users` e pelas políticas RLS; desabilitar os cadastros de e-mail bloquearia também os compradores. Para clientes reais, configure SMTP próprio, porque o SMTP padrão do Supabase não atende e-mails externos em produção.
6. Copie o **UUID** de cada conta, volte ao SQL Editor e rode, trocando os exemplos:

```sql
insert into public.admin_users(user_id,display_name,username,must_change_password) values
('COLE-O-SEU-UUID'::uuid,'Fernando','fgoulart',true),
('COLE-O-UUID-DA-SINARA'::uuid,'Sinara','sfelice',true);
```

7. Em **Project Settings > API**, copie a `Project URL` e a **publishable/anon key**. A `service_role` ou **secret key** JAMAIS pode ser colocada no site, no GitHub ou no `.env` do Vite.
8. Copie `.env.example` para `.env` e substitua URL e chave pública:

```env
VITE_SUPABASE_URL=https://SEU-PROJETO.supabase.co
VITE_SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
VITE_CHECKOUT_ENABLED=false
```

9. Execute `npm run dev` e entre com um dos usuários criados. Somente contas na tabela `admin_users` entram no painel. **A RLS é aplicada no banco, não apenas na interface.**

### Privacidade e segurança

A tabela `products` inteira é privada para administradores. A vitrine consulta a `catalog_products`, que expõe apenas nome, descrição, preço de venda, fotos, categoria e estoque. Preço de custo, fornecedores, clientes, caixa e cobranças não são acessíveis ao público. As fotos dos produtos **são públicas**, como é esperado numa vitrine. Não fotografe documentos ou dados privados.

Faça cópias de segurança periódicas do banco e tenha senhas diferentes com autenticação multifator nos serviços administrativos. Verifique os termos e limites do plano do Supabase antes de começar a vender.

## 3. Publicar pelo GitHub Pages

1. No GitHub, crie um **repositório público** chamado `sf-semijoias` (sem README inicial).
2. Dentro desta pasta, execute:

```bash
git init
git add .
git commit -m "Site e sistema de gestão SF Semijoias"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/sf-semijoias.git
git push -u origin main
```

3. No repositório, em **Settings > Secrets and variables > Actions > Variables**, crie:
   - `VITE_SUPABASE_URL` = URL do Supabase.
   - `VITE_SUPABASE_ANON_KEY` = chave pública anon/publishable.
   - `VITE_CHECKOUT_ENABLED` = `false` até terminar o passo 4.
4. Em **Settings > Pages > Build and deployment**, escolha **GitHub Actions**.
5. Em **Actions**, abra a execução **Publicar SF Semijoias**. A publicação usa o workflow `.github/workflows/deploy.yml` e adapta automaticamente a rota para `/sf-semijoias/`.
6. Acesse `https://SEU-USUARIO.github.io/sf-semijoias/`.

**Atenção:** GitHub Pages hospeda apenas a interface estática. Os dados, autenticação, uploads e checkout ficam no Supabase. Nunca coloque uma senha ou `service_role` em arquivos públicos. Sem as variáveis, a versão publicada não abre o painel de demonstração nem apresenta produtos reais.

## 4. Receber pagamentos de outras cidades (configuração adicional)

A versão entregue **não está apta a receber dinheiro real sem configurar e testar o Mercado Pago**. A opção de pedido pelo WhatsApp funciona independentemente do checkout, mas não cobra automaticamente.

Passos para habilitar pagamentos:

1. Crie uma aplicação no [Mercado Pago Developers](https://www.mercadopago.com.br/developers/pt) usando **Checkout Pro via Orders API** e configure uma conta recebedora da loja.
2. Instale o [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started), faça login e vincule o projeto:

```bash
npx supabase login
npx supabase link --project-ref SEU-PROJECT-REF
```

3. Configure **secrets do Supabase Edge Functions**, nunca variáveis `VITE_...`:

```bash
npx supabase secrets set MERCADOPAGO_ACCESS_TOKEN="SEU_ACCESS_TOKEN_PRIVADO"
npx supabase secrets set MERCADOPAGO_WEBHOOK_SECRET="SUA_ASSINATURA_SECRETA"
npx supabase secrets set PUBLIC_STORE_URL="https://SEU-USUARIO.github.io/sf-semijoias/"
npx supabase secrets set ALLOWED_ORIGINS="https://SEU-USUARIO.github.io,http://localhost:5173"
```

4. Implante as duas funções (públicas apenas no sentido de receber o checkout e o webhook; elas usam segredos apenas no servidor):

```bash
npx supabase functions deploy create-checkout --no-verify-jwt
npx supabase functions deploy mercadopago-webhook --no-verify-jwt
```

5. No painel de Developers do Mercado Pago, configure o Webhook com o evento **Order (Mercado Pago)** na URL:

```
https://SEU-PROJECT-REF.supabase.co/functions/v1/mercadopago-webhook
```

6. Faça testes com contas de teste, notificações simuladas e pedidos com valor pequeno; confira valores, assinaturas, estoque e se o pedido aparece no painel **Pedidos online**. Teste reprovação, pagamento pendente e estorno.
7. Depois dos testes, mude a variável `VITE_CHECKOUT_ENABLED` para `true` no GitHub, execute nova publicação e, no painel **Minha loja**, marque **Permitir pagamento online**.

**Como funciona**: o navegador envia apenas IDs e quantidades. O servidor recalcula preços e frete no banco, cria a order no Mercado Pago, recebe a notificação assinada e confirma o pagamento consultando diretamente a API. O estoque só é reduzido após confirmação, em transação no banco. Uma notificação repetida não repete a venda. Se o estoque acabar entre o checkout e o pagamento, o pedido ficará `revisao_estoque`, e a equipe precisará resolver entrega ou reembolso manualmente. **Não envie o pedido por conta de uma tela de "sucesso" no navegador — confira o status no painel.**

O site não coleta nem armazena número de cartão, CVV ou credenciais bancárias. O cliente é redirecionado ao ambiente hospedado do Mercado Pago.

**Frete:** nesta versão, pode ser escolhido retirada grátis ou **frete fixo**. Habilite frete fixo somente se a loja tiver condições de entregar nos CEPs atendidos pelo valor configurado. Não há cálculo automático por Correios/transportadoras; não apresente frete fixo para todo o país sem verificar os custos reais. Se não houver logística definida, deixe entrega desabilitada no checkout e combine fretes pelo WhatsApp.

## 5. Recomendações antes do lançamento comercial

- Configure **identificação do fornecedor e contato comercial**, políticas de entrega e trocas, direito de arrependimento, privacidade/LGPD e emissão de comprovantes conforme o enquadramento do negócio. Consulte profissional contábil/jurídico quando necessário.
- Confira impostos, taxas do cartão, chargebacks, custo de frete e taxas do Mercado Pago. O dashboard registra **valor bruto** de vendas online; taxas e frete pago precisam virar despesas separadas. É um controle gerencial e **não substitui contabilidade fiscal**.
- Defina limites/condições de parcelamento e gestão de inadimplência. Parcelas no painel são cobranças **internas**; ele não envia links automáticos de cobrança.
- Configure backups, políticas de senha, 2FA em GitHub/Supabase e revise usuários autorizados.
- Para vender nacionalmente, considere integrar uma solução de cálculo de frete por CEP e rotinas para estornos, devoluções e cancelamentos automáticos. Não envie o pedido enquanto o pagamento estiver pendente ou em revisão.
- As imagens da dona da loja foram incluídas como fornecidas; revise os direitos de uso e substitua se desejar.

## 6. Próximas evoluções possíveis

Comissões, relatórios de lucro efetivo, relatórios de clientes, impressão de comprovantes, códigos de barras, catálogo de tamanhos/cores e variações (roupas P/M/G), conciliação bancária, estoque reservado durante pagamento, transportadoras por CEP, aviso de vendas por WhatsApp e despesas a pagar ainda não estão implementados. O projeto já está organizado para crescer.

**Aviso operacional:** sem instalação de dependências e conexão às contas reais, os serviços de banco e checkout não podem ser validados neste ambiente. Execute testes completos em Supabase/Mercado Pago antes da produção.
