# SF Semijoias — integração de pagamentos e liberação segura

Estado em 12/11/2026: Checkout Pro pela **Orders API** implementado no código e com implantação das Edge Functions confirmada nos logs enviados, mas **pagamento real permanece DESATIVADO**. Este documento não contém tokens privados.

## 1. Criar aplicação na conta da Sinara

Na conta Mercado Pago que **receberá** os pagamentos:
1. Acesse https://www.mercadopago.com.br/developers/pt e entre em **Suas integrações**.
2. Clique em **Criar aplicação**. Nome sugerido: `SF Semijoias`.
3. Selecione a solução **Checkout Pro** (via Orders API).
4. Ative o ambiente **Teste**. Não compartilhe login, senhas ou Access Token em mensagens, arquivos, prints ou commits.
5. No ambiente Teste, entre em **Credenciais**. O código de backend usa **Access Token**; este é privado e não deve aparecer no frontend. O fluxo Checkout Pro/Orders redireciona por URL e não precisa de Public Key no React.
6. Abra **Configuração de Webhooks**, escolha **Teste**, configure abaixo, evento **Order (Mercado Pago)** e salve.
   - URL: `https://lydxjkgnlvqmezjhzxhl.supabase.co/functions/v1/mercadopago-webhook`
   - Guarde a **Assinatura secreta** do ambiente Teste, sem compartilhá-la.

## 2. Configurar secrets privados no Supabase

Entre em https://supabase.com/dashboard/project/lydxjkgnlvqmezjhzxhl/functions/secrets

Adicione os secrets com os valores correspondentes, pelo formulário do **Supabase** (não no GitHub):

| Nome (Key) | Valor (Value) |
|---|---|
| `MERCADOPAGO_ACCESS_TOKEN` | Access Token de Teste obtido na aplicação da Sinara |
| `MERCADOPAGO_WEBHOOK_SECRET` | Assinatura secreta de Webhooks do ambiente Teste |
| `PUBLIC_STORE_URL` | `https://fergoula-source.github.io/sf-semijoias/` (temporário e apenas para testes) |
| `ALLOWED_ORIGINS` | `https://fergoula-source.github.io` (apenas origem, sem caminho) |

`SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` são injetados pelo próprio Supabase nas Edge Functions. **Nunca** adicione essas chaves privadas a `.env.production`, `VITE_*` nem ao GitHub público.

Confirme em **Edge Functions** que `create-checkout` e `mercadopago-webhook` aparecem como implantadas. O GitHub/Supabase deploy deve aplicar versões novas das funções no próximo commit/deploy.

## 3. Antes de testar pagamentos

- Concluir as configurações do e-mail de confirmação do Supabase (SMTP de produção antes de receber clientes reais).
- Criar cliente comprador de teste com e-mail confirmado, **não um dos administradores**.
- Cadastrar no painel 1 produto fictício, baixo valor e estoque de teste.
- Verificar que o carrinho recalcula preços no servidor e que o webhook exige assinatura.
- Enquanto `VITE_CHECKOUT_ENABLED=false` e `store_settings.checkout_enabled=false`, o checkout público fica desabilitado. **Não os altere para true sem passar por todos os testes abaixo.**
- Para testar efetivamente o checkout, crie **um ambiente de preview separado** (hospedagem não comercial/temporária), com as credenciais de teste e `VITE_CHECKOUT_ENABLED=true`, sem alterar a loja pública de produção. Ajuste `PUBLIC_STORE_URL` e `ALLOWED_ORIGINS` para esse preview, usando um projeto Supabase separado se o teste precisar coexistir com produção.

## 4. Roteiro de homologação

Execute e registre resultados dos seguintes cenários em **ambiente de teste**:
- Carrinho com produto disponível, preço correto e frete adequado;
- Login de cliente e exigência de e-mail confirmado;
- Pagamento aprovado e webhook assinado; conferir pedido `pago`, venda registrada **uma única vez**, baixa de estoque e lançamento no caixa;
- Pagamento recusado, abandonado ou pendente; **não** baixar estoque nem registrar como receita;
- Webhook duplicado, sem assinatura ou com assinatura inválida; não duplicar vendas;
- Produto sem estoque na confirmação do pagamento: pedido deve ir para `revisao_estoque`, com tratativa manual de reembolso ou entrega, **nunca confirmar entrega automaticamente**;
- Pedido no celular e no computador; conferir visibilidade correta para cliente e admin;
- Cancelamento, estorno/chargeback e conciliação com extrato real: **ainda requerem processo operacional de reembolso e ajustes de estoque/caixa** antes do lançamento.

**ATENÇÃO:** não use parâmetros `?resultado=sucesso` como confirmação financeira. Eles informam apenas que o cliente retornou do checkout. A aprovação só é válida após consultar a API do Mercado Pago e receber o webhook verificado.

## 5. Produção

Depois dos testes:
1. Migrar a vitrine do GitHub Pages para hospedagem apropriada para e-commerce (por exemplo, Cloudflare Pages/Vercel) e configurar domínio e políticas comerciais.
2. Na aplicação da Sinara, ativar credenciais **Produção** e confirmar que a conta está habilitada a receber.
3. No Supabase, substituir os secrets de teste por **Access Token e Assinatura Secreta de produção**, atualizar `PUBLIC_STORE_URL` e `ALLOWED_ORIGINS` para o domínio definitivo. Não divulgar os valores privados.
4. No Mercado Pago, configurar os Webhooks em **Produção** para a mesma URL das Edge Functions e selecionar evento **Order (Mercado Pago)**. Usar a assinatura de produção.
5. Só após testes reais controlados, ativar o flag `VITE_CHECKOUT_ENABLED=true` no build e, no admin, marcar `Permitir pagamento online`. **Não ativar um sem o outro.**
6. Configurar alertas e procedimentos de tratamento manual de pedidos sem estoque, estornos, chargebacks e disputas. Conferir o recebimento líquido versus taxas antes de entregar.

Documentação oficial:
- https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-orders/create-application
- https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-orders/create-order
- https://www.mercadopago.com.br/developers/pt/docs/checkout-pro-orders/notifications
- https://supabase.com/docs/guides/functions/secrets
