# Relatórios, exportações e impressão

Revisão: **15/10/2026**. [Índice](README.md).

## Para que serve e interface

Em **Relatórios**, selecionar o relatório, conferir seus filtros e consultar/exportar. A tela atual oferece vendas; compras e movimentações; contas a receber; contas a pagar; estoque atual e contagem física; resultado financeiro gerencial.

Em **Formulários em Branco**, escolher os modelos ativos A (fiado), B (contas a pagar) e D (inventário), com opções disponíveis de preenchimento e linhas. Esses documentos servem para consulta ou anotação manual; escrever no papel não atualiza o sistema.

Na tela **Formulários A4 para Impressão**, os dois modos permitem marcar quais
colunas serão incluídas no PDF e no XLSX. Pelo menos uma coluna deve permanecer
selecionada. Campos desmarcados também saem dos totais apresentados. As escolhas
ficam salvas neste dispositivo por modelo e são compartilhadas entre os modos
vazio e preenchido. **Restaurar padrão automático** volta a selecionar todos os
campos e restaura a configuração inicial.

A coluna **Data do pagamento** está disponível nos modelos de fiado e contas
a pagar, nos modos vazio e preenchido, com o mesmo nome no PDF e XLSX. No modo
preenchido, continua mostrando o pagamento confirmado mais recente; o histórico
individual é preservado. **Observações** permanece disponível para anotações,
sem preenchimento automático de detalhes adicionais de pagamentos.

Em **Ordem das colunas**, usar as setas para cima e para baixo para reorganizar
os campos selecionados. O primeiro item da lista será a primeira coluna à
esquerda no documento. A mesma sequência é usada na prévia, no PDF e no XLSX,
nos modos vazio e preenchido, e fica salva por modelo. **Selecionar todas**
mantém a ordem escolhida e acrescenta os campos ausentes ao final. Um campo
desmarcado e marcado novamente também volta ao final. **Restaurar ordem padrão**
reorganiza somente os campos selecionados, sem alterar as outras configurações.

O padrão usa papel A4, margens de 15 mm, fonte de 9 pt e linhas de pelo menos
9 mm. A orientação automática escolhe retrato para até cinco colunas e paisagem
para mais colunas. No modo vazio, o total automático de linhas reserva espaço
para cabeçalho, tabela e assinaturas e cabe em uma página nos modelos padrão.
É possível definir um total manual de 1 a 500 linhas, distribuído em páginas.
Com ajustes personalizados, o cliente valida a quantidade automática no PDF
real e reduz linhas se o cabeçalho exigir mais altura. A planilha recebe essa
mesma quantidade resolvida, além das outras opções de apresentação.

O operador pode ajustar orientação, cada margem (5–40 mm), altura mínima das
linhas (6–30 mm), fonte (8–16 pt), assinaturas e larguras proporcionais de colunas
(0,5–8). O valor de largura divide a área disponível entre as colunas; não é uma
medida em milímetros. Texto preenchido pode aumentar a altura de uma linha no
PDF. A prévia e o resumo mostram a paginação real do PDF após os ajustes.
Margens inferiores a 15 mm dependem da área imprimível da impressora.

**Salvar PDF** e **Salvar planilha XLSX** abrem o seletor nativo de destino. Um
cancelamento não produz mensagem de sucesso. O XLSX recebe papel, orientação,
margens, altura de linhas, larguras, repetição de cabeçalhos e quebras de página.
O Excel pode paginar texto longo de maneira diferente do PDF; conferir também a
prévia do Excel ao imprimir a planilha. O visualizador PDF conserva a orientação
escolhida para o documento.

Na prévia, **Imprimir / Selecionar impressora** abre a janela de impressão do
app. No Android, a descoberta é feita pela janela nativa do sistema; o app não
tenta listar impressoras por uma API de enumeração não suportada nessa
plataforma. Há acesso às configurações de impressão e uma página de teste A4.
No Windows, impressoras cadastradas são listadas quando o sistema oferece essa
capacidade. A consulta com erro não remove o caminho de impressão nativa.
Consultar [a análise de compatibilidade Wi-Fi/Android](IMPRESSAO_WIFI_E_ANDROID.md)
e o [guia de configuração](MANUAL_IMPRESSAO_EPSON.md).

