# Relatório de análise — Formulários A4 para Impressão

Data: 14/10/2026.

**Parecer:** a área tem uma base útil, mas precisa de correções de conteúdo e de geração dos documentos antes do refinamento visual. Foram confirmadas inconsistências que podem confundir uma conferência financeira, desperdiçar papel e produzir arquivos diferentes do que o operador espera.

Análise baseada na imagem enviada, no código atual do cliente Flutter e do backend, na documentação do projeto, em testes existentes e em amostras geradas pelo construtor real de PDF. Os testes exploratórios usaram dados sintéticos e banco SQLite em memória. Não houve alteração de código funcional, de regras de negócio ou do banco da empresa.

## 1. Escopo e funcionamento atual

Os três modelos ativos são pagamentos/fiados, contas a pagar e contagem física de estoque. Cada um oferece modo em branco e modo preenchido. O formulário de expedição permanece apenas no backend, conforme o escopo arquivado do projeto; sua ausência na interface não é um defeito.

O fluxo atual é:

1. Escolher o modo e o modelo.
2. Consultar o servidor, inclusive para um formulário vazio.
3. No modo em branco, escolher de 10 a 25 linhas, inicialmente 16.
4. Abrir uma segunda tela para visualizar/imprimir o PDF, ou solicitar o XLSX.

O PDF usa os dados já carregados na tela. O XLSX faz outra consulta ao servidor. As duas saídas têm implementações e configurações independentes.

Referências: [tela](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:19>), [serviço do cliente](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/services/reports_service.dart:55>), [consulta dos formulários](</C:/Users/jardi/Desktop/ZM CESTA BASICA/backend/app/services/reports.py:1368>).

## 2. O que está bem encaminhado

- A finalidade operacional é clara: apoiar a rotina de papel, caneta e conferência.
- A divisão entre documento vazio e preenchido é adequada.
- Os três modelos correspondem às funções ativas do aplicativo.
- O PDF é gerado dentro do cliente e tem tabela, identificação da empresa, campos de assinatura e paginação.
- No formulário vazio, a altura mínima de 26 pontos equivale a aproximadamente 9,2 mm, coerente com a proposta de escrita manual.
- A integração de impressão utiliza os serviços do sistema operacional.
- O backend consulta dados existentes, sem transformar a impressão em lançamento de vendas, pagamentos ou ajustes de estoque.

Esses componentes podem ser aproveitados na evolução da área.

## 3. Problemas prioritários de conteúdo e confiabilidade

### 3.1. Títulos cancelados aparecem como abertos — prioridade crítica

As consultas dos modelos preenchidos de pagamentos e contas a pagar buscam todos os títulos, sem excluir ou distinguir os cancelados. A tradução do estado só reconhece `PAID` e `PARTIAL`; qualquer outro valor recebe `[   ] ABERTO`.

**Reprodução:** um recebível cancelado de R$ 123,45 entrou no formulário como aberto e somou R$ 123,45 ao valor original total. Uma conta a pagar cancelada de R$ 678,90 também apareceu como aberta e entrou no total. Com saldo zero, essa conta ainda trouxe a observação “Liquidado”, contradizendo seu próprio estado na linha.

Isso pode induzir cobrança ou conferência equivocada. O formulário deve adotar uma regra explícita: excluir cancelados da visão operacional ou incluí-los com identificação inequívoca e totais separados. Não é necessário apagar nenhum histórico para corrigir essa apresentação.

Referências: [recebíveis](</C:/Users/jardi/Desktop/ZM CESTA BASICA/backend/app/services/reports.py:1407>), [contas a pagar](</C:/Users/jardi/Desktop/ZM CESTA BASICA/backend/app/services/reports.py:1464>).

### 3.2. Ausência de dados vira “15 registros” — prioridade alta

Quando a consulta não encontra linhas, o backend cria 15 linhas vazias, inclusive no modo preenchido, e informa `total_rows=15`.

**Reprodução:** os três modelos preenchidos, em banco vazio, retornaram 15 registros com todas as células vazias. A tela usa esse número no selo de auditoria.

A interface precisa distinguir “nenhum registro encontrado” de “formulário com linhas disponíveis para escrever”. A geração de linhas vazias deve ser uma configuração do documento manual, sem fabricar a contagem de dados de uma auditoria.

Referência: [fallback de linhas e metadados](</C:/Users/jardi/Desktop/ZM CESTA BASICA/backend/app/services/reports.py:1609>).

### 3.3. Possibilidade de usar dados de uma seleção anterior — prioridade alta

