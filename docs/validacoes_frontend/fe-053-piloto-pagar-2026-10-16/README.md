# FE-053 — Validação do primeiro piloto real de Pagar

**16/10/2026.** Ver o [guia do incremento](../../PILOTO_PAGAR_REVISADO.md).

## Resultados

- Entrada: 414 testes backend e 238 Flutter aprovados.
- Saída: **420 backend / 274 Flutter aprovados**. São seis novos testes backend
  e 36 novos testes Flutter; a suíte responsiva existente continua verificando
  posição do FAB e filtros, com preferências locais vazias explicitamente isoladas.
- Análise estática Flutter: **sem pendências**.
- Compilação Windows **debug** concluída em `client/build/windows/x64/runner/Debug`.
  Não foi executada contra a empresa ou instalada. Usar a pasta completa, com
  DLLs/dados; o executável sozinho não contém o aplicativo.

[Resultado resumido e hashes](verificacao.json) identifica logs temporários,
fontes, artefatos e preservação da prévia FE-052. O teste Flutter dirigido cobre
43 casos contando as verificações responsivas existentes; o backend dirigido
cobre 14 casos contando o ciclo legado de contas a pagar.

## O que foi conferido

Backend: pagamento/quitação, replay antes da precondição, saldo que sobe após
estorno, dia civil → 03:00Z, rejeição de data ambígua, método inválido, hash legado
e atraso por dia de negócio. Banco temporário das fixtures, sem acesso ao banco
da empresa ou criação de movimentos reais.

Cliente: perda da resposta com retomada do estado serializado, chave/corpo/data
idênticos, confirmação persistida sem outro POST, falha local antes/depois do
envio, estado corrompido, status incertos conservados, servidor sem capacidade,
conexão alterada e bloqueio entre dois coordenadores. No fluxo de widgets:
Integral ignora parcial oculto, Editar preserva, calendário/método, saldo alterado
antes/depois da revisão, confirmação com GET falho e carga além de cem contas.

Dimensões dos testes de widgets: 320×740 (100% e 200%), 390×844 (200%, escuro) e
1100×900 (100%). Verificações apontam ausência de exceções de layout observadas;
não são certificação completa de acessibilidade ou desempenho.

## Capturas reais dos widgets Flutter

Todas usam fixtures. Não são outro protótipo HTML, tela do aplicativo instalado
ou prova de gravação no servidor da empresa.

- [Revisão no celular](revisao-celular.png).
- [Retomada após resposta perdida](retomada-celular.png).
- [Confirmação preservada com atualização falha](confirmacao-consulta-falhou.png).
- [320, texto 100%](revisao-320-100.png) e [320, texto 200%](revisao-320-200.png).
- [390, escuro e texto 200%](revisao-390-200-escuro.png).
- [Computador](revisao-computador.png).

## Limites e continuidade

Sem homologação em Android/iPhone físico, leitor de tela real, toque/teclado
nativos em aparelho ou preferência nativa de redução de transparência. O
armazenamento foi testado com a implementação simulada de SharedPreferences;
reinício de coordenador/reconstrução da tela não equivale a reiniciar o processo
no aparelho. A integração TLS/HTTP usa o cliente existente com vínculo de origem;
os testes do fluxo de widgets usam serviço simulado, e o backend usa TestClient.
Não houve execução ponta a ponta no servidor da empresa.

Nenhuma tabela/migração nova, dependência adicionada, commit Git, distribuição
ou substituição da instalação. Workspace já continha mudanças de outras rodadas;
elas foram preservadas. A prévia FE-052 e seus 35 arquivos de manifesto continuam
intactos. A próxima integração é Receber, mantendo seus métodos e efeitos próprios.
