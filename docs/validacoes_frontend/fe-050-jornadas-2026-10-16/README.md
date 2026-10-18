# FE-050 — Inspeção das jornadas e saúde do projeto

Data: **16/10/2026**. Ver o
[contrato consolidado](../../JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md).

## Alcance

Leitura das telas/serviços Flutter, cliente HTTP, schemas, rotas, serviços e
idempotência do backend, resumo do negócio e testes financeiros existentes.
[Fontes e hashes](fontes-inspecionadas.json) identificam o conteúdo local lido;
os marcadores indicam funções relevantes. Inspeção delimitada, sem auditoria de
todos os consumidores, requisições à API da empresa ou teste no app instalado.

Achados: revisão/data/forma ainda diferem da prévia; diálogos não passam chave
estável; servidor possui replay transacional; saldo revisado não faz parte do
request; listas e resumo usam critérios diferentes de atraso. O documento
consolidado separa esses fatos das propostas de integração.

## Verificação

[Resultado resumido](verificacao.json): **363 testes backend aprovados**, com
14 avisos, e **238 testes Flutter aprovados**, antes das edições documentais.
Backend executado com `pytest backend/tests -q`, usando diretório temporário
isolado; Flutter com `flutter test`. Foram usadas as dependências locais do
projeto. Logs completos ficaram em `tmp/fe-050-backend.log` e
`tmp/fe-050-flutter.log`; o arquivo resumido conserva seus hashes e resultados,
sem copiar o conteúdo completo para a documentação.

O manifesto FE-049 foi conferido por SHA-256: seus **18 arquivos** permanecem
iguais. A fonte integrada não foi editada e não houve nova execução visual nesta
rodada. As 180 composições Edge/WebKit são evidência anterior de FE-049.

Suítes existentes não validam novos contratos propostos, recuperação de pagamento
após reiniciar o app, corrida entre operações reais nem integração nativa iOS.
Nenhum código de produção, banco da empresa ou referência histórica foi alterado
por esta rodada. Não foi criado commit Git.