A tela mantém `_loadedReport` durante uma nova consulta. Se ela falha, o relatório anterior continua em memória. Os botões consideram a existência desse relatório e o carregamento, mas não bloqueiam por erro nem verificam se o resultado pertence ao modelo/modo selecionado.

Além disso, as trocas de seleção podem disparar requisições concorrentes. Não há identificador de requisição que impeça uma resposta antiga de substituir a nova. Após a espera, `_loadFormData` também chama `setState` sem verificar `mounted`.

São falhas verificadas na lógica; não foi feita reprodução interativa com atraso de rede. Devem ser corrigidas com estado vinculado à seleção, descarte de respostas antigas e tratamento do fechamento da tela.

Referências: [carregamento](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:64>), [habilitação das ações](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:342>).

### 3.4. PDF e XLSX não representam necessariamente a mesma consulta

O PDF imprime o resultado carregado anteriormente; o XLSX busca os dados novamente. Se houver uma confirmação ou cancelamento entre as duas ações, os arquivos podem divergir.

Para conferência, é desejável apresentar o instante da consulta e definir se as saídas usam o mesmo conjunto de dados ou se cada exportação atualiza a consulta. Hoje isso não é explicado ao operador.

## 4. Impressão e qualidade do papel

### 4.1. O padrão de 16 linhas gera uma segunda folha quase vazia — prioridade alta

Foram gerados PDFs reais dos três modelos com 10, 16 e 25 linhas:

| Modelo | 10 linhas | 16 linhas, padrão | 25 linhas |
| --- | --- | --- | --- |
| Pagamentos | 1 página | 2 páginas | 2 páginas |
| Contas a pagar | 1 página | 2 páginas | 2 páginas |
| Contagem física | 1 página | 2 páginas | 2 páginas |

No modelo de pagamentos com 16 linhas, a primeira página contém 15 linhas de preenchimento e a segunda somente uma, além das estruturas do documento. O usuário não recebe essa previsão ao mover o controle.

A quantidade deveria indicar claramente se é total ou por página. O sistema deve calcular a capacidade da folha, informar quantas páginas serão usadas e oferecer uma opção de preencher uma página com espaçamento confortável.

### 4.2. A largura das colunas não acompanha sua função

O construtor deixa a distribuição a cargo da largura intrínseca do conteúdo. Na amostra de pagamentos, “Qtd” quebrou em “Qt” e “d”, e “Observações” também foi partida. Cliente, tipo de cesta e observações precisam de proporções pensadas para escrita; quantidade e datas podem usar medidas menores e previsíveis.

Altura confortável, sozinha, não garante um bom formulário manual. A avaliação deve considerar se um nome e uma observação reais cabem nas células.

### 4.3. Margens menores que o padrão documentado

Os PDFs usam 36 pontos, aproximadamente 12,7 mm. A arquitetura do projeto define mínimo de 15 mm. A diferença não comprova corte em toda impressora, mas mostra divergência entre implementação e requisito interno.

Referências: [margens do PDF](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/utils/report_pdf_builder.dart:310>), [requisito de impressão](</C:/Users/jardi/Desktop/ZM CESTA BASICA/ARCHITECTURE.md:368>).

### 4.4. Orientação oferecida sem efeito na construção

O visualizador permite mudar a orientação, mas os callbacks da tela ignoram o `format` recebido. No modo vazio, a orientação é sempre paisagem; no preenchido, depende da quantidade de colunas. Assim, a configuração oferecida pelo visualizador não controla o documento como deveria.

Referências: [callbacks](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:119>), [visualizador](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/pdf_viewer_screen.dart:241>).

### 4.5. Modo preenchido perde espaço para anotação

O PDF preenchido usa o construtor de relatório genérico, com texto pequeno e altura de linha determinada pelo conteúdo. Não conserva a altura mínima de 26 pontos do formulário vazio. Isso é especialmente inadequado para o inventário, que deixa quantidade física, diferença e assinatura em branco justamente para preenchimento posterior.

O modo preenchido deve ter um template próprio de conferência, preservando espaço manual onde necessário.

## 5. Planilha XLSX e salvamento

### 5.1. Três contagens diferentes para o mesmo formulário

- A interface começa com 16 linhas e permite escolher entre 10 e 25.
- O JSON do backend retorna 15 linhas vazias.
- O XLSX em branco gera sempre 20 linhas.

A quantidade escolhida não é enviada na exportação XLSX. Isso foi confirmado abrindo as planilhas produzidas pelo exportador real.

