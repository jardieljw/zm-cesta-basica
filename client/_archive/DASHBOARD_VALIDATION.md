# Validação do dashboard simplificado

- Backend completo: **194 testes aprovados**, incluindo cinco novos cenários.
- Flutter completo: **101 testes aprovados**, incluindo três novos cenários.
- `flutter analyze`: **sem problemas**.
- `flutter build windows --release`: **compilação concluída**; pacote atualizado
  em `client/build/windows/x64/runner/Release/`.
- Verificação dos hashes dos 26 snapshots e do grafo de imports do aplicativo:
  nenhuma dependência de execução com a pasta de arquivamento.
- Patches dos arquivos compartilhados permitem a verificação de restauração
  com `git apply --reverse --check`.

Os novos testes verificam confirmações parciais, pagamentos sem escolher conta,
estornos, exclusão de depósitos/transferências/repasses, recebimento à vista,
custo dos insumos sem dupla dedução, relatório CSV/XLSX e os limites do dia local.
O dashboard foi renderizado nos testes em larguras de 360 e 1280 pixels, incluindo
o detalhamento de recebimentos. Nenhum dado comercial real foi apagado.

Os avisos de depreciação do backend e de fontes PDF são anteriores a esta etapa.
