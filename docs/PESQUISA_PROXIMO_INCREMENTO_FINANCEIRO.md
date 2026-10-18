# Pesquisa e recomendação para o próximo incremento financeiro

Data: **15/10/2026**. Situação: **pesquisa e proposta; sem mudança de código ou migração nesta etapa**.

Atualização posterior: o usuário confirmou alcance multibanco. O incremento
seguinte implementou [CSV configurável, adaptador conhecido e prévias versionadas](IMPORTACAO_CSV_MULTIBANCO.md).
Esta pesquisa registra a recomendação original. A
[correção auditável de decisões concluídas](CORRECAO_REVISAO_FINANCEIRA.md) foi
implementada posteriormente; a revisão global de acesso continua pendente.

## Recomendação

Executar uma revisão de compatibilidade dos contratos e de proteção dos dados, seguida de um **piloto do importador CSV Nubank PJ pela API**, com conferência humana. Depois ampliar para OFX e PDF/faturas. Este refinamento altera a ordem inicial, que começava pela leitura de PDF.

A escolha do CSV é uma decisão para este projeto: o exemplo já consultado contém data, valor, identificador e descrição em colunas. Ele permite avaliar o fluxo inteiro com os documentos disponíveis, antes de acrescentar a interpretação do layout de PDFs. Não se trata de dizer que qualquer CSV terá identificação confiável ou formato universal.

## Referências técnicas e aplicação

### OFX e identidade de transação

A especificação OFX define `FITID` com capacidade de até 255 caracteres e unicidade no escopo da instituição/conta. Também distingue datas de lançamento e de iniciativa da transação. Isso orienta a preservação das identidades e das datas recebidas, com tratamento dos campos ausentes.