### 5.2. XLSX sem preparação explícita para impressão A4

Nas três planilhas inspecionadas, tamanho do papel, orientação e repetição de cabeçalho estavam sem configuração explícita. O exportador também não define ajuste de largura a uma página. As larguras são calculadas pelo comprimento dos textos, inclusive assinaturas.

O Excel pode usar suas configurações padrão e distribuir a tabela em várias folhas. A experiência de impressão da planilha precisa ser configurada e validada separadamente da do PDF.

Referência: [exportador XLSX](</C:/Users/jardi/Desktop/ZM CESTA BASICA/backend/app/services/report_exporters.py:200>).

### 5.3. O fluxo de download usa uma função destinada a PDF

O XLSX é entregue a `Printing.sharePdf`, e o retorno booleano é ignorado antes de mostrar sucesso. Na implementação instalada do pacote, o Windows grava um arquivo temporário e tenta abri-lo no aplicativo associado. No Android, o compartilhamento usa o tipo `application/pdf`, inadequado para XLSX.

Isso não significa que o arquivo gerado esteja corrompido; o problema está na entrega, na identificação do formato e na mensagem de sucesso. Deve haver salvamento/compartilhamento apropriado para XLSX, com cancelamento e falha tratados corretamente.

O PDF também usa o compartilhamento como caminho de “salvar”, sem uma ação própria de escolher destino nessa tela. A impressão e o compartilhamento têm poucos tratamentos explícitos de exceção, e erros na enumeração de impressoras são apresentados como lista vazia.

Referências: [download XLSX](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:84>), [impressão e compartilhamento](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/pdf_viewer_screen.dart:17>).

## 6. Adequação de cada modelo ao trabalho real

**Pagamentos/fiados:** o modo preenchido usa `SalesReceivable`, portanto representa os títulos de fiado. A descrição da tela menciona recebimentos à vista ou a prazo, mas as vendas à vista sem recebível não entram nessa consulta. O nome deve comunicar esse limite. A coluna de data usa o último pagamento confirmado, enquanto “Valor recebido” é o acumulado. Convém explicitar “Último pagamento” e “Total recebido”, ou oferecer histórico quando esse for o objetivo. Códigos como `CREDIT_TERM` aparecem em observações sem tradução.

**Contas a pagar:** há apenas valor original em coluna própria. Valor pago não é exibido, e saldo fica em observações. Isso prejudica a leitura de pagamentos parciais e ocupa o lugar de anotações/NF; a arquitetura prevê valor pago e saldo restante. O total `amount_cents` recebe o rótulo genérico “Resultado Líquido” no PDF, embora represente a soma dos valores das contas. O saldo em observações também usa formatação com ponto decimal no backend.

**Contagem física:** o modelo traz produtos e cestas ativos com saldo da loja e deixa campos de conferência vazios. É uma boa base. A descrição fala em verificar validades, mas não há campos de lote ou validade. Essa promessa deve ser ajustada ao escopo existente. Pode ser útil oferecer contagem sem revelar o saldo do sistema, sem transformar isso em requisito obrigatório. Anotações no papel não atualizam o estoque; essa informação precisa estar visível ao operador.

## 7. Usabilidade e aparência da tela

A imagem mostra uma sequência compreensível, mas o peso visual está mal distribuído:

- O cartão amarelo ocupa bastante espaço para explicar uma qualidade que deveria ser percebida no documento. Seu tamanho e cor competem com a tarefa principal.
- Textos como “Ergonomia de Preenchimento Manual em Prancheta” e “Modelo de Formulário / Tabela” são longos para decisões simples.
- O cartão inferior lista colunas como chips. Ele informa a estrutura, mas não mostra a folha, a largura das células nem as páginas resultantes.
- Há uma área grande disponível abaixo, que poderia mostrar uma prévia real na configuração da imagem.
- O controle deslizante é pouco preciso para escolher um número inteiro; campo numérico com incremento e decremento seria mais direto.
- O botão continua dizendo “Baixar Modelo XLSX Vazio” no modo preenchido, pois o texto não depende do modo.
- Não há filtros por período, cliente, fornecedor ou estado nessa área; o modo preenchido consulta o conjunto completo de registros.
- O botão atualizar não explica se atualiza dados ou configuração. Para formulário vazio, a consulta de rede é uma dependência que poderia ser reduzida com modelos disponíveis localmente.

