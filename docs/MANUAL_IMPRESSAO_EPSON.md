# Manual de Impressão Direta Multiplataforma e Compatibilidade Epson Wi-Fi
## ZM Cesta Básica — Módulo de Relatórios, Documentos A4 e Impressão Nativa

**Versão do Documento:** 1.0 (Sistema Homologado - Fases 1 a 9)  
**Público-Alvo:** Gestores, Encarregados de Escritório e Operadores de Galpão  
**Equipamentos Suportados:** Impressoras Epson Wi-Fi (Série EcoTank), HP, Canon, Brother, Laser e Matriciais  

---

## 1. Arquitetura de Impressão do Sistema

O módulo de relatórios e impressão do **ZM Cesta Básica** foi desenvolvido para operar de forma nativa e integrada tanto no **Windows Desktop** quanto no **Android Mobile**, eliminando a necessidade de instalar pacotes de escritório como Microsoft Excel ou visualizadores de terceiros:

```
┌────────────────────────────────────────────────────────┐
│             Aplicativo ZM Cesta Básica                │
│    (Gerador Nativo de PDF Vetorial: ReportPdfBuilder)  │
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│ Windows Print Spooler     │ │ Android Print Framework   │
│ - Drivers Nativos Windows │ │ - Mopria Print Service    │
│ - Epson ESC/P-R Driver    │ │ - Epson Print Enabler     │
│ - Impressoras USB / Wi-Fi │ │ - Impressoras Wi-Fi Direto│
└─────────────┬─────────────┘ └─────────────┬─────────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                             ▼
              ┌───────────────────────────┐
              │   Impressão Física em A4  │
              │  (ou Salvar/Compartilhar) │
              └───────────────────────────┘
```

---

## 2. Modalidades de Impressão Disponíveis

### 2.1. Relatórios Preenchidos em Tempo Real
- Gerados com base nos dados reais do sistema para o período selecionado (Hoje, Mês, Ano, Período Customizado ou Todo o Histórico).
- Incluem cabeçalho padronizado da empresa, tabela zebrada para leitura confortável, paginação no rodapé (`Página X de Y`) e carimbo de data/hora de emissão.
- Totalizadores financeiros e operacionais formatados no padrão monetário brasileiro (`R$ X.XXX,XX`).

### 2.2. Formulários em Branco para Preenchimento Manual à Caneta (Prancheta)
Projetados especificamente para a rotina prática de galpão e carga/descarga na rua, onde não há computador disponível:
- **Linhas Altas e Espaçosas:** Cada linha possui entre **8 e 10 mm de altura**, proporcionando espaço amplo para escrita manual legível à caneta.
- **Caixas de Seleção (*Checkboxes*):** Espaço para visto de conferência física e assinaturas de recebimento.
- **Tabelas Claras:** Sem fontes minúsculas nem compressão excessiva de colunas.

Os 4 modelos disponíveis:
1. **Formulário A:** Vendas Fiadas, Pagamentos e Quitação (controle de parcelas e cobrança na rota).
2. **Formulário B:** Contas a Pagar e Despesas Operacionais (controle de faturas e vencimentos).
3. **Formulário C:** Saídas Físicas e Conferência Diária (romaneio de carga, devoluções intactas e avarias).
4. **Formulário D:** Balanço Físico de Estoque (contagem cega e auditoria de insumos no depósito).

---

## 3. Configuração de Impressoras Epson Wi-Fi

O sistema não utiliza portas seriais proprietárias nem sockets TCP crus; ele integra-se diretamente à **camada oficial de spooler do sistema operacional**, garantindo compatibilidade universal com toda a linha Epson (ex.: EcoTank L3250, L4260, L3150, L4160, M1120).

### 3.1. Configuração no Windows Desktop
1. Conecte a impressora Epson à mesma rede Wi-Fi do computador.
2. Instale o pacote de drivers oficiais da Epson para Windows (**Epson ESC/P-R Driver**).
3. No Windows, acesse **Configurações $\rightarrow$ Dispositivos $\rightarrow$ Impressoras e Scanners** e confirme se a Epson está definida como disponível (ou impressora padrão).
4. Ao clicar no botão **Imprimir** dentro do aplicativo ZM Cesta Básica:
   - A janela oficial do **Spooler do Windows** abrirá automaticamente.
   - Selecione a impressora Epson, a quantidade de cópias e clique em **Imprimir**.

### 3.2. Configuração no Smartphone Android
1. Conecte o smartphone Android à mesma rede Wi-Fi da impressora.
2. Na Google Play Store do celular, instale o serviço oficial:
   - **Epson Print Enabler** (plugin oficial da Epson) OU
   - **Mopria Print Service** (padrão universal da indústria).
3. No Android, acesse **Configurações $\rightarrow$ Dispositivos Conectados $\rightarrow$ Preferências de Conexão $\rightarrow$ Impressão** e certifique-se de que o plugin está **Ativado**.
4. No aplicativo ZM Cesta Básica no celular:
   - Ao visualizar o relatório ou formulário, clique no ícone da impressora.
   - O Android localizará automaticamente a Epson conectada na rede Wi-Fi local.
   - Escolha o número de cópias e confirme a impressão.

---

## 4. Pré-visualização Interativa no Aplicativo (`PdfPreview`)

Antes de enviar qualquer documento para a impressora física, o operador visualiza o documento completo na tela:
- **Zoom e Navegação:** Permite folhear as páginas do relatório e dar zoom para conferir valores.
- **Orientação Automática:** Relatórios mais largos (como o Extrato de Contas a Pagar e Romaneio Completo de Expedição) são gerados automaticamente em orientação **Paisagem (Horizontal)** para garantir que nenhuma coluna seja cortada.
- **Margens de Segurança:** Configurado com margem mínima de 15 mm, impedindo cortes em cabeçalhos ou rodapés mesmo em impressoras jato de tinta que exigem margem inferior maior.

---

## 5. Rota de Contingência (Impressora Offline / Sem Papel)

Caso a impressora esteja desligada, sem papel ou sem tinta, a operação da empresa não é interrompida:

1. **Botão "Salvar PDF":**  
   Permite salvar o arquivo `.pdf` diretamente no disco local do computador ou na pasta de Downloads do celular.
2. **Botão "Compartilhar":**  
   No celular Android, permite enviar o arquivo imediatamente via WhatsApp, Telegram ou e-mail para o cliente ou para uma gráfica rápida.
3. **Exportação para Planilhas (CSV / XLSX):**  
   Todos os relatórios preenchidos possuem botões alternativos para baixar os dados em formato de planilha, permitindo abri-los no Excel quando for necessária análise customizada.
