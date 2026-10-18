# Validação dos formulários A4 configuráveis

Revisão: 14/10/2026. Guia de uso: [Relatórios e impressão](RELATORIOS_E_IMPRESSAO.md).

## Escopo entregue

- Seleção de colunas nos modelos ativos de fiados, contas a pagar e inventário,
  em branco ou preenchidos, refletida nos arquivos PDF e XLSX e nos totais.
- Ordenação dos campos selecionados por setas, salva por modelo e aplicada à
  prévia e às duas exportações. Inclusão/remoção de colunas preserva a sequência
  restante; restauração da ordem mantém a seleção e as outras configurações.
- Orientação automática/retrato/paisagem; quatro margens; altura mínima das
  linhas; fonte; proporções das colunas; espaços de assinatura no rodapé.
- Linhas em branco calculadas para uma página, verificadas no layout real do
  PDF, ou quantidade manual paginada. Prévia e contagem real de páginas.
- Preferências locais por modelo, com restauração dos padrões.
- Exportação do mesmo conjunto de dados carregado para consulta; seletor nativo
  de destino para PDF e XLSX, com cancelamento sem falso sucesso.
- Exclusão de cancelados nos totais operacionais dos formulários preenchidos;
  vazio com zero registros; contas a pagar com valor pago, saldo e observações
  próprios; datas de vencimento preservadas como datas de calendário.
- Bloqueio de respostas antigas e descarte do relatório após erro; consultas
  agrupadas de pagamentos e estoque para reduzir buscas por registro.

As alterações são de consulta, apresentação e exportação. Não há migração de
esquema ou alteração de registros comerciais. O formulário de expedição não foi
restaurado na interface. As rotas GET antigas continuam disponíveis.

## Evidências automatizadas

Antes das mudanças: 232 testes backend e 175 testes Flutter aprovados.

Depois das mudanças:

- Backend: 248 testes aprovados.
- Flutter: 208 testes aprovados, incluindo a revisão posterior da impressão.
- Análise estática do cliente sem problemas.
- Compilações de teste Windows e Android verificadas nesta entrega.

Novas verificações cobrem seleção e ordem de colunas, valores/totais,
configurações inválidas, cancelados, ausência de dados, snapshot sem nova
consulta, XLSX com texto literal em vez de fórmula, configuração A4, margens,
larguras, alturas e expansão de texto longo, paginação real do PDF, fonte
ampliada em janelas de 320/560/1200 px, respostas fora de ordem, fechamento da
tela durante requisição, erro de atualização e cancelamento de salvamento.
Os testes de ordenação também verificam ambos os modos, reabertura da tela,
limites da primeira/última posição e seleção de todos os campos sem perder a
ordem personalizada.

Arquivos: `backend/tests/test_form_print_options.py`,
`backend/tests/test_reports_dashboard.py`, `client/test/form_document_test.dart`
e `client/test/blank_forms_view_test.dart`.

## Conferência visual e limites

Foram geradas amostras dos três modelos com todas as colunas em paisagem e com
subconjuntos em retrato. Os PDFs automáticos ficaram em uma página. A leitura
visual das amostras de pagamentos e contas a pagar confirmou cabeçalhos legíveis,
proporções de colunas e espaços para escrita, com margens e assinaturas.

O XLSX configura impressão e quebras, mas a paginação do Excel pode diferir da
do PDF por suas métricas de fonte e renderização. A geração estima a altura
necessária para textos longos, mantendo a altura configurada como mínimo.
Impressoras podem limitar margens pequenas. Não houve impressão física ou
validação do seletor de destino em aparelho Android; compilação e testes não
substituem essa conferência em equipamento.

As rotas configuradas exigem o backend atualizado junto com o novo cliente.
O fluxo de seleção de impressoras e os testes adicionais estão registrados na
[análise Wi-Fi/Android](IMPRESSAO_WIFI_E_ANDROID.md).
Para compilar o cliente, são necessários Flutter 3.44+ e Dart 3.12+, conforme as
dependências declaradas em `client/pubspec.yaml`.
