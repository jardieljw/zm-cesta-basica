# Validação da limpeza — 13/10/2026

| Verificação | Antes | Depois |
| --- | --- | --- |
| `python -m pytest backend/tests -q` | 183 aprovados | 189 aprovados |
| `flutter test` | 95 aprovados | 98 aprovados |
| `flutter analyze` | Não executado antes | Sem problemas |

Os testes foram executados com acesso ao SDK e à pasta temporária do sistema.
A primeira tentativa restrita do pytest falhou na criação da pasta temporária,
antes da execução das regras de negócio. A execução completa posterior passou.

Cobertura adicionada:

- Venda de balcão consulta estoque da loja sem chamadas a expedição.
- Estoque acabado insuficiente bloqueia a venda comum.
- Montagem durante a venda continua disponível mesmo sem cestas prontas.
- Novas vendas pelo cliente usam `DIRECT_STORE`, sem responsável ou saída.
- Relatório, CSV e XLSX excluem transferências quando solicitado e preservam
  as vendas históricas de balcão e rota.
- A API mantém o comportamento anterior quando o novo parâmetro é omitido.

Os 95 testes Flutter anteriores continuam executando, incluindo a leitura dos
modelos arquivados usados como fixtures de compatibilidade.

As cópias anteriores tiveram seus hashes SHA-256 conferidos. O grafo de imports
do aplicativo a partir de `main.dart` foi verificado sem referências à pasta de arquivamento.
As classes de tradução foram regeneradas com `flutter gen-l10n`.

Persistem avisos anteriores de depreciação no backend e de suporte Unicode das
fontes padrão do pacote PDF. Nenhuma compilação Windows/APK ou verificação em
impressora física foi realizada nesta tarefa.
