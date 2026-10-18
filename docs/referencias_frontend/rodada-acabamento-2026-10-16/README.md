# Acabamento integrado e filtros compactos — FE-052

**16/10/2026.** O usuário pediu adiantar o conjunto respeitando arquitetura e
acordos, e rejeitou os filtros grandes da captura inicial. A
[nova fonte integrada](acabamento-integrado-zm.html) reúne o acabamento apreciado
em FE-051 à organização FE-049 e à **Leitura recuperada**. Dados fictícios;
não é aplicação do tema no Flutter ou conexão com os registros da empresa.

## Entrega agrupada

- Fundo azul acinzentado com luz quente discreta; vidro suave, borda iluminada
  e sombra nos resumos e painéis de conteúdo.
- Pagar/Receber com apresentação de extrato: pessoa/origem/vencimento,
  original e pago/recebido, saldo atual e situação; reordenação no celular
  estreito ou texto ampliado.
- Filtro recolhido por padrão, em uma linha, com recorte ativo visível. Abre
  somente os seis recortes de vencimento já existentes. Escolher aplica e fecha;
  fechar sem escolher mantém o recorte. Navegação e retorno mantêm a consulta.
- Material sólido para comparação e alternativa de leitura, nos ajustes da
  apresentação. Não cria uma nova configuração definitiva no produto.
- Início curto com Dia/Semana/Mês, atenção atual independente, resultado em
  Negócio, demais caminhos e jornadas financeiras mantidos.

Campos continuam 24, painéis 32, intervalo 20 e azul original configurável.
Navegação conserva coluna 140, raios 12 e alinhamentos. O material do conteúdo
não foi estendido à barra nem alterou seus tamanhos. A Leitura orientada não
voltou como padrão. O bloco antigo de filtros extensos não foi copiado.

Contagem de “contas em aberto” inclui as parciais; a indicação “parcial” é um
subconjunto. Saldo exibido continua sendo o restante, sem somar novamente valores
já pagos/recebidos. Não é saldo bancário nem receita confirmada.

## Fontes e reprodução

Derivação direta da [fonte FE-049](../rodada-organizacao-2026-10-16/organizacao-integrada-zm.html),
identificada por SHA-256 antes de gerar. A referência inicial de material é o
[estudo de vidro](../direcoes-design-zm-ajustavel.html), sem copiar suas medidas
antigas ou substituir a estrutura atual. A [base visual](../../BASE_VISUAL_FRONTEND.md)
registra a preferência FE-051 e os limites dessa captura.

[Gerador](gerar-revisao.py), [material](acabamento.css),
[composição da lista](lista-financeira.js) e
[origem/preservação](origem-e-alteracoes.json) tornam a revisão reproduzível.
Executar o gerador com `--output-dir` apontando para uma pasta nova e comparar
o SHA-256 do fragmento. Não usar `--replace-draft` em revisões arquivadas.

O [contêiner de inspeção](acabamento-integrado-zm-preview.html) usa o renderizador
da skill visualize. Os scripts de verificação apontam para os executáveis locais
de Node/Playwright; revisar os caminhos ao retomar em outra máquina.

## Verificação e limites

[Regressão do conjunto](acabamento-regressao.json): cinco grupos e 90 composições
por Edge/WebKit, 180 no total. Períodos, resumos, destinos, geometria da barra,
home em até 844 nas larguras externas 390/422, Integral/Parcial, revisão/edição,
confirmação simulada e restauração foram conservados.

[Verificação do acabamento](acabamento-verificacao.json): filtros, extrato,
alteração de tema/material com rascunho preservado, retorno, tamanhos e estados.
São 72 composições financeiras por motor (144 no total), com 320/390/1024 de
largura externa, claro/escuro, conteúdo 100/150/200% e vidro/sólido. As duas
verificações somam **324 composições**, sem erro JavaScript observado.
Foram calculados 16 pares/limites de contraste por motor, com resultado ≥ 4,5.
O relatório conserva os limites de suporte do ambiente. Contraste calculado usa os limites das camadas padrão;
não mede todos os pixels, cores personalizadas ou estados nativos.
No Edge, cores forçadas emuladas ativaram o material sólido; a emulação específica
de redução de transparência não ficou disponível. A alternativa sólida foi
verificada nos dois motores. A espera da checagem por animações foi limitada
para não depender de uma promessa de término que ficou pendente no WebKit;
o relatório final considera as execuções completas após esse ajuste do verificador.

[Saúde e preservação](saude-e-preservacao.json) registra as suítes existentes,
hashes, equivalência estrutural, reprodução e arquivos preservados. Testes do
servidor usam bancos temporários isolados; não há homologação no aparelho iOS,
preferência nativa de transparência, servidor da empresa ou binário instalado.
Capturas foram inspecionadas em claro/escuro no celular e computador.

O [manifesto](manifesto.json) cobre os arquivos desta rodada, exceto ele próprio
e este README. Evidências locais não equivalem a commit Git ou distribuição.

## Continuidade para chegar à entrega

Esta é a revisão agrupada de acabamento, sem reabrir navegação, tipografia ou
descoberta. A próxima etapa de integração usa o recorte já preparado nas
[jornadas financeiras](../../JORNADAS_FINANCEIRAS_E_PRONTIDAO_DO_PILOTO.md): Pagar
sobre título existente como primeiro piloto recomendado. Preservar arquitetura,
serviços, histórico e demais telas ao tratar os contratos técnicos identificados
em FE-050. A aparência da simulação não comprova recuperação real de envio,
precondição de saldo ou semântica de datas já implementadas.
