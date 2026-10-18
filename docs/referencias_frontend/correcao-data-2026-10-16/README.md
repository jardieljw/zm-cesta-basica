# Correção do campo de data — 16/10/2026

O usuário mostrou a [data ultrapassando a coluna no iPhone](data-excedendo-iphone.jpg).
A correção pertence à prévia HTML, sem alteração no cliente Flutter.
Consultar o [registro da rodada](../../RODADA_FRONTEND_INTEGRAL_2026-10-16.md).

- [Fonte corrigida](jornada-pagar-data-alinhada-zm.html) e [contêiner de inspeção](jornada-pagar-data-alinhada-zm-preview.html).
- [Contêiner anterior](jornada-pagar-integral-zm-preview.html), preservado como baseline do teste.
- [Script de verificação](check-data-alinhada.cjs) e [relatório](data-alinhada-verificacao.json).
- Edge: [integral](data-edge-integral.png) e [parcial](data-edge-parcial.png).
- WebKit instalado: [integral](data-webkit-integral.png) e [parcial](data-webkit-parcial.png).
- [Manifesto](manifesto.json): origem, tamanho e SHA-256 das 10 cópias.

O campo nativo de data agora tem preenchimento interno zero; espaçamento, borda
e formato ficam em uma moldura dimensionada pela coluna do formulário. O controle
preserva seu tipo, valor, associação com o rótulo e eventos. O teste compara suas
bordas com os campos vizinhos e com o campo pai, além dos limites da janela.

Foram aprovados 64 casos de alinhamento: dois motores, quatro larguras, dois
tamanhos de fonte do campo de data, dois modos de pagamento e duas condições de
dimensionamento. Também foram conferidos valor vazio, revisão e edição da data.

**Limite importante:** nesta instalação Windows, o WebKit apresenta o atributo
`type=date` como controle de texto de contingência. Sua evidência é de layout e
fluxo, não do seletor UIKit. O cenário forçado `content-box` reproduz o efeito de
largura extra na versão anterior; não é prova de reprodução local do defeito
nativo do iOS. O Edge conserva o controle de data nativo. A confirmação visual
no iPhone real continua pendente.

O script usa navegadores existentes, aceita `PLAYWRIGHT_BROWSERS_PATH`,
`PLAYWRIGHT_MODULE` e `PREVIEW_DIR`, e não instala dependências no aplicativo.
Isola a persistência do contêiner com gravador de estado sem efeitos externos.
Para reexecutar sem substituir as evidências, copiar os dois contêineres para
outra pasta e apontar `PREVIEW_DIR` para ela.
