# Evidência da correção de importação — 19/10/2026

## Continuação: ativação e requisitos de alocação

[Ativação verificada](ativacao.json), [runtime HTTPS](runtime-https.json) e
[resultado e hashes da continuação](continuidade.json), além do
[contrato/limites das alocações](../../ALOCACOES_DE_FATURA.md). Os resultados da
etapa anterior abaixo permanecem como evidência histórica imutável em
`resultado.json`; o registro novo não os apresenta como execução repetida.

- Conferência dos **136 arquivos** Flutter e hashes do backend da etapa anterior;
  nenhuma fonte Flutter mudou. Os 16 arquivos do Release foram copiados para a
  pasta usual `client/build/windows/x64/runner/Release/`, com hashes iguais e
  Release anterior preservado em `tmp/`. Executável correspondente iniciado.
- Backup privado íntegro/FKs verificadas em `backend/backups/`. Schema já em
  fe4, sem migração aplicada. Servidor Python reiniciado e dono da porta 8000
  identificado no novo processo; HTTPS/contrato novo conferidos. Tabelas de
  negócio iguais ao backup; conexão do cliente só alterou `paired_devices.last_seen_at`.
- Sete PDFs autorizados usados como amostras em banco descartável, servidor
  HTTPS real e worker PDF separado. Extrato: 28 ocorrências, confirmação como
  evidência, revisão/replay, conciliação parcial, bloqueio de excesso/sentido
  incorreto e anulação sem reverter dinheiro. Livros comerciais inalterados.
- Demais seis PDFs: confirmação bloqueada, preservando os impedimentos
  conhecidos. `pdf_2` conserva adicionalmente `PDF_SOURCE_TYPE_MISMATCH` porque
  a ferramenta usa o tipo da origem anteriormente cadastrada; a releitura antiga
  escolhia o tipo detectado. Isso não é novo defeito do leitor nem homologação de
  novo layout. Os aliases conservam a ordem de criação dos documentos.
- Diagnóstico de alocação somente da API: oito testes sintéticos novos, mais
  verificação HTTPS de crédito sem alvo e geração ainda bloqueada. Backend
  completo: **488 aprovados, 14 avisos anteriores, 95,65 s**. Log privado
  `tmp/fi-allocation-backend-final.log`. Flutter/análise/build anteriores
  reaproveitados por hashes; não reexecutados sem mudança.
- `pip check` aprovado. Runtime certificado nesta rodada é Python/venv;
  backend congelado continua indisponível para PDF. O app nativo foi iniciado,
  mas não houve interação visual nativa ponta a ponta nem certificação física.

Ferramenta: `scripts/verify_financial_runtime.py --source-db backend/data/estoque.db
--report <relatorio.json>`, executada com o Python do backend. O banco de entrada
é aberto em `mode=ro` para obter somente os PDFs/tipo de origem. O destino é
sempre criado por `TemporaryDirectory`, migrado e descartado, sem opção para
escolher banco operacional de destino. O relatório contém aliases/contagens/
códigos, sem texto bancário, valores, contas, tokens ou originais. O caso de
alocação é inteiramente sintético. Não é oráculo independente de todas as linhas.

Não houve exclusão, pagamento ou estorno dos testes na base original. Sua
recuperação contábil não é pendência. Próximo: plano persistido e confirmado de
créditos contra alvos da mesma fatura; demais casos e mapeamento assistido ainda
exigem os contratos detalhados no guia. Sem commit/publicação.

**Esclarecimento do usuário — 19/10/2026, após a entrega:** os PDFs enviados e
os dados bancários importados eram exclusivamente testes. Os lançamentos gerados
não têm valor de histórico financeiro a recuperar. Usar os PDFs disponíveis como
amostras para testar o aplicativo; não criar trabalho de preservação/recuperação
contábil dessas importações. Os registros financeiros de teste são descartáveis.
Isso não se estende a estoque, vendas, cadastros ou outros dados do aplicativo.
Nenhuma exclusão foi executada nesta atualização documental.

[Guia do comportamento e limites](../../CORRECAO_IMPORTACAO_FINANCEIRA_2026-10-19.md).
[Resultado e hashes](resultado.json). [Fontes da cópia de build](fontes-build.json).

## Resultados finais

| Verificação | Resultado |
| --- | --- |
| Backend completo | **480 aprovados**, 14 avisos de depreciação já existentes |
| Flutter completo | **367 aprovados** |
| `flutter analyze` | **No issues found** |
| Windows Release | Compilado em cópia isolada, sem substituir o app aberto |
| Correspondência de fontes | **136 arquivos** da cópia de build iguais aos arquivos do projeto e aos hashes registrados |
| Banco da empresa | Nenhuma escrita, migração, estorno ou importação de teste |

Comandos usados, a partir das respectivas pastas:

```powershell
# backend/ — fixtures apontam para bancos descartáveis
.\.venv\Scripts\python.exe -m pytest -q
# client/
flutter analyze
flutter test
# cópia tmp/fi-client-20261019/
flutter pub get
flutter build windows --release
```

Última execução backend: `480 passed, 14 warnings in 93.25s`. Logs locais:
`tmp/import-fix-backend-full-final3.log`,
`tmp/import-fix-flutter-full-final2.log`,
`tmp/import-fix-analysis-clean2.log`,
`tmp/import-fix-build-windows-final.log`.
O primeiro teste backend no sandbox não conseguiu criar o diretório temporário;
execuções seguintes autorizadas usaram as mesmas fixtures isoladas. Uma tentativa
posterior de execução foi recusada por limite de uso da revisão automática antes
de iniciar; após a retomada autorizada, a execução final acima terminou com sucesso.
Nenhum bloqueio de aprovação foi contornado.

Os casos positivos existentes de fatura empresarial/pessoal/encargos e vínculo
com compra continuam passando. Os casos novos verificam que as falhas conhecidas
não criam efeitos incompletos, incluindo compensação numérica sem alocação de
saldo anterior/pagamento. Extrato revisado e conciliado reutiliza dinheiro
existente; a rota antiga de lançamento não cria novas entradas de caixa.

Os 14 testes de caracterização da
[auditoria anterior](../auditoria-2026-10-19/test_caracterizacao.py) são evidência
histórica de defeitos: passar significava reproduzi-los. Não fazem parte da suíte
de aceitação atual. As regressões corrigidas estão em
`backend/tests/test_financial_import_safety.py` e nas demais suítes financeiras.

## Capturas sintéticas

Capturadas por testes de widgets com `PDF_IMPORT_CAPTURE=true`; fontes Segoe UI,
Segoe UI Semibold e Material Icons carregadas do ambiente de desenvolvimento.
Não contêm documentos, contas ou transações da empresa. As primeiras capturas
sem todas as fontes não foram usadas como prova visual; estes arquivos são os
resultados atualizados após carregar as famílias necessárias.

| Arquivo | Condição |
| --- | --- |
| [Revisão do extrato](bank-review-safe.png) | 390 × 844, tema claro |
| [Correspondência ao movimento](bank-link-safe.png) | 390 × 844, tema claro |
| [Cabeçalho CSV de conta](csv-bank-header-safe.png) | 390 × 844, validação de campos vazios |
| [Cabeçalho CSV de cartão](csv-card-header-safe.png) | 390 × 844, validação de campos vazios |
| [Conta ampliada](csv-bank-narrow-enlarged.png) | 320 × 780, tema escuro, texto 1,7×, conteúdo rolado |
| [Cartão ampliado](csv-card-narrow-enlarged.png) | 320 × 780, tema escuro, texto 1,7×, conteúdo rolado |
| [Ocorrência ampliada](bank-occurrence-narrow-enlarged.png) | 320 × 780, tema escuro, texto 1,7×, conteúdo rolado |

Inspeção identificou botão cortado com texto ampliado; o formulário passou a usar
ação no conteúdo rolável e o botão de identidade recebeu alinhamento/padding
adequados. Rótulos e erros monetários ajustados para ampliação. Os testes
verificam ausência de exceções de layout e ações sem mutação automática.
Estas amostras não certificam todos os pixels/telas, teclado nativo, TalkBack,
VoiceOver ou aparelhos físicos.

## Releitura dos originais sem escrita na empresa

[Relatório sanitizado](releitura-sanitizada.json): apenas aliases, quantidades,
adaptadores e códigos de impedimento, sem nomes, valores ou texto de transações.

Dos 7 PDFs armazenados, o extrato conhecido com 28 ocorrências continua sem
impedimento. Duas faturas são bloqueadas por diferença resumo/detalhes, duas
compilações por controles/ciclos/linhas e duas não têm leitor reconhecido.
Extrações e renderizações privadas permanecem em `tmp/`, fora desta evidência.
Não se alteraram as prévias antigas para obter esse resultado.

Isto não é transcrição independente de todas as linhas, homologação universal
nem validação contábil dos 89 vínculos/28 movimentos de teste. O esclarecimento
posterior do usuário retirou a recuperação contábil desses testes da continuidade.

## Binário e ativação

Pasta completa: `tmp/fi-client-20261019/build/windows/x64/runner/Release/`.
Executável: `zm_cesta_basica_client.exe`, SHA-256:

```text
a2cf8c6098391fc9db15911d0ac4e6bb84c2afef560b6d99885d9582a2851596
```

As 16 dependências/arquivos da pasta Release devem permanecer juntos. É build de
verificação: aplicativo aberto e servidor em execução foram preservados.
Servidor e cliente correspondentes, backup verificado e runtime PDF precisam ser
conferidos na ativação. Nenhum instalador/backend congelado foi certificado.
O código novo não corrige silenciosamente títulos ou movimentos já gerados.