## Backend e banco

O `ReportsService` consulta `/reports/...`. O relatório de vendas da tela usa a rota histórica `sales-dispatches` com `include_dispatches=false`; o nome da rota não significa que a tela voltou a mostrar expedição. Outros tipos usam `purchases-movements`, `receivables`, `payables`, `physical-inventory` e `business-financial-summary`.

O backend monta metadados, colunas, linhas e totais. CSV e XLSX são produzidos pelos exportadores do servidor via `/reports/{tipo}/export`. PDF e a prévia de impressão são construídos no cliente com os serviços de PDF, usando os dados recebidos. Formulários consultam `/reports/blank-templates/{tipo}` e sua exportação quando aplicável.

A exportação configurada usa `POST /reports/blank-templates/{tipo}/export`, com
autenticação de dispositivo, o resultado já carregado na tela e as opções de
apresentação. O servidor valida modelo e colunas e renderiza o XLSX sem consultar
novamente os dados comerciais ou gravar no banco. Assim, PDF e XLSX partem da
mesma consulta, inclusive se houver alterações posteriores no sistema. As rotas
GET anteriores continuam disponíveis para clientes antigos.

Nos formulários preenchidos de fiados e contas a pagar, títulos cancelados ficam
fora da lista e dos totais operacionais. Ausência de dados retorna zero registros,
sem linhas fictícias de auditoria. Contas a pagar traz valor original, valor pago,
saldo e observações em campos próprios. A data de pagamento representa o último
pagamento confirmado; o valor recebido/pago é acumulado. O formulário de fiados
não inclui vendas à vista sem recebível. A contagem física cobre o saldo atual
da loja de produtos e cestas ativos, sem controle de lote ou validade.

As consultas leem as tabelas do fluxo correspondente: vendas e itens, compras e movimentos, títulos e pagamentos, produtos e estoque. Consultar, exportar ou imprimir não grava operações comerciais no banco.

## Exemplo e limites

Um relatório de vendas de um mês seleciona as operações daquele período. Já o relatório de inventário apresenta posição atual: não deve ser interpretado como reconstrução automática do saldo em uma data passada. No financeiro, ver as distinções entre operações do período e pendências atuais em [Dashboard e financeiro](DASHBOARD_E_FINANCEIRO.md).

Salvar um PDF conserva uma cópia da consulta naquele momento. Um recebimento confirmado depois não modifica o arquivo exportado. Imprimir depende da configuração e dos drivers da plataforma; a API não confirma que uma impressora física entregou a folha.

As rotas de relatórios de montagem e expedição continuam no backend, mas não são opções da tela ativa. Ver [Funções arquivadas](FUNCOES_ARQUIVADAS.md).

## Onde conferir

- [Relatórios](../client/lib/views/reports_view.dart), [formulários](../client/lib/views/blank_forms_view.dart), [serviço](../client/lib/services/reports_service.dart), [prévia PDF](../client/lib/views/pdf_viewer_screen.dart) e [construtor PDF](../client/lib/utils/report_pdf_builder.dart).
- [Opções de impressão](../client/lib/models/form_print_options.dart), [PDF configurável](../client/lib/utils/form_pdf_builder.dart), [salvamento](../client/lib/services/document_file_service.dart), [contrato do exportador](../backend/app/schemas/form_print.py) e [testes de configuração](../backend/tests/test_form_print_options.py).
- [API](../backend/app/api/v1/reports.py), [consultas](../backend/app/services/reports.py), [exportadores](../backend/app/services/report_exporters.py).
- [Manual Epson](MANUAL_IMPRESSAO_EPSON.md), [testes de relatórios](../backend/tests/test_reports_dashboard.py) e [vendas sem expedição](../backend/tests/test_sales_only_report.py).
