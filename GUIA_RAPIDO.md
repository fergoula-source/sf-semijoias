# Guia rápido — SF Semijoias 💎

## Para a Sinara: o que fazer todo dia

1. Acesse o site publicado no celular ou computador. Toque no ícone de pessoa e entre com seu e-mail e senha.
2. **Produtos & estoque:** cadastre cada semijoia ou roupa, foto, preço pago, preço de venda, quantidade e categoria. A tela calcula a margem e o percentual de ganho sobre o custo. Se inventar uma categoria, use o campo “Nova categoria”.
3. **Nova venda:** adicione os itens que vendeu pessoalmente, selecione o cliente, inclua descontos, o número de parcelas e quanto recebeu de entrada. Confirme para dar baixa no estoque.
4. **A receber:** confira quem ainda deve, quais parcelas estão vencendo e registre os valores pagos, inclusive pagamentos parciais.
5. **Reposição de estoque:** acompanhe as peças que chegaram à quantidade mínima. Ao comprar mais unidades, informe a quantidade e o custo; o estoque aumenta automaticamente.
6. **Financeiro:** lance gastos avulsos (água, luz, embalagens, frete, etc.) e confira entradas/saídas.
7. **Visão geral:** veja vendas do mês, dinheiro efetivamente recebido, despesas, contas pendentes e estoque baixo.
8. **Minha loja:** altere a história da SF Semijoias, o WhatsApp, as frases de apresentação e informações comerciais.

**Cuidados:** valor de venda não é o mesmo que dinheiro em caixa. Dinheiro a receber não é dinheiro recebido. “Lucro por peça” no cadastro é uma estimativa **bruta**, antes de impostos, cartão, frete e despesas fixas.

## Para quem vai configurar o site (uma vez)

1. **Primeiro, testar sem dados reais.** Instale Node.js, execute `npm install` e `npm run dev` dentro do projeto. Um modo fictício estará disponível.
2. **Criar banco e usuários.** Monte o projeto no Supabase, execute `supabase/migrations/001_schema.sql`, crie os dois usuários no Authentication e insira os UUIDs na tabela `admin_users`. O passo a passo completo está no `README.md`.
3. **Criar repositório público no GitHub.** Nome sugerido: `sf-semijoias`. Envie o projeto todo em um único commit, configure as três Variables de Actions, e em `Settings > Pages` selecione `GitHub Actions`.
4. **Cadastrar produtos reais.** Fotos, categorias e valores são armazenados no Supabase, não no GitHub; novas publicações do site não apagam o catálogo.
5. **Só depois, vender com pagamento online.** Configure credenciais privadas e webhooks no Supabase/Mercado Pago, execute testes reais de ponta a ponta e só então habilite o checkout. O site nunca deve receber diretamente números de cartão.

**Importante:** o projeto está preparado, mas não está publicado nem conectado a contas reais. Nenhum pagamento de verdade deve ser aceito até que as funções de checkout e webhooks sejam configuradas e testadas. As políticas de entrega, devoluções e privacidade são rascunhos editáveis: revise-as antes da abertura ao público.
