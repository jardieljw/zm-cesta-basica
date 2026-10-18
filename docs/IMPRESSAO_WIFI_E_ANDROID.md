# Análise da impressão Wi-Fi, com foco no Android

Revisão: 14/10/2026. [Guia de operação](MANUAL_IMPRESSAO_EPSON.md).

## Parecer

A arquitetura adequada é entregar o PDF ao sistema operacional. No Android,
o serviço de impressão ativado no celular descobre e atende as impressoras; no
Windows, essa função cabe ao spooler e aos drivers instalados. O app não deve
implementar um scanner de rede ou enviar comandos proprietários para tentar
substituir todos esses serviços.

**Uma impressora ter Wi-Fi não garante compatibilidade.** A condição é que o
modelo seja atendido pelo serviço de impressão do Android ou pelo driver do
Windows, com conectividade adequada. Mopria cobre modelos certificados;
modelos específicos podem precisar de serviço próprio do fabricante.
Referências: [Android PrintManager](https://developer.android.com/reference/android/print/PrintManager),
[Mopria: impressão Android e requisitos](https://mopria.org/print-from-android).

## Problemas encontrados e correções

| Constatação no código anterior | Tratamento implementado |
| --- | --- |
| `listPrinters()` era chamado em todas as plataformas; o adaptador Android instalado não implementa essa função. | Android não chama enumeração nem impressão direta. A seleção usa a janela nativa de impressão. |
| A tela não consultava as capacidades reais da plataforma antes de oferecer caminhos específicos. | Serviço central consulta capacidades, limita a consulta por tempo e verifica no Android a presença do recurso de impressão e do PrintManager. |
| Botões padrão do PdfPreview e botões próprios levavam a caminhos diferentes. | As ações de imprimir passam por uma única janela controlada. A prévia não mantém uma segunda ação de impressão sem o mesmo tratamento. |
| O texto e a identificação de impressoras privilegiavam Epson e inferiam Wi-Fi a partir do nome. | Impressoras são apresentadas sem inferência de protocolo/marca. Nome, modelo, padrão e disponibilidade são os informados pelo sistema. |
| Não havia acesso às configurações de impressão do Android. | Botão usa `Settings.ACTION_PRINT_SETTINGS`, com tratamento para aparelhos sem essa tela. |
| Não havia uma folha própria de diagnóstico. | Página A4 com acentos, números, moeda, referência de 100 x 20 mm e linhas de 8/9/10 mm. Só imprime por ação do usuário. |
| O retorno/cancelamento da impressão era ignorado. | A interface diferencia cancelamento, erro e retorno do sistema. Não declara que a folha foi fisicamente entregue. |
| Repetir a ação podia iniciar outro trabalho enquanto o anterior aguardava o sistema. | A instância do serviço mantém o estado do trabalho e bloqueia reenvio, inclusive após fechar e reabrir a janela. |
| Relatórios gerais ignoravam a orientação pedida pelo visualizador e iniciavam com sugestão de papel incorreta. | A sugestão inicial acompanha o relatório; mudanças de orientação são repassadas ao construtor. Formulários configurados conservam seu documento fixo. |
| Erros de lista podiam parecer ausência de impressora ou impedir o entendimento do fluxo. | Falha de consulta é distinta de lista vazia; o caminho nativo continua oferecido quando a consulta falha. |

O app mantém os caminhos de salvar e compartilhar PDF. Uma impressora ausente
ou um serviço incompatível não deve impedir a obtenção do documento.

O diagnóstico também fica em **Configurações → Impressão e impressoras**,
sem precisar carregar relatório, autenticar o dispositivo ou conectar ao
servidor. Nesse acesso, a ação de impressão é a página de teste sem dados
comerciais; não existe um documento comercial vazio sendo enviado.

## Fluxo Android

1. Abrir a prévia do documento e tocar em imprimir.
2. Usar **Procurar impressora e imprimir**. A descoberta ocorre na interface
   do sistema, por meio do serviço habilitado no aparelho.
3. Se a impressora não aparecer, abrir **Configurar impressão no Android**,
   habilitar um serviço compatível e retornar ao app.
4. Conferir rede, suporte do modelo e fila. Quando o serviço oferecer cadastro
   por IP, essa configuração é feita no próprio serviço/sistema.
5. Usar a página de teste A4 para conferir o resultado físico.

O app não solicita permissões novas de localização, câmera ou varredura Wi-Fi
para imprimir. Um serviço externo pode ter suas próprias permissões. Não há
instalação automática de plugin ou alteração automática da rede do celular.

A ponte Android usa APIs públicas: `PackageManager.FEATURE_PRINTING`,
`Context.PRINT_SERVICE` e
[`Settings.ACTION_PRINT_SETTINGS`](https://developer.android.com/reference/android/provider/Settings#ACTION_PRINT_SETTINGS).
A detecção do recurso não comprova que exista um serviço habilitado ou que uma
impressora específica esteja acessível; essas condições continuam verificadas
pela janela nativa e pelo operador.

## Rede e compatibilidade

- Celular e impressora devem estar acessíveis na mesma rede local para a
  descoberta usual. Uma impressora ligada por cabo à mesma LAN pode ser
  acessível ao celular via Wi-Fi; não precisam usar a mesma forma física de
  conexão.
- Rede de visitantes, isolamento entre clientes, VLANs sem descoberta
  encaminhada e VPN podem impedir a localização ou o acesso.
- Wi-Fi Direct depende do suporte dos dois dispositivos. Ao conectar à rede
  direta da impressora, o celular pode perder a rede do servidor da loja.
  Carregar o documento antes de trocar de conexão. A impressão do PDF já
  carregado não requer uma nova consulta ao backend.
- Suporte de IPP/Mopria, driver/serviço de fabricante e opções de papel variam
  por modelo. Não há uma promessa de funcionamento universal com qualquer
  equipamento apenas por ter interface Wi-Fi.

Base: [Mopria: conexão e requisitos](https://mopria.org/print-from-android),
[impressão de documentos no Android](https://developer.android.com/training/printing/custom-docs).

## Verificações realizadas

- Inspeção do cliente, do adaptador Dart e do código Android do pacote
  `printing` 5.15.1 instalado. Nesse adaptador, `directPrint=false` e não há
  implementação de `listPrinters` no handler Android.
- Consulta ao Windows: apenas **Microsoft Print to PDF** registrado no momento
  da análise. Não foi encontrada impressora física cadastrada.
- Consulta ADB: nenhum dispositivo Android conectado. A ponte nativa foi
  compilada; não foi executada em aparelho real nesta análise.
- Dezoito novos testes automatizados de serviço/interface aprovados,
  simulando capacidades Android/Windows, indisponibilidade, tempo limite,
  cancelamento, erro, orientação, reenvio, página de teste, janela estreita e
  diagnóstico nas Configurações sem conexão com o servidor.
- Página de teste gerada pelo código real e inspecionada visualmente. PDF de
  uma página A4; geometria da referência verificada como 100 x 20 mm.

Suítes completas: **208 testes Flutter e 248 testes backend aprovados**.
Análise estática sem problemas; compilações de teste Windows e Android
verificadas. Testes simulados não comprovam descoberta ou transporte físico em
uma rede Wi-Fi real.

## Homologação física ainda necessária

| Cenário | O que conferir |
| --- | --- |
| Android + serviço padrão + impressora compatível na LAN | Descoberta, seleção, cópias, orientação e saída da página de teste. |
| Android + Mopria ou serviço do fabricante | Mesmo teste no modelo efetivo da loja; verificar instalação e ativação do serviço. |
| Wi-Fi Direct, quando suportado | Acesso ao documento previamente carregado e retorno posterior à rede da loja. |
| Impressora desligada ou trabalho bloqueado | Mensagem/fila do sistema, recuperação e ausência de reenvio automático. |
| Cancelar antes de confirmar | Ausência de folha e de mensagem falsa de sucesso. |
| Documento de várias páginas | Paginação e escolha de um intervalo de páginas na janela do Android. A geração de bytes não homologa a seleção de páginas do serviço/driver. |
| A4 retrato/paisagem e margens | Legibilidade, ausência de cortes e referência de 100 mm na escala escolhida. |
| Windows + driver do modelo real | Enumeração, janela nativa e, quando oferecida, impressão direta. |

Para executar essa etapa, registrar modelo da impressora, versão do Android,
celular, serviço habilitado, modo de conexão e resultado. O estado “concluído”
do spooler é uma informação do sistema; não constitui medição de papel, tinta
ou entrega física feita pelo app.

## Implementação e testes

- `client/lib/services/printer_service.dart`
- `client/lib/widgets/shared/printer_selection_dialog.dart`
- `client/lib/views/pdf_viewer_screen.dart`
- `client/lib/utils/printer_test_page.dart`
- `client/android/app/src/main/kotlin/com/example/zm_cesta_basica_client/MainActivity.kt`
- `client/test/printer_service_test.dart`
- `client/test/printer_selection_dialog_test.dart`