A responsividade também merece revisão: títulos longos e o controle de linhas usam `Row` com textos sem adaptação suficiente. Em telas menores e com fonte ampliada, há risco de transbordamento. Isso foi identificado no código, sem teste interativo em Android. Há cores fixas e textos fora do catálogo de tradução; o suporte a tema escuro e acessibilidade precisa de verificação específica.

Uma organização recomendada é: escolher o documento, escolher vazio/preenchido, ajustar as opções pertinentes, conferir a folha real e executar a ação. No desktop, configuração e prévia podem ficar lado a lado; no celular, em sequência. As ações podem permanecer no fluxo da tela, respeitando as preferências atuais do projeto.

Referências: [configuração](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:288>), [resumo de colunas](</C:/Users/jardi/Desktop/ZM CESTA BASICA/client/lib/views/blank_forms_view.dart:372>).

## 8. Manutenção, desempenho e consistência

Os modelos e rótulos estão distribuídos pela tela Flutter, pelo serviço Python e pelo exportador XLSX. A configuração `filledReportType` existe na tela, mas não é utilizada. Essa duplicação facilita divergências como as de contagem de linhas e nomes.

As consultas preenchidas carregam todos os registros e fazem consultas adicionais por título ou item. Com crescimento do histórico, o padrão de múltiplas consultas pode deixar a geração mais lenta. Não foi realizado teste de carga, portanto não há medição de lentidão atual.

A formatação também está dividida entre prévia, PDF e XLSX. Há interpretação diferente de valores monetários `double` entre prévia e PDF, embora o contrato atual preveja centavos inteiros. Datas e emissão não fazem conversão explícita para horário local nesses caminhos; timestamps UTC podem aparecer com horário diferente do esperado pelo operador. A correção deve distinguir datas de vencimento de instantes com horário.

É recomendável concentrar o contrato dos modelos, as opções de impressão, os rótulos de estados e as regras de apresentação, preservando os serviços de domínio existentes.

## 9. Verificação realizada e limites

- **Backend:** 3 testes existentes aprovados, cobrindo modelos vazios, exportação preenchida e ausência de lançamentos comerciais nas consultas verificadas.
- **Flutter:** 7 testes existentes do construtor PDF aprovados. Houve avisos de suporte Unicode das fontes padrão.
- **Exploração:** geração de 9 PDFs vazios, 3 PDFs preenchidos sem registros, inspeção de 3 XLSX vazios e reprodução de títulos cancelados com dados sintéticos.
- **Inspeção visual:** primeira e segunda páginas do formulário de pagamentos com 16 linhas e inventário preenchido sem registros.

Os testes atuais confirmam geração de arquivos e formato básico, mas não garantem qualidade da paginação, exclusão/identificação de cancelados, contagem correta de dados, resposta a trocas rápidas, salvamento real ou responsividade. No Flutter, boa parte das asserções verifica apenas a assinatura `%PDF-` e o tamanho dos bytes.

Não houve impressão física, teste de driver Epson, compartilhamento em dispositivo Android, validação completa de teclado/leitor de tela ou teste de carga. As observações sobre esses ambientes são derivadas do código, não de uma homologação em equipamento.

## 10. Ordem de melhoria recomendada

| Ordem | Entrega | Resultado esperado |
| --- | --- | --- |
| 1 | Corrigir cancelados, vazio real e coerência da seleção | Conferência com dados e estados confiáveis |
| 2 | Unificar opções de PDF/XLSX e corrigir salvamento | Arquivos compatíveis com a escolha do operador |
| 3 | Rever paginação, margens, orientação e larguras | Impressão previsível e papel adequado para caneta |
| 4 | Adequar os campos e nomes dos três modelos | Documentos fiéis à rotina de fiado, despesas e inventário |
| 5 | Mostrar prévia real e adaptar o layout | Configuração mais simples em Windows e Android |
| 6 | Adicionar filtros e otimizar consultas | Utilidade e desempenho com histórico maior |

Critérios para considerar a revisão pronta: cancelados nunca aparecem como pendência comum; ausência de dados informa zero registros; o documento corresponde à seleção atual; PDF e XLSX respeitam suas opções anunciadas; a quantidade de páginas é conhecida antes da impressão; colunas e linhas permitem escrita real; cancelar salvamento não mostra sucesso; e os três modelos funcionam em janela estreita e fonte ampliada.

**Conclusão:** a proposta é adequada e os componentes existentes são aproveitáveis. A prioridade deve ser tornar o conteúdo correto e a impressão previsível, acompanhadas de uma interface mais simples e de uma prévia fiel ao papel.
