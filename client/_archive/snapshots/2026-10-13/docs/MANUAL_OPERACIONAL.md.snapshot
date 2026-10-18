# Manual Operacional do Usuário e da Empresa
## ZM Cesta Básica — Sistema de Gestão de Estoque, Produção, Vendas e Financeiro

**Versão do Documento:** 1.0 (Sistema Homologado - Fases 1 a 9)  
**Público-Alvo:** Gestores da Empresa, Encarregados de Galpão, Operadores de Caixa e Entregadores/Responsáveis por Rotas  
**Idioma:** Português Brasileiro (pt-BR)  

---

## 1. Visão Geral da Rotina Operacional

O sistema **ZM Cesta Básica** foi desenvolvido sob medida para gerenciar com máxima precisão o ciclo de vida completo de uma empresa de montagem e comercialização de cestas básicas. A operação diária é estruturada em 6 macroetapas coordenadas:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  1. Compras &  │ ──> │  2. Produção & │ ──> │ 3. Expedição & │
│   Estoque MP   │     │    Montagem    │     │   Custódia     │
└────────────────┘     └────────────────┘     └────────────────┘
                                                       │
┌────────────────┐     ┌────────────────┐              ▼
│  6. Tesouraria │ <── │ 5. Conferência │ <── ┌────────────────┐
│  & Financeiro  │     │   & Acerto     │     │  4. Vendas &   │
└────────────────┘     └────────────────┘     │    Rotas       │
                                              └────────────────┘