Fonte primária: [OFX Banking Specification 2.3, Financial Data Exchange](https://financialdataexchange.org/common/Uploaded%20files/OFX%20files/OFX%20Banking%20Specification%20v2.3.pdf), seção 3.2.3 e descrições dos campos de transação. A versão é identificada explicitamente; não se afirma aqui que seja a versão mais recente de todo o ecossistema.

**Lacuna confirmada no código:** `external_id` está limitado a 200 caracteres no schema de entrada e nas declarações dos modelos. Isso pode recusar um identificador OFX válido. Antes de anunciar compatibilidade OFX, ampliar o contrato, revisar as duas representações de identidade e testar IDs de 255 caracteres.

Outro ponto para revisão: `transaction_date`/`date_kind` classifica uma única data. O próximo contrato deve avaliar a preservação simultânea de data da compra e data do lançamento quando a fonte trouxer ambas, sem inventar campos preenchidos.

### Reconciliação como processo verificável

A documentação de conciliação do Odoo descreve correspondência entre movimentações e documentos/registros comerciais, validação e itens que podem ficar para conferência. É uma referência de fluxo; o mecanismo contábil interno do Odoo não é o mecanismo implementado no ZM.

Fonte primária: [Odoo — Bank reconciliation](https://www.odoo.com/documentation/17.0/applications/finance/accounting/bank/reconciliation.html).

**Aplicação proposta:** manter origem, evidência, sugestão, decisão e efeitos financeiros distinguíveis. Ambiguidades permanecem pendentes. Criar um contrato auditável para corrigir interpretação ou decisão de duplicidade já concluída; hoje as ocorrências concluídas ficam bloqueadas. O desfazimento de uma conciliação de caixa já existente não resolve, por si só, uma identificação de duplicidade incorreta.

### Leitura de PDF

A documentação do pypdf explica que PDFs não oferecem uma estrutura semântica confiável de tabelas e que imagens digitalizadas exigem OCR. Isso torna necessários leitores específicos, validação e verificação dos resultados; extrair texto não equivale a interpretar corretamente uma fatura.

Fonte primária: [pypdf — Extract Text from a PDF](https://pypdf.readthedocs.io/en/stable/user/extract-text.html).

**Aplicação proposta:** começar pelo arquivo estruturado disponível, preservar o PDF para consulta e comparação, e depois criar um leitor de fatura de um emissor. Registrar nome/versão do leitor e procedência dos campos. Não promover data de emissão, subtotal, publicidade ou simulação de financiamento a transação efetiva. Leitor determinístico de CSV/OFX e de layouts conhecidos pode funcionar sem IA.

### Recepção e processamento de arquivos

A OWASP recomenda validação em camadas, limites, permissões e cuidados com armazenamento; cabeçalho de tipo e assinatura do arquivo não bastam isoladamente. Também alerta para vazamento de dados ao enviar arquivos a serviços públicos de análise.

Fonte primária: [OWASP — File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html).

**Aplicação proposta:** revisar os controles já implementados e acrescentar, conforme o leitor escolhido, limites de linhas/campos, codificação, tempo e memória. Para PDF futuro, controlar também páginas e saída extraída. Preservar o original sem executá-lo ou expô-lo como conteúdo ativo. Não enviar documentos bancários a ferramentas públicas de análise.

### Acesso, registros e proteção local

A OWASP recomenda verificar permissões em cada requisição e evitar dados bancários, tokens e segredos em logs comuns. O guia da ANPD aborda controles de segurança e backups protegidos, inclusive recuperação e armazenamento seguro.

Fontes primárias: [OWASP — Authorization](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html), [OWASP — Logging](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html) e [ANPD — Guia de Segurança da Informação para Pequeno Porte](https://www.gov.br/anpd/pt-br/centrais-de-conteudo/materiais-educativos-e-publicacoes/guia-orientativo-sobre-seguranca-da-informacao-para-agentes-de-tratamento-de-pequeno-porte).

**Lacunas já documentadas no projeto:** as rotas novas têm validação explícita de token, mas a política das rotas legadas é diferente; não há novos papéis por usuário nem criptografia de aplicação para SQLite/backups. A revisão deve alcançar também exportação e backup, definir quem consulta/revisa/obtém originais e escolher proteção de armazenamento, chaves e recuperação apropriada à instalação. Uma suíte aprovada não certifica esses pontos.

Definir finalidade, acesso e retenção dos documentos com os responsáveis pelo negócio. Preservação de histórico comercial não significa retenção indefinida de toda cópia de documento pessoal. Mudanças de retenção não devem apagar ou quebrar os registros financeiros.

### Gmail e Open Finance como origens futuras

O Google classifica `gmail.readonly` como escopo restrito. A necessidade de verificação e eventual avaliação de segurança depende da configuração e do uso do aplicativo. Isso exige planejamento próprio da autorização e das credenciais.

Fonte primária: [Google — Choose Gmail API scopes](https://developers.google.com/workspace/gmail/api/auth/scopes?hl=en).

O Banco Central descreve compartilhamento autorizado de dados de contas e cartões pelo Open Finance. Esse é um caminho a avaliar futuramente, considerando instituições participantes e requisitos de integração.

Fonte primária: [Banco Central — Open Finance](https://www.bcb.gov.br/meubc/faqs/s/open-finance).

**Aplicação proposta:** primeiro validar a interpretação e a conciliação. Gmail será um coletor de documentos para o mesmo fluxo; Open Finance, se adotado, outro adaptador. A conexão de Gmail desta conversa não representa autorização ou credenciais instaladas no ZM. Nenhuma dessas integrações torna obrigatória a contratação de IA.

## Próxima entrega proposta

1. **Fechar os ajustes de contrato:** identificação compatível com o formato, datas distintas quando existirem, sinal/centavos, procedência, versão do leitor e correção auditável de interpretações.
2. **Resolver os pontos de acesso prioritários:** incluir rotas legadas, downloads, exportações e backups na análise; documentar permissões e proteção do armazenamento antes de uso operacional de dados reais.
3. **Criar um adaptador CSV Nubank PJ:** reconhecer o layout, validar cabeçalho/codificação, converter valores sem ponto flutuante e preservar identificadores e linhas de origem. Formato desconhecido deve ser informado como incompatível.
4. **Entregar prévia pela API:** apontar erros e candidatos a duplicidade, conferir totais disponíveis e cobertura de período e permitir confirmação explícita. Não exigir o novo design para testar o backend.
5. **Comparar o resultado com o original:** conferir quantidade e valores das operações, sinais, identificadores, datas e diferenças explicáveis. CSV nem sempre contém saldos; não exigir informação que a fonte não trouxe.
6. **Homologar recuperação e repetição:** falha/reinício, reenvio simultâneo, períodos sobrepostos, alterações de layout e restauração. Usar fixtures sintéticas nos testes e revisão controlada dos exemplos reais.
7. **Ampliar o escopo:** OFX, fatura PDF de um emissor, ligação contábil da fatura às dívidas existentes e, depois, coleta por Gmail ou avaliação de Open Finance.

## Critérios de aceite do piloto

- Reimportação não duplica os eventos, inclusive com períodos sobrepostos.
- Operações legítimas iguais continuam distintas.
- IDs completos são preservados; datas e horários ausentes permanecem ausentes.
- Ambiguidades e divergências ficam identificadas, sem ajuste financeiro inventado.
- Interpretação errada pode ser corrigida por fluxo auditado, preservando a anterior.
- Conferir documento não executa pagamento; conciliar evidência não duplica uma saída existente.
- Falha de processamento não deixa efeitos financeiros parciais.
- Backup/restauração conserva originais, decisões e referências.
- O piloto usa a API e respeita os fluxos atuais do aplicativo.

## Situação após a pesquisa

Esta etapa registra recomendações com base em documentação oficial e inspeção do código atual. **Não implementou as correções identificadas, não acrescentou um leitor e não aplicou migração ao banco da empresa.** O guia da implementação existente continua em [Base financeira e conciliação](BASE_FINANCEIRA_E_CONCILIACAO.md).
