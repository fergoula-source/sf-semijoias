# SF Semijoias 💎

Site de vendas e sistema administrativo da SF Semijoias, pensado para funcionar no **celular e no computador**. Identidade visual inspirada na marca original (turquesa, branco e detalhes dourados). Fotos fornecidas pela própria família.

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

## 1. Testar no seu computador (sem banco real)

Instale [Node.js 22](https://nodejs.org/) e execute na pasta do projeto:

```bash
npm install
npm run dev
```

Abra o endereço exibido no terminal, normalmente `http://localhost:5173`. Se **não** houver `.env`, o modo de desenvolvimento usa uma demonstração local com dados **fictícios**, que ficam salvos apenas no navegador. Na vitrine, clique no ícone de pessoa e depois em **Abrir painel de demonstração**. Teste cadastro, vendas, contas, estoque e despesas. Esse modo é intencionalmente **desativado nas versões de produção**.

### Importante sobre a demonstração

Nunca use dados de clientes reais na demonstração: ela não tem autenticação, não está criptografada no navegador e pode ser apagada ao limpar os dados do navegador. Fotos na demonstração também ocupam espaço no armazenamento local. O banco de verdade exige a próxima etapa.

## 2. Criar o banco seguro (Supabase)

1. Acesse [supabase.com](https://supabase.com), crie conta, depois **New project**.
2. Escolha nome `sf-semijoias`, uma senha forte do banco e a região mais próxima disponível. Guarde a senha em local seguro.
3. Vá até **SQL Editor > New query**, cole todo o arquivo `supabase/migrations/001_schema.sql` e execute. Isso cria tabelas, views, regras de acesso, armazenamento de fotos e funções de venda.
4. Vá até **Authentication > Users > Add user** e crie uma conta para a Sinara e outra para você. Não coloque senhas dentro do repositório.
5. Em **Authentication**, desative cadastro público (*Sign ups*) e configure o e-mail de confirmação/recuperação conforme necessário.
6. Copie o **UUID** de cada conta, volte ao SQL Editor e rode, trocando os exemplos:

```sql
insert into public.admin_users(user_id,display_name) values
('COLE-O-UUID-DA-SINARA'::uuid,'Sinara'),
('COLE-O-SEU-UUID'::uuid,'Administrador');
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