```

---

## 2. Cadastro de Produtos e Embalagens Comerciais

### 2.1. Insumos e Matérias-Primas
- **Unidade-Base de Armazenamento:** Todo insumo possui uma unidade-base estrita de medição:
  - `G` (Gramas): Para itens pesáveis secos (arroz, feijão, açúcar, café, farinha, sal).
  - `ML` (Mililitros): Para líquidos (óleo de soja, detergente, vinagre, desinfetante).
  - `UNIT` (Unidade): Para itens unitários indivisíveis (sabonete, esponja de aço, pasta de dente, embalagens plásticas, caixas de papelão).
- **Estoque Mínimo:** Definido na unidade-base. Quando o saldo atinge ou fica abaixo deste valor, o item é automaticamente destacado em vermelho no **Dashboard** e no relatório de reposição.

### 2.2. Embalagens Comerciais e Fatores de Conversão
Na compra, fornecedores vendem fardos, caixas e sacos, enquanto a montagem consome unidades ou gramas. O sistema elimina erros manuais:
- Exemplo 1: Arroz Agulhinha Tipo 1 (unidade-base: `G`). Embalagem cadastrada: *Fardo 6x5kg* com fator de conversão de `30.000` gramas. Ao registrar a compra de 10 fardos, o estoque é creditado automaticamente em `300.000` gramas.
- Exemplo 2: Sabonete (unidade-base: `UNIT`). Embalagem: *Caixa c/ 72 unidades* (fator: `72`). Ao comprar 5 caixas, o saldo sobe `360` unidades.

---

## 3. Composição de Cestas e Versionamento de Receitas

### 3.1. Tipos Comerciais de Cestas
- O sistema permite cadastrar tipos comerciais padrão (ex.: *Cesta Família Padrão*, *Cesta Econômica*, *Cesta Natalina*, *Cesta Limpeza*).
- Cada tipo possui código de identificação único, descrição, preço de venda sugerido e permissão para personalização.

### 3.2. Imutabilidade e Versionamento de Receitas
- Cada cesta possui uma **Receita Ativa** detalhando exatamente quais produtos compõem a cesta e em qual quantidade na unidade-base.
- **Regra de Ouro:** Toda alteração de composição cria uma **nova versão** da receita (Versão 2, Versão 3). As versões anteriores permanecem imutáveis no histórico contábil, assegurando que o custo de cestas montadas no passado nunca seja recalculado retroativamente.

---

## 4. Entrada de Compras e Custo Médio Ponderado Móvel (CMPM)

### 4.1. Registro de Compras
1. Acesse o menu **Compras** e clique em **Nova Compra**.
2. Informe o fornecedor, número da nota fiscal e os itens adquiridos (selecionando a embalagem comercial ou unidade avulsa).
3. O sistema calcula o valor total da nota e o custo unitário por unidade-base em escala de microcentavos ($1 \text{ centavo} = 10.000 \text{ microcentavos}$).

### 4.2. Recálculo Automático do CMPM
O Custo Médio Ponderado Móvel é atualizado instantaneamente a cada entrada com arredondamento bancário *half-even*:
$$\text{CMPM}_{\text{novo}} = \frac{(\text{Estoque Atual} \times \text{CMPM Antigo}) + (\text{Qtd Compra} \times \text{Custo Unitário da Compra})}{\text{Estoque Atual} + \text{Qtd Compra}}$$

---

## 5. Produção, Montagem e Triagem de Desmontagem

### 5.1. Ordem de Montagem (Produção em Lote)
1. Acesse o menu **Produção** e selecione o tipo de cesta a produzir.
2. Informe a quantidade de cestas a montar. O sistema valida se há saldo suficiente de todos os ingredientes no armazém.
3. Ao confirmar, o sistema executa uma **transação atômica** (`BEGIN IMMEDIATE`):
   - Dá baixa imediata de todos os insumos consumidos.
   - Dá entrada das cestas prontas no estoque vendável da loja (`STORE`).
   - Apura o custo real total dos insumos e congela de forma imutável o **Custo Unitário da Cesta** (`unit_cost_cents`) para fins de apuração de CMV na DRE.

### 5.2. Desmontagem e Triagem Física de Insumos
Caso um lote precise ser desmanchado (ex.: cancelamento de pedido ou avaria de embalagem externa):
- O operador realiza a triagem item por item.
- Itens intactos retornam formalmente ao estoque vendável (`STORE`).
- Itens danificados (ex.: saco de açúcar furado) são baixados como perda de montagem (`ASSEMBLY_LOSS`) com justificativa obrigatória, sem gerar saldo falso no sistema.

---

## 6. Expedição Física e Custódia de Cestas (`STORE` vs `TRANSIT`)

### 6.1. Cadastro de Responsáveis por Rotas
No galpão, as cestas saem para entrega sob responsabilidade de entregadores parceiros ou motoristas internos. Eles são cadastrados no menu **Expedição -> Responsáveis** com nome e telefone (sem necessidade de criação de logins ou senhas).

### 6.2. Registro de Saída Física (Romaneio de Expedição)
1. Antes do caminhão/van sair, registre a saída no menu **Expedição -> Nova Saída**.
2. Selecione a pessoa responsável e a quantidade de cada tipo de cesta embarcada.
3. O sistema realiza uma **transferência de custódia contábil**:
   - Saldo no galpão da loja (`STORE`): **reduzido**.
   - Saldo em trânsito sob custódia do responsável (`TRANSIT`): **aumentado**.

---

## 7. Registro de Vendas e Prevenção de Duplo Desconto de Estoque

### 7.1. Vendas de Balcão (Loja Física)
- Vendas feitas diretamente no galpão (`DIRECT_STORE`) dão baixa nas cestas prontas do estoque da loja (`STORE`).

### 7.2. Vendas em Rota Comercial (Entregadores)
- Quando o entregador vende uma cesta durante a rota (`COMMERCIAL_ROUTE`), a venda é vinculada ao responsável e à saída física (`dispatch_id`).
- **Blindagem do Sistema:** A baixa de estoque incide **exclusivamente sobre o saldo em trânsito (`TRANSIT`)** sob custódia daquele motorista. O estoque da loja não sofre nenhum desconto duplo.

---

## 8. Conferência de Retorno e Equação de 4 Termos

Ao final do dia ou término da rota, o entregador retorna ao galpão para prestar contas. O sistema aplica a **Equação Canônica de 4 Termos**:

$$\text{Quantidade Retirada} = \text{Vendidas} + \text{Devolvidas Intactas} + \text{Avariadas/Perdidas} + \text{Ainda em Custódia}$$

1. **Vendidas:** Cestas registradas no módulo de vendas durante a rota.
2. **Devolvidas Intactas:** Cestas perfeitas que retornam ao caminhão e são recolocadas na prateleira do galpão (crédito em `STORE` e débito em `TRANSIT`).
3. **Avariadas ou Perdidas:** Cestas danificadas no transporte (baixa de `TRANSIT` como `DISPATCH_LOSS` com justificativa obrigatória). **Proibido retorno automático ao estoque vendável**.
4. **Itens que Permanecem sob Custódia:** Cestas que permanecerão na van para entrega na manhã seguinte continuam sob responsabilidade do motorista.
5. **Divergências:** Se a soma não bater com as retiradas, o sistema registra formalmente a diferença como `PENDING_INVESTIGATION`.

---

## 9. Acerto Financeiro da Rota e Segregação de Meios de Pagamento

Para evitar cobrar do motorista valores que ele não recebeu em mãos:

### 9.1. Segregação Mandatória
- **Dinheiro Físico em Mãos:** Papel-moeda recebido de vendas à vista ou de cobranças de fiados antigos na rota. Este valor **deve ser conferido e entregue fisicamente ao caixa da empresa**.
- **Pagamentos Recebidos Diretamente na Conta da Empresa (Pix / Cartão da Loja):** Quando o cliente faz Pix para o CNPJ da ZM ou passa o cartão na maquininha fixa, o valor entra diretamente na conta bancária da empresa. **O sistema não cobra esse valor do motorista**.
- **Despesas Autorizadas Abatidas:** Gastos com combustível ou pedágio autorizados pela gerência são abatidos do dinheiro físico a entregar, mediante comprovante e justificativa.

### 9.2. Fórmula do Repasse em Dinheiro
$$\text{Dinheiro Físico a Entregar} = \text{Vendas à Vista em Dinheiro} + \text{Cobranças de Fiado em Dinheiro} - \text{Despesas de Viagem}$$

---

## 10. Vendas a Prazo (Fiado), Cobranças e Quitações

1. O cliente pode ser cadastrado previamente com limite de crédito e dados de contato.
2. Ao registrar uma venda a prazo (`INSTALLMENT` ou `CREDIT_TERM`), o sistema gera títulos em **Contas a Receber**.
3. O cliente pode amortizar o valor em parcelas ou valor avulso. Cada pagamento registra o meio utilizado e abate o saldo devedor.
4. Quando o saldo zera, o título é marcado automaticamente como `PAID` (Quitado).

---

## 11. Contas a Pagar e Livro-Caixa da Tesouraria

1. **Contas a Pagar:** Registro de obrigações com fornecedores de insumos e contas fixas (aluguel, energia, água, internet, manutenção).
2. **Classificação entre Empresa e Sócios:**
   - `BUSINESS`: Despesas operacionais do negócio (computadas na DRE).
   - `PERSONAL_WITHDRAWAL`: Retiradas particulares dos sócios. Deduzem saldo da conta da empresa, mas não distorcem o lucro operacional do negócio.
3. **Livro-Caixa Imutável (`cash_flow_entries`):** O livro-caixa é estritamente *append-only*. Nenhum lançamento de caixa pode ser editado ou apagado; correções ocorrem exclusivamente por estornos auditáveis.

---

## 12. Dashboard, Relatórios Gerenciais e Impressão de Formulários A4

### 12.1. Dashboard Operacional e Financeiro
Apresenta em tempo real:
- Total de cestas montadas e vendidas no dia/mês.
- Alertas de produtos abaixo do estoque mínimo.
- Saldo atual e saldo projetado da tesouraria (considerando contas a pagar e receber nos próximos 30 dias).
- Painel de motoristas com repasses de dinheiro pendentes.

### 12.2. Exportação de Planilhas e Relatórios Preenchidos
Todos os 8 relatórios do sistema podem ser visualizados na tela, baixados em formato de planilha digital (CSV e XLSX) ou gerados em PDF paginado formatado para papel A4.

### 12.3. Formulários em Branco para Preenchimento Manual à Caneta
Para facilitar o trabalho no pátio onde não há computadores disponíveis, o sistema disponibiliza 4 formulários A4 padronizados com linhas largas (8 a 10 mm de altura) para escrita à mão:
- **Formulário A:** Vendas Fiadas, Pagamentos e Quitação.
- **Formulário B:** Contas a Pagar e Despesas.
- **Formulário C:** Saídas Físicas e Romaneio de Conferência Diária.
- **Formulário D:** Balanço Físico de Estoque (Inventário / Prancheta).
