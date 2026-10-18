# FE-054 — Receber revisado e padrão comum financeiro

**17/10/2026.** [Guia do incremento](../../PILOTO_RECEBER_REVISADO.md).

## Resultado final

- Entrada: 420 backend / 274 Flutter aprovados.
- Saída: **436 backend / 319 Flutter aprovados**; 14 avisos backend preexistentes.
- Análise estática: **sem pendências**.
- Windows **debug** compilado; usar a pasta Debug completa, com DLLs e dados.
  Não foi instalado, iniciado contra a empresa ou distribuído.

[Resultados resumidos](resultados.txt) e [verificação com hashes](verificacao.json).
Logs integrais de teste permanecem no diretório temporário do projeto e são
identificados por hash no relatório. Capturas, resultado e relatório têm
[manifesto próprio](manifesto.json). Isso é preservação local, não commit Git.

## Cobertura

Backend: contrato aditivo/capacidade, replay antes da precondição, concorrência
de saldo após estorno, hash legado, métodos próprios, dia civil/03:00Z, atraso
de hoje/ontem, filtro aberto incluindo parciais e preservação de venda/estoque.
Recebimento parcial e estorno foram verificados em banco sintético, mantendo
valor, itens, custos e movimentos da venda.

Cliente: corpo/chave/data idênticos após reiniciar coordenador, recibo já
confirmado sem outro POST ou GET, falha de persistência, dados corrompidos,
origem/fingerprint alterados, capacidade antiga, duas chamadas concorrentes,
recusas versus falhas incertas e separação dos namespaces Pagar/Receber.

Widgets: Integral ignora parcial oculto; forma obrigatória e códigos de Receber;
data, Editar e saldo alterado antes/depois da revisão; venda de origem somente
leitura com erro/retentativa; estorno e motivo; confirmação com GET indisponível;
retomada visível mesmo se a conta quitada sair do filtro; mais de cem títulos;
recorte/paginação preservados e filtros recolhidos; reflow em 320/390/1100 com
texto 100%/200% e tema escuro. O cliente/venda ficam visíveis ao entrar na revisão.

A primeira rodada encontrou inicialização antecipada de l10n e pintura de
controles interativos abaixo da decoração. Depois, a inspeção visual encontrou
offset da revisão herdado do formulário. Foram corrigidos e a suíte final foi
executada sobre a fonte resultante. As contagens finais acima substituem os
resultados intermediários; capturas não substituem asserções financeiras.

## Capturas de widgets com dados fictícios

- [Lista e filtros compactos](lista-filtros-compactos.png).
- [Revisão no celular](revisao-celular.png) e [computador](revisao-computador.png).
- [Tentativa com resposta perdida](retomada-celular.png).
- [Confirmação conhecida; consulta falhou](confirmacao-consulta-falhou.png).
- [Venda de origem](venda-origem-celular.png).
- [320 a 100%](revisao-320-100.png), [320 a 200%](revisao-320-200.png) e
  [390 escuro a 200%](revisao-390-200-escuro.png).

Sombras na rasterização de testes podem diferir do runtime nativo; capturas não
homologam efeito de vidro, métricas de fonte ou preferência de transparência em
aparelho. Quando a altura não comporta texto ampliado, a página continua rolável.

## Limites e continuação

Sem teste físico Android/iPhone, integração nativa iOS, leitor de tela real ou
reinício de processo no aparelho. Testes usam SharedPreferences simulado,
serviços fictícios no cliente e TestClient/bancos temporários no servidor.
Não houve uso do banco da empresa, migração nova, commit ou atualização instalada.
Servidor/cliente correspondentes são necessários para o novo contrato.

Fonte FE-052 e evidência FE-053 preservadas pelos manifestos anteriores. A nova
navegação, Início com períodos, resultado em Negócio, tema global/configuração
de cor e as demais áreas ainda não foram integrados. A lista de Pagar conserva
seus filtros. Próximo recorte: áreas principais e seus resumos reais.
