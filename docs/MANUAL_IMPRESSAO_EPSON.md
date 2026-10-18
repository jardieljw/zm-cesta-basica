# Guia de impressão Wi-Fi — Android, Windows e Epson

Revisão: 14/10/2026. [Análise e limites de compatibilidade](IMPRESSAO_WIFI_E_ANDROID.md).

## Antes de começar

O app imprime PDFs por meio do sistema operacional. A compatibilidade depende
do modelo da impressora e do serviço/driver que a atende. Ter Wi-Fi, por si só,
não garante impressão pelo Android. O padrão Mopria atende modelos certificados;
outros equipamentos podem exigir um serviço específico do fabricante.

Fontes: [Android: impressão de documentos](https://developer.android.com/training/printing/custom-docs),
[Mopria: imprimir pelo Android](https://mopria.org/print-from-android).

## Android

Para configurar ou testar antes de abrir documentos, entre em
**Configurações → Impressão e impressoras** no app. Esse diagnóstico funciona
sem conexão com o servidor e sem acessar dados comerciais. A página de teste
abre a seleção nativa de impressoras do Android.

1. Confira se o celular e a impressora estão acessíveis na mesma rede local.
   Evite redes de visitantes com isolamento entre dispositivos. Uma impressora
   ligada por cabo à mesma rede também pode ser acessível pelo celular.
2. Abra um relatório ou formulário no app e toque no ícone de impressão.
3. Toque em **Procurar impressora e imprimir**. O Android abre sua janela de
   impressão; os serviços habilitados no aparelho procuram as impressoras.
4. Escolha a impressora e confira papel, orientação, páginas e cópias antes de
   confirmar.

O app não mostra uma lista própria de impressoras no Android, porque a API de
enumeração do pacote instalado não oferece esse recurso nessa plataforma.
Quem descobre os dispositivos é o serviço de impressão do Android.

### Se a impressora não aparecer

Use **Configurar impressão no Android** na janela do app. O botão abre as
configurações de impressão do sistema, quando essa tela existe no aparelho.
Também é possível pesquisar “Impressão” nas configurações do celular.

Confira se está ativado o serviço padrão, Mopria ou um serviço do fabricante
compatível com o modelo. Para Epson, consulte o serviço indicado pelo fabricante
para aquela impressora; não é uma garantia para toda a linha Epson.
Instalação e ativação são decisões do operador nas configurações/loja de apps.

Se a descoberta automática falhar, alguns serviços permitem adicionar a
impressora por IP. Essa opção depende do serviço e é configurada na janela do
próprio sistema. Verifique também VPN, isolamento da rede e o estado da
impressora. Ao voltar das configurações, o app atualiza as capacidades; há ainda
o botão **Atualizar**.

### Wi-Fi Direct

Esse modo depende do suporte do celular e da impressora. O procedimento de
conexão varia por modelo. Ao entrar na rede direta da impressora, o celular pode
perder a conexão com o servidor da loja. Carregue o documento antes de trocar a
rede e retorne à rede da loja depois da impressão. O app não altera a conexão
Wi-Fi automaticamente.

## Windows

Adicione a impressora em **Configurações → Impressoras e scanners** e instale o
driver adequado ao modelo. Ela precisa estar acessível pela rede e cadastrada
no sistema; o app não substitui o instalador do fabricante.

Na janela de impressão do app:

- **Procurar impressora e imprimir** abre a seleção nativa do Windows.
- **Impressoras cadastradas no sistema** mostra a lista que o Windows retorna,
  quando essa função é suportada. A impressora padrão aparece primeiro.
- A impressão direta por item é oferecida somente quando a plataforma oferece
  o recurso. Um dispositivo informado como indisponível fica desabilitado nesse
  caminho; a janela nativa continua disponível para conferir a configuração.

Nomes como “Wi-Fi” ou “Network” não são usados como prova de conectividade. Um
estado disponível informado pelo driver também não comprova papel ou tinta.

## Página de teste

Toque em **Imprimir página de teste A4**. Nada é impresso automaticamente ao
abrir a janela ou atualizar a lista.

A página contém acentos, números, moeda, uma referência de **100 x 20 mm** e
linhas de 8, 9 e 10 mm. Ela não contém dados de clientes, vendas ou pagamentos.
Selecione A4, retrato e escala de 100% quando disponível, e confira a folha:

1. Texto, acentos e números legíveis.
2. Referência com as medidas esperadas, sem redução/ampliação automática.
3. Ausência de cortes nas bordas e alinhamento adequado.

Depois, teste um documento real em paisagem e um documento de várias páginas,
incluindo seleção de intervalo e cópias. A homologação depende da saída física
no celular/serviço/impressora que serão usados.

## Cancelamento, erro e fila

O app diferencia cancelamento, erro e retorno de conclusão do sistema. Esse
retorno não é uma medição de entrega física. Se houver trabalho bloqueado,
confira papel, tinta, conectividade e fila do Android/Windows antes de reenviar.

Enquanto uma impressão aguarda o sistema, o app bloqueia outro envio pela mesma
tela. A janela do app pode ser fechada; isso não cancela automaticamente o
trabalho já entregue ao sistema. Acompanhe a fila do sistema para cancelar ou
resolver um trabalho pendente.

Falha ao consultar impressoras tem mensagem própria. Não deve ser confundida
com “nenhuma impressora encontrada”; a seleção nativa continua sendo uma
alternativa quando a consulta não está disponível.

## Salvar e compartilhar

**Salvar PDF** abre o seletor de destino. **Compartilhar** entrega o PDF ao
compartilhamento da plataforma. Esses caminhos permitem obter o documento
mesmo sem impressora acessível. Exportar XLSX não envia o arquivo diretamente à
impressora; é necessário um programa que abra e imprima planilhas.

Os modelos ativos são fiados, contas a pagar e inventário. O formulário de
expedição permanece arquivado na interface. As opções de campos, ordem,
margens, espaço manual e paginação estão no
[guia de relatórios e formulários](RELATORIOS_E_IMPRESSAO.md).

## Situação da validação

Foram realizados testes automatizados com adaptadores simulados e compilações
Windows/Android. No ambiente desta análise, só havia Microsoft Print to PDF no
Windows e nenhum Android conectado por ADB. Portanto, nenhuma impressora Wi-Fi
física ou serviço de um celular real foi homologado nesta entrega.

Para registrar a homologação, anotar modelo da impressora, celular/versão do
Android, serviço ativado, modo de conexão e resultado dos cenários da
[matriz de validação](IMPRESSAO_WIFI_E_ANDROID.md).
