// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get billIntegrationTitle => 'Conferir fatura';

  @override
  String get billDetailDifference =>
      'Diferença entre detalhes e total conferido';

  @override
  String get billIntegrationHelp =>
      'Você pode guardar a fatura ou adicioná-la a Contas a Pagar. Suas compras ficam disponíveis para consulta. O pagamento só é registrado quando você usar Registrar pagamento; gastos pessoais não viram despesas da empresa automaticamente.';

  @override
  String get billIntegrationHeader => 'Conferir total e vencimento';

  @override
  String get billIntegrationDestination =>
      'O que você quer fazer com esta fatura?';

  @override
  String get billIntegrationPending => 'Guardar por enquanto; decidir depois';

  @override
  String get billIntegrationHistory => 'Guardar sem adicionar a Contas a Pagar';

  @override
  String get billIntegrationOpen =>
      'Adicionar a Contas a Pagar: esta fatura ainda precisa ser paga';

  @override
  String get billIntegrationDetailAck =>
      'Usar o total conferido e guardar a diferença para revisar depois.';

  @override
  String get billIntegrationControlsAck =>
      'Conferi o cartão, o total, o vencimento e o que será feito com esta fatura.';

  @override
  String get billIntegrationReason =>
      'Origem, controles e situação da fatura conferidos pelo operador.';

  @override
  String get billIntegrationConfirm => 'Salvar fatura';

  @override
  String get billIntegrationRetry => 'Retomar confirmação';

  @override
  String get billIntegrationSuccess =>
      'Fatura adicionada a Contas a Pagar. Você pode consultar os itens e registrar o pagamento na conta abaixo.';

  @override
  String get billIntegrationEvidenceSaved =>
      'Esta fatura está guardada para consulta. Ela não foi adicionada a Contas a Pagar.';

  @override
  String get billIntegrationOpenPayable => 'Ver conta e pagamentos';

  @override
  String get billIntegrationConflict =>
      'Esta fatura precisa de uma conferência de ciclo, saldo anterior ou título já existente. Atualize os dados e confira o vínculo indicado.';

  @override
  String get billIntegrationRequiredStep => 'Para salvar, conclua esta etapa:';

  @override
  String get billIntegrationGoToMarkedArea => 'Ver área destacada';

  @override
  String get billIntegrationGoToRequiredStep => 'Ir para esta etapa';

  @override
  String get billIntegrationReturnToDocuments => 'Voltar aos documentos';

  @override
  String get billIntegrationErrorDetails =>
      'O total e os itens da fatura ainda não conferem. Marque a opção abaixo se aceita guardar essa diferença para revisar depois.';

  @override
  String get billIntegrationErrorContent =>
      'Esta fatura difere de uma conferência anterior. Compare os itens listados e marque a opção para aceitar esta revisão.';

  @override
  String get billIntegrationErrorObligations =>
      'Não foi possível confirmar o vínculo com uma conta existente. Abra “Já existe alguma destas contas?” e selecione o título que representa o saldo anterior ou a compra. Se a seção não aparecer, volte a Contas a Pagar e confira se esse título existe.';

  @override
  String get billIntegrationErrorDestination =>
      'Esta fatura já tem uma cobrança vinculada. Selecione “Adicionar a Contas a Pagar” para manter o vínculo.';

  @override
  String get billIntegrationErrorHeader =>
      'O ciclo desta fatura não foi identificado. Confira o total e o vencimento em “Conferir total e vencimento”.';

  @override
  String get billIntegrationErrorPreviousBalance =>
      'O saldo anterior do resumo não bate com o saldo detalhado. Abra o documento original e confira esses valores antes de salvar.';

  @override
  String get billIntegrationErrorRevision =>
      'Esta fatura mudou desde que você abriu a revisão. Confira os dados atualizados e marque novamente a confirmação final para salvar.';

  @override
  String get billIntegrationErrorCycle =>
      'Este documento já está associado a outro ciclo ou cartão. Volte aos documentos, confira o ciclo e a origem selecionados e abra a fatura correta.';

  @override
  String get billIntegrationErrorSingleCycle =>
      'O arquivo reúne mais de uma fatura. Volte aos documentos e selecione um ciclo por vez antes de continuar.';

  @override
  String get billIntegrationErrorRole =>
      'O tipo de lançamento e o sinal do valor não correspondem. Confira esse item no documento original; esta tela não permite alterar essa classificação.';

  @override
  String get billIntegrationErrorPaid =>
      'Esta revisão alteraria valores já pagos. Confira a fatura e os pagamentos registrados antes de tentar novamente.';

  @override
  String get billPurposeUnknown => 'Finalidade não informada';

  @override
  String get billStatusSubstituted => 'Substituído pela fatura';

  @override
  String get billDetailsPending => 'Detalhes pendentes de conferência';

  @override
  String get billUnclassifiedPaid => 'Pagamentos sem finalidade informada';

  @override
  String get billCompositionStock => 'Estoque';

  @override
  String get billCompositionBusiness => 'Despesas do negócio';

  @override
  String get billCompositionPersonal => 'Pessoal';

  @override
  String get billItemsTitle => 'Itens da fatura';

  @override
  String get financialImportAutoReaderHelp =>
      'O formato será reconhecido pelo conteúdo. A conta ou o cartão escolhido será mantido.';

  @override
  String get financialImportSummaryOnly =>
      'Este arquivo é uma relação de faturas, sem as compras individuais. Ele precisa de conferência por ciclo.';

  @override
  String get financialImportReaderAmbiguous =>
      'O conteúdo admite mais de uma leitura. Confira se a origem escolhida é uma conta ou um cartão e selecione o documento detalhado.';

  @override
  String get financialImportDueConflict =>
      'O documento informa vencimentos diferentes. Confira as datas e sua origem antes de cadastrar a cobrança.';

  @override
  String get appTitle => 'ZM Cesta Básica';

  @override
  String get homeHeaderTitle => 'ZM Cestas - Gestão de Estoque';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonActions => 'Ações';

  @override
  String get commonNotes => 'Observações';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRequired => 'Obrigatório';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonSuccess => 'Operação realizada com sucesso';

  @override
  String get commonError => 'Ocorreu um erro';

  @override
  String get commonWarning => 'Atenção';

  @override
  String get commonViewDetails => 'Ver Detalhes';

  @override
  String get statusOnline => 'Conectado';

  @override
  String get statusOffline => 'Desconectado';

  @override
  String get statusPaired => 'Pareado';

  @override
  String get statusUnpaired => 'Não Pareado';

  @override
  String get serverUrlLabel => 'URL do Servidor';

  @override
  String get fingerprintLabel => 'Fingerprint TLS';

  @override
  String get moduleProducts => 'Produtos & Insumos';

  @override
  String get moduleBasketTypes => 'Tipos de Cestas';

  @override
  String get modulePurchases => 'Entrada de Compras';

  @override
  String get moduleProduction => 'Ordens de Produção';

  @override
  String get moduleAssembly => 'Montar Cestas';

  @override
  String get moduleInventorySummary => 'Posição de Estoque';

  @override
  String get moduleInventoryMovements => 'Histórico de Movimentações';

  @override
  String get moduleSettings => 'Configurações';

  @override
  String get modulePairing => 'Pareamento de Dispositivo';

  @override
  String get productsTitle => 'Produtos e Insumos';

  @override
  String get productNew => 'Novo Produto';

  @override
  String get productEdit => 'Editar Produto';

  @override
  String get productName => 'Nome do Produto';

  @override
  String get productCategory => 'Categoria';

  @override
  String get productBaseUnit => 'Unidade Base';

  @override
  String get productMinStock => 'Estoque Mínimo';

  @override
  String get productActive => 'Ativo';

  @override
  String get productInactive => 'Inativo';

  @override
  String get productPackagings => 'Embalagens / Apresentações';

  @override
  String get packagingNew => 'Nova Embalagem';

  @override
  String get packagingName => 'Nome da Embalagem';

  @override
  String get packagingBarcode => 'Código de Barras';

  @override
  String get packagingMultiplier => 'Fator Multiplicador';

  @override
  String get packagingUnit => 'Unidade de Embalagem';

  @override
  String get basketTypesTitle => 'Tipos de Cestas';

  @override
  String get basketTypeNew => 'Novo Tipo de Cesta';

  @override
  String get basketTypeEdit => 'Editar Tipo de Cesta';

  @override
  String get basketTypeCode => 'Código da Cesta';

  @override
  String get basketTypeName => 'Nome da Cesta';

  @override
  String get basketTypeAllowsCustom => 'Permite Personalização';

  @override
  String get recipeVersionLabel => 'Versão da Receita';

  @override
  String get recipeAddIngredient => 'Adicionar Insumo';

  @override
  String get purchasesTitle => 'Entrada de Compras';

  @override
  String get purchaseNew => 'Registrar Compra';

  @override
  String get purchaseInvoiceNumber => 'Número da NF';

  @override
  String get purchaseSupplier => 'Fornecedor';

  @override
  String get purchaseDate => 'Data da Compra';

  @override
  String get purchaseItems => 'Itens da Compra';

  @override
  String get purchasePackagesCount => 'Qtd. Embalagens';

  @override
  String get purchaseUnitCost => 'Preço Unitário';

  @override
  String get purchaseTotalCost => 'Custo Total';

  @override
  String get productionBatchesTitle => 'Lotes de Produção';

  @override
  String productionBatchNumber(int number) {
    return 'Lote #$number';
  }

  @override
  String get productionDirectSale => 'Venda Direta';

  @override
  String get productionCustom => 'Cesta Personalizada';

  @override
  String productionDisassembleTitle(int number) {
    return 'Desmontar Lote #$number';
  }

  @override
  String get productionDisassembleConfirm => 'Confirmar Desmontagem';

  @override
  String get productionDisassembleQtyLabel => 'Qtd. a Desmontar';

  @override
  String get productionDisassembleReasonLabel => 'Motivo da Desmontagem';

  @override
  String get productionDisassembleTriageTitle => 'Triagem Física dos Insumos';

  @override
  String get productionDisassembleAllIntact => '100% Intacto (Sem Avarias)';

  @override
  String productionIntactQtyLabel(String unit) {
    return 'Intacto ($unit)';
  }

  @override
  String productionLossQtyLabel(String unit) {
    return 'Perda/Avaria ($unit)';
  }

  @override
  String get productionDisassembledSuccess => 'Lote desmontado com sucesso!';

  @override
  String get productionBatchEmpty => 'Nenhum lote de produção encontrado.';

  @override
  String get productionBatchMountFirst => 'Montar Primeira Cesta';

  @override
  String productionBatchCancelTitle(int number) {
    return 'Estorno Total do Lote #$number';
  }

  @override
  String get productionBatchCancelConfirm => 'Confirmar Estorno';

  @override
  String get productionBatchCancelSuccess => 'Lote estornado com sucesso!';

  @override
  String validationMinChars(int min) {
    return 'Mínimo de $min caracteres';
  }

  @override
  String get validationMustBePositive =>
      'A quantidade a desmontar deve ser maior que zero.';

  @override
  String get commonTryAgain => 'Tentar Novamente';

  @override
  String get homePhase2Header => 'Cadastros e Receitas';

  @override
  String get homeProductsDescription =>
      'Catálogo de itens, embalagens comerciais e estoque mínimo.';

  @override
  String get homeBasketTypesDescription =>
      'Tipos de cestas e versionamento imutável de receitas.';

  @override
  String get homePhase3Header => 'Estoque, Compras e Razão Contábil';

  @override
  String get homePurchasesDescription =>
      'Entrada de notas, conversão de fardos/caixas e cancelamento seguro.';

  @override
  String get homeInventorySummaryDescription =>
      'Posição consolidada e alerta de ruptura de estoque.';

  @override
  String get homeInventoryMovementsDescription =>
      'Histórico auditável e imutável de todas as movimentações.';

  @override
  String get homeServerStatusTitle => 'Status do Servidor';

  @override
  String get homeCentralServer => 'Servidor Central';

  @override
  String get homeCheckConnection => 'Verificar Conexão';

  @override
  String get homePairDevice => 'Parear Dispositivo';

  @override
  String get inventorySummaryTitle => 'Posição de Estoque';

  @override
  String get inventoryMovementsTitle => 'Movimentações de Estoque';

  @override
  String get stockAdjustmentsTitle => 'Ajuste Manual de Estoque';

  @override
  String get stockAdjustmentNew => 'Novo Ajuste de Estoque';

  @override
  String get stockAdjustmentTypeIn => 'Sobra / Entrada (+)';

  @override
  String get stockAdjustmentTypeOut => 'Avaria / Saída (-)';

  @override
  String get stockAdjustmentReasonLabel => 'Justificativa do Ajuste';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get pairingTitle => 'Pareamento do Dispositivo';

  @override
  String get pairingPinLabel => 'PIN de Pareamento';

  @override
  String get pairingScanQr => 'Escanear QR Code';

  @override
  String get pairingDeviceName => 'Nome deste Dispositivo';

  @override
  String get errorInsufficientStock =>
      'Estoque insuficiente para realizar esta operação.';

  @override
  String get errorIdempotencyMismatch =>
      'Operação já executada com parâmetros divergentes.';

  @override
  String get errorRequestInProgress =>
      'Requisição em processamento concorrente. Aguarde alguns instantes.';

  @override
  String get errorUnauthorized =>
      'Dispositivo não autenticado. Realize o pareamento novamente.';

  @override
  String get errorDeviceRevoked =>
      'Dispositivo revogado pelo servidor central.';

  @override
  String get errorForbidden => 'Acesso não permitido.';

  @override
  String get errorNotFound => 'Registro ou recurso não encontrado.';

  @override
  String get errorConflict =>
      'Conflito de estado ou dados inconsistentes na operação.';

  @override
  String get errorValidationError =>
      'Dados enviados são inválidos. Verifique os campos preenchidos.';

  @override
  String get errorServer =>
      'Erro interno no servidor local. Tente novamente mais tarde.';

  @override
  String get errorConnectionFailed =>
      'Não foi possível conectar ao servidor local. Verifique sua rede e se o serviço está ativo.';

  @override
  String get errorUnexpected => 'Ocorreu um erro inesperado.';

  @override
  String get productsCatalogTitle => 'Catálogo de Produtos e Insumos';

  @override
  String get productSearchHint => 'Buscar por nome, SKU ou código de barras...';

  @override
  String get productEmpty =>
      'Nenhum produto encontrado com os filtros selecionados.';

  @override
  String get productInactivateTitle => 'Inativar Produto';

  @override
  String productInactivateConfirm(String name) {
    return 'Deseja inativar o produto \"$name\"?\n\nO cadastro e o histórico serão preservados. Ele deixará de aparecer em novas compras e composições. Produtos nunca utilizados também podem ser excluídos definitivamente pela ação de excluir.';
  }

  @override
  String get productInactivateButton => 'Inativar';

  @override
  String get productInactivatedSuccess => 'Produto inativado com sucesso.';

  @override
  String productInactivateError(String error) {
    return 'Falha ao inativar produto: $error';
  }

  @override
  String productLoadError(String error) {
    return 'Erro ao carregar produtos: $error';
  }

  @override
  String get productCostPriceRef => 'Custo Ref.:';

  @override
  String get productSalePriceRef => 'Venda Ref.:';

  @override
  String productPackagingsCount(int count) {
    return 'Formas de compra ($count)';
  }

  @override
  String productSkuLabel(String sku) {
    return 'SKU: $sku  ';
  }

  @override
  String productBarcodeLabel(String barcode) {
    return 'EAN: $barcode';
  }

  @override
  String get productFormNewTitle => 'Novo Produto / Insumo';

  @override
  String get productFormEditTitle => 'Editar Produto / Insumo';

  @override
  String get productFormNameLabel => 'Nome do Produto *';

  @override
  String get productFormNameHint => 'Ex: Arroz Agulhinha 5kg, Detergente 500ml';

  @override
  String get productFormNameRequired => 'Nome é obrigatório';

  @override
  String get productFormCategoryLabel => 'Categoria *';

  @override
  String get productFormBaseUnitLabel => 'Unidade Base no Estoque *';

  @override
  String get productFormSkuLabel => 'SKU / Código Interno';

  @override
  String get productFormSkuHint => 'Ex: ARR-5KG';

  @override
  String get productFormBarcodeLabel => 'Código de Barras / EAN';

  @override
  String get productFormBarcodeHint => 'Ex: 7891234567890';

  @override
  String productFormMinStockLabel(String unit) {
    return 'Estoque Mínimo ($unit)';
  }

  @override
  String get productFormMinStockInvalid => 'Mínimo deve ser >= 0';

  @override
  String get productFormCostPriceLabel => 'Preço de Custo (R\$)';

  @override
  String get productFormSalePriceLabel => 'Preço de Venda (R\$)';

  @override
  String get productFormNotesLabel => 'Observações';

  @override
  String get productFormStatusActive => 'Status Ativo';

  @override
  String get productFormStatusActiveSubtitle =>
      'Produtos inativos não podem ser incluídos em novas receitas ou compras.';

  @override
  String get productFormSaveCreate => 'Cadastrar Produto';

  @override
  String get productFormSaveUpdate => 'Atualizar Produto';

  @override
  String productFormSaveError(String error) {
    return 'Falha ao salvar produto: $error';
  }

  @override
  String get packagingsTitle => 'Formas de compra (embalagens)';

  @override
  String packagingProductSubtitle(String name, String unit) {
    return '$name (Base: $unit)';
  }

  @override
  String get packagingEmpty =>
      'Nenhuma embalagem comercial cadastrada. O estoque será movimentado diretamente na unidade base.';

  @override
  String packagingFactorLabel(int factor, String unit, String defaultTag) {
    return 'Fator: $factor $unit $defaultTag';
  }

  @override
  String get packagingDefaultTag => '• (Padrão)';

  @override
  String get packagingInactivateTooltip => 'Inativar';

  @override
  String get packagingAddButton => 'Adicionar Embalagem';

  @override
  String get packagingDialogNewTitle => 'Nova Embalagem Comercial';

  @override
  String get packagingDialogNameLabel => 'Nome da Embalagem *';

  @override
  String get packagingDialogNameHint => 'Ex: Fardo c/ 10 un, Caixa c/ 12';

  @override
  String packagingDialogQtyLabel(String unit) {
    return 'Conteúdo de uma embalagem ($unit) *';
  }

  @override
  String get packagingDialogQtyHint => 'Ex: 10, 5000';

  @override
  String get packagingDialogDefaultSwitch => 'Embalagem Padrão de Compra';

  @override
  String get packagingDialogValidation =>
      'Informe nome e quantidade maior que 0.';

  @override
  String packagingDialogSaveError(String error) {
    return 'Falha ao cadastrar: $error';
  }

  @override
  String packagingDialogLoadError(String error) {
    return 'Erro ao carregar embalagens: $error';
  }

  @override
  String get basketTypesHeaderTitle => 'Tipos de Cestas e Receitas';

  @override
  String get basketTypeSearchHint => 'Buscar por nome ou código...';

  @override
  String get basketTypeEmpty => 'Nenhum tipo de cesta encontrado.';

  @override
  String get basketTypeInactivateTitle => 'Inativar Tipo de Cesta';

  @override
  String basketTypeInactivateConfirm(String name) {
    return 'Deseja inativar \"$name\"?\n\nA exclusão física é proibida para preservar histórico de vendas e montagens.';
  }

  @override
  String get basketTypeInactivateButton => 'Inativar';

  @override
  String get basketTypeInactivatedSuccess =>
      'Tipo de cesta inativado com sucesso.';

  @override
  String basketTypeInactivateError(String error) {
    return 'Falha ao inativar: $error';
  }

  @override
  String basketTypeLoadError(String error) {
    return 'Erro ao carregar tipos de cestas: $error';
  }

  @override
  String basketTypeRecipeActive(int version, int count) {
    return 'Receita Versão $version Ativa ($count itens)';
  }

  @override
  String get basketTypeRecipeNone => 'Sem receita cadastrada';

  @override
  String get basketTypeManageRecipe => 'Gerenciar Receita';

  @override
  String get basketTypeFormNewTitle => 'Novo Tipo de Cesta';

  @override
  String get basketTypeFormEditTitle => 'Editar Tipo de Cesta';

  @override
  String get basketTypeFormCodeLabel => 'Código da Cesta *';

  @override
  String get basketTypeFormCodeHint => 'Ex: BASICA-FAMILIA-01';

  @override
  String get basketTypeFormCodeRequired => 'Código é obrigatório';

  @override
  String get basketTypeFormNameLabel => 'Nome da Cesta *';

  @override
  String get basketTypeFormNameHint => 'Ex: Cesta Básica Familiar Completa';

  @override
  String get basketTypeFormNameRequired => 'Nome é obrigatório';

  @override
  String get basketTypeFormCategoryLabel => 'Categoria *';

  @override
  String get basketTypeFormPriceLabel => 'Preço de Venda Padrão (R\$)';

  @override
  String get basketTypeFormDescLabel => 'Descrição / Apresentação';

  @override
  String get basketTypeFormAllowsCustom => 'Permite Personalização';

  @override
  String get basketTypeFormAllowsCustomSubtitle =>
      'Permite que operadores alterem itens durante a montagem física.';

  @override
  String get basketTypeFormTracksStock => 'Estoque de cestas prontas';

  @override
  String get basketTypeFormTracksStockSubtitle =>
      'Mantém o saldo de cestas prontas no estoque. Na venda, permite escolher Pronta ou Montar.';

  @override
  String get basketTypeFormStatusActive => 'Status Ativo';

  @override
  String get basketTypeFormSaveCreate => 'Cadastrar Tipo de Cesta';

  @override
  String get basketTypeFormSaveUpdate => 'Atualizar Tipo de Cesta';

  @override
  String basketTypeFormSaveError(String error) {
    return 'Falha ao salvar tipo de cesta: $error';
  }

  @override
  String recipeAppTitle(String name) {
    return 'Receita: $name';
  }

  @override
  String get recipeNewVersionButton => 'Nova Versão';

  @override
  String get recipeEmptyVersions =>
      'Nenhuma versão de receita cadastrada para esta cesta.';

  @override
  String get recipeCreateFirstVersion => 'Criar Primeira Versão';

  @override
  String get recipeImmutabilityBanner =>
      'Você pode mudar a composição e o preço sem criar outro tipo de cesta. Vendas não canceladas e montagens ainda existentes protegem a receita utilizada. Crie outra receita neste mesmo tipo para as próximas operações.';

  @override
  String get recipeVersionDisplayed => 'Versão em exibição: ';

  @override
  String recipeVersionItem(int version) {
    return 'Versão $version';
  }

  @override
  String get recipeStatusActive => 'ATIVA';

  @override
  String get recipeStatusArchived => 'ARQUIVADA';

  @override
  String recipeNotesLabel(String notes) {
    return 'Notas da Versão: \"$notes\"';
  }

  @override
  String recipeSectionHeader(String section, int count) {
    return 'Seção: $section ($count itens)';
  }

  @override
  String get recipeDialogTitle => 'Nova Versão de Receita (Imutável)';

  @override
  String get recipeDialogSubtitle =>
      'Defina a composição e o preço desta receita. Vendas anteriores mantêm os valores registrados.';

  @override
  String get recipeDialogNotesLabel => 'Motivo da revisão / Notas da versão';

  @override
  String get recipeDialogNotesHint =>
      'Ex: Troca de fornecedor do arroz, ajuste sazonal';

  @override
  String recipeDialogItemsTitle(int count) {
    return 'Insumos da Receita ($count)';
  }

  @override
  String get recipeDialogAllProductsAdded =>
      'Todos os produtos ativos já estão na receita.';

  @override
  String get recipeDialogDuplicateItem =>
      'Este insumo já está na receita. Consolide a quantidade em um único item.';

  @override
  String get recipeDialogNoItems =>
      'Nenhum insumo adicionado. Clique em \"Adicionar Insumo\".';

  @override
  String recipeDialogQtyLabel(String unit) {
    return 'Qtd ($unit)';
  }

  @override
  String get recipeDialogValidationMinItems =>
      'A receita deve ter ao menos 1 item.';

  @override
  String get recipeDialogSaveButton => 'Salvar Nova Versão';

  @override
  String get recipeDialogSaveSuccess =>
      'Nova versão de receita criada com sucesso!';

  @override
  String recipeDialogSaveError(String error) {
    return 'Falha ao criar receita: $error';
  }

  @override
  String recipeLoadError(String error) {
    return 'Erro ao carregar receitas: $error';
  }

  @override
  String recipeLoadProductsError(String error) {
    return 'Erro ao carregar insumos: $error';
  }

  @override
  String get recipeNoActiveProducts =>
      'Nenhum insumo ativo encontrado. Cadastre produtos primeiro.';

  @override
  String purchaseNumberTitle(int number) {
    return 'Compra #$number';
  }

  @override
  String get purchaseFilterAll => 'Todos os Status';

  @override
  String get purchaseFilterConfirmed => 'Confirmadas';

  @override
  String get purchaseFilterDraft => 'Rascunho';

  @override
  String get purchaseFilterCanceled => 'Canceladas';

  @override
  String get purchaseSearchHint => 'Buscar por fornecedor, NF ou notas...';

  @override
  String get purchaseEmpty => 'Nenhuma compra registrada.';

  @override
  String purchaseCancelTitle(int number) {
    return 'Cancelar Compra #$number';
  }

  @override
  String get purchaseCancelWarning =>
      'Esta operação realizará o estorno contábil dos produtos no livro-razão. Se os produtos já foram consumidos e não houver saldo suficiente, a operação será rejeitada.';

  @override
  String get purchaseCancelReasonLabel => 'Motivo do Cancelamento';

  @override
  String get purchaseCancelReasonHint =>
      'Ex: Nota fiscal cancelada pelo fornecedor';

  @override
  String get purchaseCancelReasonRequired => 'Informe o motivo do cancelamento';

  @override
  String get purchaseCancelSuccess =>
      'Compra cancelada e estoque estornado com sucesso!';

  @override
  String get purchaseEditDraft => 'Editar rascunho';

  @override
  String get purchaseDeleteDraftButton => 'Excluir rascunho';

  @override
  String purchaseDeleteDraftTitle(int number) {
    return 'Excluir compra #$number?';
  }

  @override
  String get purchaseDeleteDraftWarning =>
      'O rascunho e seus itens serão removidos permanentemente. Isso não movimenta o estoque e não pode ser desfeito.';

  @override
  String get purchaseDeleteDraftSuccess => 'Rascunho excluído.';

  @override
  String purchaseCancelError(String error) {
    return 'Falha ao cancelar compra: $error';
  }

  @override
  String purchaseLoadError(String error) {
    return 'Erro ao carregar compras: $error';
  }

  @override
  String purchaseDetailItems(int count) {
    return 'Itens da Compra ($count)';
  }

  @override
  String purchaseDetailInvoice(String invoice) {
    return 'NF: $invoice';
  }

  @override
  String purchaseDetailSupplier(String supplier) {
    return 'Fornecedor: $supplier';
  }

  @override
  String purchaseDetailDate(String date) {
    return 'Data: $date';
  }

  @override
  String purchaseDetailTotal(String total) {
    return 'Total da Compra: $total';
  }

  @override
  String get purchaseStatusConfirmed => 'CONFIRMADA';

  @override
  String get purchaseStatusDraft => 'RASCUNHO';

  @override
  String get purchaseStatusCanceled => 'CANCELADA';

  @override
  String get purchaseCancelButton => 'Cancelar Compra';

  @override
  String get purchaseFormTitle => 'Nova Entrada de Compras';

  @override
  String get purchaseEditDraftTitle => 'Editar rascunho de compra';

  @override
  String get purchaseDraftUpdateButton => 'Salvar alterações';

  @override
  String get purchaseFormSupplierLabel => 'Fornecedor *';

  @override
  String get purchaseFormSupplierHint => 'Ex: Atacadão Distribuidora Ltda';

  @override
  String get purchaseFormSupplierRequired => 'Informe o fornecedor';

  @override
  String get purchaseFormInvoiceLabel => 'Número da NF';

  @override
  String get purchaseFormInvoiceHint => 'Ex: 123456';

  @override
  String get purchaseFormDateLabel => 'Data da Compra';

  @override
  String get purchaseFormNotesLabel => 'Observações';

  @override
  String get purchaseFormNotesHint =>
      'Ex: Prazo de pagamento 30 dias, lote promocional';

  @override
  String get purchaseFormItemsHeader => 'Itens da Compra';

  @override
  String get purchaseFormAddItem => 'Adicionar Item';

  @override
  String get purchaseFormProductLabel => 'Produto *';

  @override
  String get purchaseFormPackagingLabel => 'Forma de compra';

  @override
  String purchaseFormBaseUnitPackaging(String unit) {
    return 'Sem embalagem: comprar em $unit';
  }

  @override
  String get purchaseFormQtyLabel => 'Qtd. Embalagens';

  @override
  String get purchaseFormQtyRequired => 'Informe a quantidade';

  @override
  String get purchaseFormUnitCostLabel => 'Preço Unitário (R\$)';

  @override
  String get purchaseFormUnitCostRequired => 'Informe o preço unitário';

  @override
  String purchaseFormTotalItem(String total) {
    return 'Subtotal: $total';
  }

  @override
  String purchaseFormTotalOverall(String total) {
    return 'Total Geral da Compra: $total';
  }

  @override
  String get purchaseFormSaveButton => 'Salvar Compra';

  @override
  String get purchaseFormSuccess => 'Compra registrada com sucesso!';

  @override
  String get purchaseDraftUpdateSuccess => 'Rascunho atualizado.';

  @override
  String purchaseFormSaveError(String error) {
    return 'Falha ao registrar compra: $error';
  }

  @override
  String get purchaseFormAtLeastOneItem =>
      'Adicione ao menos um item à compra.';

  @override
  String purchaseFormConvertedStock(int qty, String unit) {
    return 'Equivalente em Estoque: $qty $unit';
  }

  @override
  String get inventorySummaryHeaderTitle => 'Saldo de Estoque em Tempo Real';

  @override
  String get inventorySummaryHistoryTooltip => 'Extrato do Razão Contábil';

  @override
  String get inventorySummaryAdjustmentTooltip => 'Ajuste Manual';

  @override
  String get inventorySummarySearchHint => 'Buscar por produto, categoria...';

  @override
  String get inventorySummaryBelowMinFilter => 'Apenas Abaixo do Mínimo';

  @override
  String get inventorySummaryEmpty =>
      'Nenhum item em estoque com os filtros selecionados.';

  @override
  String inventorySummaryCurrentStock(String quantity) {
    return 'Saldo Atual: $quantity';
  }

  @override
  String inventorySummaryMinStock(String quantity) {
    return 'Mínimo: $quantity';
  }

  @override
  String inventorySummaryAverageCost(String cost) {
    return 'Custo Médio Ponderado: $cost';
  }

  @override
  String inventorySummaryTotalValue(String value) {
    return 'Valor em Estoque: $value';
  }

  @override
  String get inventorySummaryAdjustmentSuccess =>
      'Ajuste de estoque registrado com sucesso!';

  @override
  String inventorySummaryLoadError(String error) {
    return 'Erro ao carregar saldo de estoque: $error';
  }

  @override
  String get inventorySummaryStatusOk => 'ESTOQUE REGULAR';

  @override
  String get inventorySummaryStatusAlert => 'ALERTA: ABAIXO DO MÍNIMO';

  @override
  String get inventoryMovementsHeaderTitle => 'Extrato do Razão Contábil';

  @override
  String get inventoryMovementsFilterAll => 'Todos os Tipos';

  @override
  String get inventoryMovementsFilterPurchase => 'Compras';

  @override
  String get inventoryMovementsFilterCancel => 'Estornos';

  @override
  String get inventoryMovementsFilterAdjustment => 'Ajustes Manuais';

  @override
  String get inventoryMovementsFilterAssembly => 'Produção / Montagem';

  @override
  String get inventoryMovementsEmpty =>
      'Nenhuma movimentação registrada no livro-razão.';

  @override
  String inventoryMovementDelta(String delta, String unit) {
    return 'Qtd: $delta $unit';
  }

  @override
  String inventoryMovementBalanceAfter(String balance, String unit) {
    return 'Saldo Após: $balance $unit';
  }

  @override
  String inventoryMovementUnitPrice(String price) {
    return 'Custo Unit: $price';
  }

  @override
  String inventoryMovementReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String inventoryMovementsLoadError(String error) {
    return 'Erro ao carregar extrato de movimentações: $error';
  }

  @override
  String get movementPurchase => 'COMPRA';

  @override
  String get movementPurchaseCancel => 'ESTORNO COMPRA';

  @override
  String get movementAdjustmentIn => 'SOBRA / ENTRADA';

  @override
  String get movementAdjustmentOut => 'AVARIA / SAÍDA';

  @override
  String get movementLoss => 'PERDA / DESCARTE';

  @override
  String get movementAssemblyConsume => 'CONSUMO MONTAGEM';

  @override
  String get movementAssemblyProduce => 'CESTA MONTADA';

  @override
  String get movementSale => 'VENDA';

  @override
  String get stockAdjustmentDialogTitle => 'Ajuste Manual de Estoque';

  @override
  String get stockAdjustmentProductLabel => 'Produto *';

  @override
  String get stockAdjustmentTypeLabel => 'Tipo de Ajuste *';

  @override
  String get stockAdjustmentTypeLoss => 'Perda / Avaria (-)';

  @override
  String get stockAdjustmentTypeCount => 'Contagem Física (Balanço)';

  @override
  String stockAdjustmentQtyLabel(String unit) {
    return 'Quantidade ($unit)';
  }

  @override
  String get stockAdjustmentQtyRequired =>
      'Informe uma quantidade válida maior que 0';

  @override
  String get stockAdjustmentReasonHint =>
      'Ex: Quebra acidental no transporte, acerto de inventário';

  @override
  String get stockAdjustmentReasonRequired =>
      'A justificativa é obrigatória para auditoria contábil';

  @override
  String get stockAdjustmentConfirmButton => 'Confirmar Ajuste';

  @override
  String get stockAdjustmentSelectProductError => 'Selecione um produto.';

  @override
  String get pairingViewTitle => 'Pareamento do Dispositivo';

  @override
  String get pairingTabManual => 'Código PIN';

  @override
  String get pairingTabQr => 'Escanear QR';

  @override
  String get pairingPinValidation => 'O PIN deve conter exatamente 6 dígitos.';

  @override
  String get pairingUrlValidation => 'Informe o endereço IP/URL do servidor.';

  @override
  String pairingSuccess(String name) {
    return 'Dispositivo \"$name\" pareado com sucesso!';
  }

  @override
  String pairingError(String error) {
    return 'Erro ao parear: $error';
  }

  @override
  String get pairingServerUrlHint => 'Ex: https://192.168.1.100:8000';

  @override
  String get pairingPinHint => 'PIN de 6 dígitos exibido no servidor';

  @override
  String get pairingFingerprintHint =>
      'Fingerprint SHA256 do certificado (opcional se auto-assinado)';

  @override
  String get pairingDeviceNameHint => 'Ex: Tablet Depósito 01';

  @override
  String get pairingButton => 'Parear Dispositivo';

  @override
  String get pairingQrInstructions =>
      'Aponte a câmera para o QR Code de Pareamento exibido na tela do servidor central.';

  @override
  String get pairingScanning => 'Processando pareamento...';

  @override
  String get settingsHeaderTitle => 'Configurações de Rede e Dispositivo';

  @override
  String get settingsServerSection => 'Servidor Local';

  @override
  String get settingsServerUrlHint => 'Ex: https://192.168.1.100:8000';

  @override
  String get settingsFingerprintHint => 'Fingerprint SHA256 do certificado';

  @override
  String get settingsSaved => 'Configurações de rede salvas.';

  @override
  String get settingsDeviceInfoSection => 'Identificação do Dispositivo';

  @override
  String get settingsDeviceIdLabel => 'ID do Dispositivo (UUID)';

  @override
  String get settingsDeviceNameLabel => 'Nome do Dispositivo';

  @override
  String get settingsDeviceTokenLabel => 'Token de Autenticação';

  @override
  String get settingsDeviceTokenConfigured => 'Configurado e Ativo';

  @override
  String get settingsDeviceTokenMissing => 'Não autenticado';

  @override
  String get settingsSaveButton => 'Salvar Configurações';

  @override
  String get settingsUnpairButton => 'Desvincular Dispositivo';

  @override
  String get settingsUnpairTitle => 'Confirmar Desconexão';

  @override
  String get settingsUnpairContent =>
      'Deseja realmente desvincular este dispositivo do servidor local?';

  @override
  String get settingsUnpairConfirm => 'Desvincular';

  @override
  String get settingsUnpairedSuccess => 'Dispositivo desvinculado com sucesso.';

  @override
  String get settingsPairNewButton => 'Novo Pareamento';

  @override
  String get settingsGenerateQrTitle => 'Pareamento de Celulares / Tablets';

  @override
  String get settingsGenerateQrButton => 'Gerar QR Code para Celular';

  @override
  String get settingsQrDialogTitle => 'Conectar Celular / Tablet';

  @override
  String get settingsQrDialogInstructions =>
      'No celular Android, abra o aplicativo, toque em \'Parear Dispositivo\' > aba \'Escanear QR\' e aponte a câmera para a imagem abaixo:';

  @override
  String settingsPinExpiresLabel(String pin) {
    return 'PIN válido por 5 minutos: $pin';
  }

  @override
  String get settingsQrClose => 'Fechar';

  @override
  String get cameraPermissionDenied => 'O acesso à câmera não foi permitido.';

  @override
  String get pairingCameraPermissionHint =>
      'Permita o acesso à câmera para ler o QR Code. Se o Android não perguntar novamente, habilite a câmera nas configurações de permissões deste aplicativo e volte para esta tela.';

  @override
  String get pairingCameraUnavailable =>
      'Não foi possível abrir a câmera. Feche outros aplicativos que estejam usando a câmera e tente novamente.';

  @override
  String get cameraPermissionRequest => 'Ativar Câmera';

  @override
  String purchaseDetailUnitCost(String cost) {
    return 'Unit.: $cost';
  }

  @override
  String get purchaseStatusConfirmedWithStock => 'Confirmada (Aumenta Estoque)';

  @override
  String get purchaseStatusDraftWithoutStock =>
      'Rascunho (Sem movimentar estoque)';

  @override
  String purchaseItemIndex(int index) {
    return 'Item #$index';
  }

  @override
  String get stockAdjustmentQtyHint => 'Ex: 10';

  @override
  String get categoryFood => 'Alimentação';

  @override
  String get categoryCleaning => 'Limpeza';

  @override
  String get categoryMeat => 'Carnes & Frios';

  @override
  String get categoryOthers => 'Outros';

  @override
  String get categoryInput => 'Insumo';

  @override
  String get categoryAll => 'Todas';

  @override
  String get categoryStandard => 'Padrão';

  @override
  String get categoryChristmas => 'Natalina';

  @override
  String get categoryCustom => 'Personalizada';

  @override
  String recipeUnknownIngredient(String id) {
    return 'Insumo ($id)';
  }

  @override
  String get productionBatchViewIngredients => 'Ver Insumos';

  @override
  String get productionDisassembleNoIngredients =>
      'Nenhum insumo registrado neste lote.';

  @override
  String get homeLocalConnectionInfo => 'Informações da Conexão Local';

  @override
  String get homeApiVersionLabel => 'Versão da API';

  @override
  String get homeDatabaseStatusLabel => 'Banco de Dados';

  @override
  String get homeTlsFingerprintLabel => 'Impressão Digital TLS (SHA-256)';

  @override
  String get homeNotConfigured => 'Não configurado';

  @override
  String get homeNotAvailable => 'Não disponível';

  @override
  String get homePending => 'Pendente';

  @override
  String get errorCustomerDocumentConflict =>
      'Já existe um cliente cadastrado com este documento (CPF/CNPJ).';

  @override
  String get errorCreditLimitExceeded =>
      'Limite de crédito do cliente excedido para esta operação.';

  @override
  String get homePhase5Header => 'Fase 5 — Vendas, Clientes e Recebíveis';

  @override
  String get homeCustomersDescription =>
      'Cadastro de clientes, limites de crédito e histórico financeiro';

  @override
  String get homeSalesDescription =>
      'Vendas diretas, montagem sob demanda e vendas a prazo';

  @override
  String get homeReceivablesDescription =>
      'Controle de fiados, vencimentos e recebimentos parciais';

  @override
  String get moduleCustomers => 'Clientes';

  @override
  String get moduleSales => 'Vendas de Cestas';

  @override
  String get moduleReceivables => 'Contas a Receber (Fiados)';

  @override
  String get customersTitle => 'Clientes';

  @override
  String get customerNew => 'Novo Cliente';

  @override
  String get customerEdit => 'Editar Cliente';

  @override
  String get customerName => 'Nome / Razão Social';

  @override
  String get customerDocument => 'CPF / CNPJ';

  @override
  String get customerPhone => 'Telefone';

  @override
  String get customerAddress => 'Endereço';

  @override
  String get customerCreditLimit => 'Limite de Crédito';

  @override
  String get customerCreditLimitUnlimited => 'Sem limite pré-definido';

  @override
  String get customerCurrentDebt => 'Dívida Atual';

  @override
  String get customerAvailableCredit => 'Crédito Disponível';

  @override
  String get customerStatement => 'Extrato do Cliente';

  @override
  String customerStatementTitle(String name) {
    return 'Extrato Financeiro — $name';
  }

  @override
  String get customerStatementEmpty =>
      'Nenhuma movimentação registrada para este cliente.';

  @override
  String get customerInactivate => 'Inativar Cliente';

  @override
  String customerInactivateConfirm(String name) {
    return 'Deseja realmente inativar o cliente \"$name\"?';
  }

  @override
  String get customerActive => 'Ativo';

  @override
  String get customerInactive => 'Inativo';

  @override
  String get customerSavedSuccess => 'Cliente salvo com sucesso.';

  @override
  String get customerInactivatedSuccess => 'Cliente inativado com sucesso.';

  @override
  String get customersEmpty => 'Nenhum cliente cadastrado.';

  @override
  String get customerNameHint => 'Ex: Supermercado São José';

  @override
  String get customerDocumentHint => 'CPF ou CNPJ';

  @override
  String get customerPhoneHint => '(11) 99999-9999';

  @override
  String get customerAddressHint => 'Rua, número, bairro, cidade';

  @override
  String get salesTitle => 'Vendas de Cestas';

  @override
  String get saleNew => 'Nova Venda';

  @override
  String saleNumber(int number) {
    return 'Venda #$number';
  }

  @override
  String get saleDate => 'Data da Venda';

  @override
  String get saleCustomer => 'Cliente';

  @override
  String get saleCustomerAnonymous => 'Consumidor Não Identificado (Balcão)';

  @override
  String get salePaymentMode => 'Forma de Pagamento';

  @override
  String get salePaymentModeCash => 'Dinheiro (À Vista)';

  @override
  String get salePaymentModePix => 'PIX';

  @override
  String get salePaymentModeCard => 'Cartão';

  @override
  String get salePaymentModeCredit => 'Venda a Prazo (Fiado)';

  @override
  String get saleDueDate => 'Data de Vencimento';

  @override
  String get saleDueDateSuggested => 'Sugerido 30 dias';

  @override
  String get saleItemsSection => 'Cestas e Composição';

  @override
  String get saleAddItem => 'Adicionar Cesta';

  @override
  String get saleBasketType => 'Tipo de Cesta';

  @override
  String get saleQuantity => 'Quantidade';

  @override
  String get saleUnitPrice => 'Preço Unitário';

  @override
  String get saleDiscount => 'Desconto';

  @override
  String get saleSubtotal => 'Subtotal';

  @override
  String get saleAssemblyMode => 'Origem da Cesta';

  @override
  String get saleAssemblyModeStock => 'Pronta';

  @override
  String get saleAssemblyModeDemand => 'Montar';

  @override
  String get saleGrossTotal => 'Total Bruto';

  @override
  String get saleTotalDiscount => 'Total de Descontos';

  @override
  String get saleNetTotal => 'Total Líquido';

  @override
  String get saleStatusConfirmed => 'Confirmada';

  @override
  String get saleStatusCanceled => 'Cancelada';

  @override
  String get salePaymentStatusPaid => 'Pago';

  @override
  String get salePaymentStatusPending => 'Pendente';

  @override
  String get salePaymentStatusPartial => 'Parcial';

  @override
  String get saleCancel => 'Cancelar Venda';

  @override
  String saleCancelConfirm(int number) {
    return 'Cancelar a venda nº $number?';
  }

  @override
  String get saleCancelReason => 'Motivo do cancelamento';

  @override
  String get saleCanceledSuccess =>
      'Venda cancelada e estoque estornado com sucesso.';

  @override
  String get saleCreatedSuccess => 'Venda registrada com sucesso.';

  @override
  String get saleCreditLimitAlertTitle => 'Limite de Crédito Excedido';

  @override
  String saleCreditLimitAlertMessage(String amount) {
    return 'O valor da venda excede o limite de crédito do cliente em $amount. Deseja autorizar a liberação manual desta venda?';
  }

  @override
  String get saleCreditLimitAuthorize => 'Autorizar e Concluir Venda';

  @override
  String saleStockAvailable(int qty) {
    return 'Cestas prontas disponíveis: $qty';
  }

  @override
  String get salesEmpty => 'Nenhuma venda registrada.';

  @override
  String get saleCreditCustomerRequired =>
      'Vendas a prazo (fiado) exigem a seleção de um cliente cadastrado.';

  @override
  String get saleSelectBasketTypeRequired =>
      'Selecione a cesta para todos os itens.';

  @override
  String get saleQuantityMustBePositive =>
      'A quantidade deve ser maior que zero.';

  @override
  String saleInsufficientStockAlert(String name, int stock, int qty) {
    return 'Estoque insuficiente de cestas prontas para \"$name\". Saldo: $stock, Solicitado: $qty. Marque \"Montar Imediatamente\" para produzir na hora.';
  }

  @override
  String get saleAnonymousCustomerHint =>
      'Nome do cliente no balcão (opcional)';

  @override
  String saleCmvAndMargin(String cmv, String margin) {
    return 'CMV: $cmv | Margem: $margin';
  }

  @override
  String saleNotesPrefix(String notes) {
    return 'Obs: $notes';
  }

  @override
  String get receivablesTitle => 'Contas a Receber (Fiados)';

  @override
  String get receivablesSummaryTotal => 'Total a Receber';

  @override
  String get receivablesSummaryOpen => 'Títulos em Aberto';

  @override
  String get receivablesSummaryPartial => 'Pagamentos Parciais';

  @override
  String get receivablesSummaryPaid => 'Títulos Quitados';

  @override
  String get receivableOriginalAmount => 'Valor Original';

  @override
  String get receivablePaidAmount => 'Valor Pago';

  @override
  String get receivableRemainingBalance => 'Saldo Devedor';

  @override
  String receivableDueDateLabel(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get receivableOverdue => 'Vencido';

  @override
  String get receivableRecordPayment => 'Receber Pagamento';

  @override
  String get receivablePaymentAmount => 'Valor a Receber';

  @override
  String get receivablePaymentMethod => 'Meio de Recebimento';

  @override
  String get receivablePaymentNotes => 'Observações do Pagamento';

  @override
  String get receivablePaymentSuccess => 'Recebimento registrado com sucesso.';

  @override
  String get receivablePaymentsHistory => 'Histórico de Amortizações';

  @override
  String get receivableNoPayments => 'Nenhum pagamento registrado ainda.';

  @override
  String get receivableStatusOpen => 'Em Aberto';

  @override
  String get receivableStatusPartial => 'Parcialmente Pago';

  @override
  String get receivableStatusPaid => 'Quitado';

  @override
  String get receivableStatusCanceled => 'Cancelado';

  @override
  String get receivablesEmpty => 'Nenhum título a receber encontrado.';

  @override
  String get receivablePaymentAmountMustBePositive =>
      'Informe um valor maior que zero.';

  @override
  String get receivablePaymentAmountExceedsBalance =>
      'Valor informado excede o saldo devedor.';

  @override
  String get homePhase6Header => 'Fase 6: Expedição, Conferência e Custódia';

  @override
  String get moduleDispatches => 'Saídas e Conferências';

  @override
  String get moduleResponsiblePersons => 'Pessoas Responsáveis';

  @override
  String get homeResponsiblePersonsDescription =>
      'Cadastro de entregadores, vendedores externos e motoristas';

  @override
  String get responsiblePersonsTitle => 'Pessoas Responsáveis';

  @override
  String get responsiblePersonName => 'Nome';

  @override
  String get responsiblePersonCustodyTitle => 'Custódia Atual de Cestas';

  @override
  String get dispatchesTitle => 'Saídas Físicas e Conferência';

  @override
  String dispatchNumber(int number) {
    return 'Saída #$number';
  }

  @override
  String get dispatchDate => 'Data da Saída';

  @override
  String get dispatchStatusResolved => 'Resolvido';

  @override
  String get dispatchDuplicateBasketConsolidatedNotice =>
      'Cesta repetida: será consolidada automaticamente no despacho.';

  @override
  String get conferencePhysicalEquationTitle =>
      'Equação Física de Custódia (4 Termos)';

  @override
  String conferenceDispatchedLabel(int qty) {
    return '1. Retiradas: $qty';
  }

  @override
  String conferenceSoldLabel(int qty) {
    return '2. Vendidas: $qty';
  }

  @override
  String conferenceReturnedLabel(int qty) {
    return '3. Devolvidas Intactas: $qty';
  }

  @override
  String conferenceLostLabel(int qty) {
    return '4. Avariadas / Perdidas: $qty';
  }

  @override
  String get conferencePhysicalEquationBalanced =>
      'Equação Física Bateu (Sem divergências)';

  @override
  String get conferencePhysicalEquationDivergent =>
      'Divergência Física Detectada!';

  @override
  String conferenceExpectedCashLabel(String amount) {
    return 'Dinheiro em Mãos Esperado: $amount';
  }

  @override
  String get conferenceFinancialDivergent =>
      'Divergência Financeira Detectada!';

  @override
  String get conferenceFinancialBalanced =>
      'Financeiro Bateu (Repasse integral)';

  @override
  String get conferenceDirectNotice =>
      '* Pix e cartões recebidos diretamente na conta da empresa NÃO são devidos pelo motorista/entregador.';

  @override
  String get conferenceExpenseExceedsNotice =>
      'As despesas autorizadas superaram as vendas em dinheiro da rota. Saldo credor ao entregador / ressarcimento pela empresa.';

  @override
  String saleCustodyStockAvailable(int qty) {
    return 'Saldo sob custódia: $qty';
  }

  @override
  String get homePhase7Header => 'Financeiro';

  @override
  String get modulePayables => 'Contas a Pagar';

  @override
  String get homePayablesDescription =>
      'Boletos, cheques, empréstimos, fornecedores e parcelamentos';

  @override
  String get payablesTitle => 'Contas a Pagar';

  @override
  String get payablesNew => 'Nova Obrigação a Pagar';

  @override
  String get payableDescription => 'Descrição';

  @override
  String get payableBeneficiary => 'Favorecido / Fornecedor';

  @override
  String get payableCategory => 'Categoria';

  @override
  String get payableNature => 'Natureza';

  @override
  String get payableNatureBusiness => 'Operacional (Empresa)';

  @override
  String get payableNaturePersonal => 'Retirada Particular (Sócios)';

  @override
  String get payableOriginalAmount => 'Valor Nominal';

  @override
  String get payablePaidAmount => 'Valor Pago';

  @override
  String get payableBalance => 'Saldo Devedor';

  @override
  String get payableDueDate => 'Vencimento';

  @override
  String get payablePaymentMethod => 'Forma de Pagamento';

  @override
  String get payableStatus => 'Situação';

  @override
  String get payableStatusOpen => 'Em Aberto';

  @override
  String get payableStatusPartial => 'Parcialmente Pago';

  @override
  String get payableStatusPaid => 'Quitado';

  @override
  String get payableStatusCanceled => 'Cancelado';

  @override
  String get payableOverdue => 'Vencido';

  @override
  String payableInstallment(int current, int total) {
    return 'Parcela $current de $total';
  }

  @override
  String get payableRecurrent => 'Despesa Recorrente';

  @override
  String get payableRecurrenceMonthly => 'Mensal';

  @override
  String get payableRecurrenceWeekly => 'Semanal';

  @override
  String get payableRecurrenceYearly => 'Anual';

  @override
  String get payableTotalInstallments => 'Total de Parcelas';

  @override
  String get payablePaymentAction => 'Pagar / Amortizar';

  @override
  String get payableHistoryAction => 'Histórico de Pagamentos';

  @override
  String get payableCancelAction => 'Cancelar Obrigação';

  @override
  String get payableCancelReason => 'Motivo do cancelamento';

  @override
  String get payableCancelConfirm => 'Confirmar cancelamento do título';

  @override
  String get payablePaymentSuccess => 'Pagamento registrado com sucesso';

  @override
  String get payableCancelSuccess => 'Título cancelado com sucesso';

  @override
  String get payableReversePaymentSuccess => 'Pagamento estornado com sucesso';

  @override
  String get payablePaymentAmountExceedsBalance =>
      'O valor informado excede o saldo devedor.';

  @override
  String get payablePaymentAmountMustBePositive =>
      'O valor do pagamento deve ser maior que zero.';

  @override
  String get payableNoPayables => 'Nenhuma obrigação a pagar encontrada.';

  @override
  String get payableFilterMonth => 'Mês';

  @override
  String get payableFilterYear => 'Ano';

  @override
  String get treasuryOpenPayables => 'A Pagar (Obrigações Abertas)';

  @override
  String get treasuryOverduePayables => 'A Pagar Vencidos';

  @override
  String get receivableRepassDirect => 'Direto na Empresa / Loja';

  @override
  String get receivableRepassPending =>
      'Pendente de Repasse (Dinheiro em Rota)';

  @override
  String get receivableRepassDone => 'Repassado e Liquidado';

  @override
  String get receivableReversePayment => 'Estornar Recebimento';

  @override
  String get receivableReverseReason =>
      'Justificativa do estorno do recebimento';

  @override
  String get receivableReverseSuccess => 'Recebimento estornado com sucesso';

  @override
  String get payableGenerateNextRecurrence => 'Gerar Próxima Recorrência';

  @override
  String get payableRecurrenceSuccess =>
      'Nova parcela de recorrência gerada com sucesso!';

  @override
  String get payableFilterPeriod => 'Período de Vencimento';

  @override
  String get payableFilterPeriodAll => 'Todos os períodos';

  @override
  String get receivableFilterPeriod => 'Período da Venda';

  @override
  String get receivableFilterDuePeriod => 'Período do Vencimento';

  @override
  String get receivableFilterCustomer => 'Cliente';

  @override
  String get receivableFilterBasketType => 'Cesta';

  @override
  String get receivableFilterMinValue => 'Valor Mínimo';

  @override
  String get receivableFilterMaxValue => 'Valor Máximo';

  @override
  String get receivableFilterAdvanced => 'Filtros Avançados';

  @override
  String get receivableFilterHideAdvanced => 'Ocultar Filtros';

  @override
  String get receivableFilterClear => 'Limpar Filtros';

  @override
  String get receivableFilterApply => 'Aplicar Filtros';

  @override
  String get homePhase8Header =>
      'Fase 8: Dashboard, Relatórios, Planilhas e Impressão';

  @override
  String get moduleDashboard => 'Dashboard Geral';

  @override
  String get homeDashboardDescription =>
      'Vendas, estoque, recebimentos, pagamentos e resultado';

  @override
  String get moduleReports => 'Relatórios & Planilhas';

  @override
  String get homeReportsDescription =>
      'Consultas analíticas, exportação CSV/XLSX e impressão PDF';

  @override
  String get moduleBlankForms => 'Formulários A4 & Impressão';

  @override
  String get homeBlankFormsDescription =>
      'Modelos em branco para prancheta e folhas preenchidas para auditoria';

  @override
  String get dashboardTitle => 'Dashboard Operacional e Financeiro';

  @override
  String get dashboardFilterToday => 'Hoje';

  @override
  String get dashboardFilterDate => 'Data Específica';

  @override
  String get dashboardFilterRange => 'Intervalo';

  @override
  String get dashboardFilterMonth => 'Mês';

  @override
  String get dashboardFilterYear => 'Ano';

  @override
  String get dashboardFilterAll => 'Todos';

  @override
  String get dashboardSectionProduction => 'Produção & Montagem';

  @override
  String get dashboardAssembledBaskets => 'Cestas Montadas';

  @override
  String get dashboardSectionSales => 'Vendas & Faturamento';

  @override
  String get dashboardSoldBaskets => 'Cestas Vendidas';

  @override
  String get dashboardTotalSold => 'Valor Total Vendido';

  @override
  String get dashboardSectionDispatches => 'Expedição & Rotas';

  @override
  String get dashboardDispatchedBaskets => 'Cestas em Saída';

  @override
  String get dashboardUnremittedCash => 'Repasses de Rota Pendentes';

  @override
  String get dashboardPendingDivergences => 'Divergências Pendentes';

  @override
  String get dashboardSectionInventory => 'Estoque & Alertas';

  @override
  String get dashboardLowStockAlert => 'Itens Abaixo do Mínimo';

  @override
  String get dashboardStockNormal => 'Estoque em Nível Regular';

  @override
  String get dashboardOverdueReceivables => 'A Receber Vencidos';

  @override
  String get dashboardOverduePayables => 'A Pagar Vencidos';

  @override
  String get dashboardCashInflow => 'Entradas de Caixa';

  @override
  String get dashboardCashOutflow => 'Saídas de Caixa';

  @override
  String get dashboardTreasuryBalance => 'Saldo Disponível (Tesouraria)';

  @override
  String get reportsTitle => 'Relatórios Gerenciais e Planilhas';

  @override
  String get reportSalesDispatches => 'Vendas e Saídas de Cestas';

  @override
  String get reportAssembly => 'Montagem e Produção de Cestas';

  @override
  String get reportPurchasesMovements => 'Compras e Movimentações do Razão';

  @override
  String get reportReceivables => 'Contas a Receber, Pagamentos e Quitações';

  @override
  String get reportPayables => 'Contas a Pagar, Vencimentos e Pagamentos';

  @override
  String get reportDispatchSettlements =>
      'Conferência de Saídas e Repasses de Rota';

  @override
  String get reportPhysicalInventory => 'Estoque Atual e Contagem Física';

  @override
  String get reportFinancialSummary =>
      'DRE Gerencial e Demonstrativo Financeiro';

  @override
  String get reportExportCsv => 'Exportar CSV';

  @override
  String get reportExportXlsx => 'Exportar XLSX';

  @override
  String get reportPrintPdf => 'Imprimir / PDF A4';

  @override
  String get reportEmpty =>
      'Nenhum registro encontrado para os filtros selecionados.';

  @override
  String get reportTotals => 'Totais Consolidados';

  @override
  String get blankFormsTitle => 'Formulários A4 para Impressão';

  @override
  String get blankFormsSubtitle =>
      'Modelos em branco para preenchimento manual à caneta e folhas para auditoria física';

  @override
  String get formTypePayments =>
      'Tabela de Pagamentos de Cestas (Fiados / Quitações)';

  @override
  String get formTypePayables => 'Tabela de Contas a Pagar e Vencimentos';

  @override
  String get formTypeDispatch => 'Folha de Conferência de Saídas e Custódia';

  @override
  String get formTypeInventory =>
      'Folha de Contagem Física (Auditoria / Balanço)';

  @override
  String get formModeBlank => 'Formulário em Branco (Para Caneta)';

  @override
  String get formModeFilled => 'Documento Preenchido (Auditoria Física)';

  @override
  String get formActionPrint => 'Visualizar e Imprimir A4';

  @override
  String get formActionDownloadXlsx => 'Baixar Modelo XLSX Vazio';

  @override
  String get formBlankNotice =>
      'Modelos formatados com linhas amplas (mínimo de 8 a 10 mm) para escrita manual confortável em prancheta.';

  @override
  String formXlsxDownloadSuccess(String filename) {
    return 'Planilha XLSX baixada com sucesso: $filename';
  }

  @override
  String formXlsxDownloadError(String error) {
    return 'Erro ao baixar planilha: $error';
  }

  @override
  String get printerLocating => 'Localizando impressoras instaladas...';

  @override
  String get printerSystemDefault => 'Padrão do Sistema';

  @override
  String get printerAvailable => 'Disponível';

  @override
  String get printerActionPrint => 'Imprimir';

  @override
  String reportExportSuccess(String format) {
    return 'Planilha $format exportada com sucesso!';
  }

  @override
  String reportExportError(String format, String error) {
    return 'Erro ao exportar $format: $error';
  }

  @override
  String commonSelectedDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String get commonChange => 'Alterar';

  @override
  String commonPeriodLabel(String start, String end) {
    return 'Período: $start até $end';
  }

  @override
  String commonMonthNumber(int month) {
    return 'Mês $month';
  }

  @override
  String get commonYearLabel => 'Ano:';

  @override
  String get reportPhysicalBelowMinOnly =>
      'Exibir apenas itens abaixo do estoque mínimo';

  @override
  String dashboardSelectedDate(String date) {
    return 'Data selecionada: $date';
  }

  @override
  String dashboardBatchesCount(int count) {
    return 'Lotes ($count)';
  }

  @override
  String get dashboardNoBatches => 'Nenhum lote montado no período.';

  @override
  String dashboardSalesCount(int count) {
    return 'Vendas ($count)';
  }

  @override
  String get dashboardNoSales => 'Nenhuma venda registrada no período.';

  @override
  String dashboardDispatchesCount(int count) {
    return 'Saídas ($count)';
  }

  @override
  String dashboardExaminePendingDivergences(int count) {
    return 'Examinar Divergências Pendentes ($count)';
  }

  @override
  String get dashboardNoDispatches => 'Nenhuma saída registrada no período.';

  @override
  String dashboardDispatchItemSubtitle(String date, int baskets) {
    return 'Data: $date | Cestas: $baskets un.';
  }

  @override
  String get dashboardNoRetainedValues =>
      'Nenhum valor retido por responsável no momento.';

  @override
  String dashboardResponsiblePhone(String phone) {
    return 'Tel: $phone';
  }

  @override
  String dashboardResponsibleDate(String date) {
    return 'Data: $date';
  }

  @override
  String get dashboardNoDivergences => 'Nenhuma divergência pendente.';

  @override
  String dashboardSettledAt(String date) {
    return 'Acerto em: $date';
  }

  @override
  String commonNotesPrefix(String notes) {
    return 'Obs: $notes';
  }

  @override
  String get dashboardStockColBasket => 'Cesta';

  @override
  String get dashboardStockColStore => 'Loja';

  @override
  String get dashboardStockColTransit => 'Trânsito';

  @override
  String get dashboardStockColTotal => 'Total';

  @override
  String get dashboardAllAboveMinStock =>
      'Todos os itens estão acima do estoque mínimo.';

  @override
  String dashboardItemSku(String sku) {
    return 'SKU: $sku';
  }

  @override
  String dashboardCashRecordsCount(int count) {
    return 'Caixa ($count)';
  }

  @override
  String dashboardProjectedInflow(String amount) {
    return 'Entradas Previstas: $amount';
  }

  @override
  String dashboardProjectedOutflow(String amount) {
    return 'Saídas Previstas: $amount';
  }

  @override
  String get dashboardNoCashRecords => 'Nenhum lançamento no período.';

  @override
  String get dashboardNoOpenReceivables => 'Nenhum título a receber em aberto.';

  @override
  String get dashboardNoOpenPayables => 'Nenhuma conta a pagar em aberto.';

  @override
  String get payableCategorySupplier => 'Fornecedor';

  @override
  String get payableCategoryElectricity => 'Energia Elétrica';

  @override
  String get payableCategoryRent => 'Aluguel';

  @override
  String get payableCategoryFreight => 'Frete / Logística';

  @override
  String get payableCategoryFreightShort => 'Frete';

  @override
  String get payableCategoryMaintenance => 'Manutenção';

  @override
  String get payableCategoryLoan => 'Empréstimo';

  @override
  String get payableCategoryCreditCard => 'Cartão de Crédito';

  @override
  String get payableCategoryPartnerWithdrawal => 'Retirada Sócios';

  @override
  String get payableCategoryTaxes => 'Impostos / Taxas';

  @override
  String get payableCategoryTaxesShort => 'Impostos';

  @override
  String get payableCategoryOthers => 'Outros';

  @override
  String get payablePaymentMethodBoleto => 'Boleto';

  @override
  String get payablePaymentMethodPix => 'PIX';

  @override
  String get payablePaymentMethodTransfer => 'Transferência';

  @override
  String get payablePaymentMethodCheck => 'Cheque';

  @override
  String get payablePaymentMethodCard => 'Cartão de Crédito';

  @override
  String get payablePaymentMethodCash => 'Dinheiro';

  @override
  String get payablePaymentMethodOther => 'Outro';

  @override
  String get payableRecurrenceFrequency => 'Periodicidade';

  @override
  String get payableNoPaymentsYet => 'Nenhum pagamento efetuado até o momento.';

  @override
  String get payableRevertPaymentTitle => 'Estornar Pagamento';

  @override
  String get payableRevertPaymentReason => 'Justificativa do Estorno';

  @override
  String get payableConfirmCancelObligation =>
      'Tem certeza que deseja cancelar a obrigação?';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Fev';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Set';

  @override
  String get monthOct => 'Out';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get filterAllOption => 'Todos';

  @override
  String receivablesBasketsPrefix(String summary) {
    return 'Cestas: $summary';
  }

  @override
  String payableConfirmCancelObligationNamed(String description) {
    return 'Tem certeza que deseja cancelar a obrigação \"$description\"?';
  }

  @override
  String get tooltipPrintSelectPrinter => 'Imprimir / Selecionar impressora';

  @override
  String get tooltipShareSavePdf => 'Compartilhar / Salvar PDF';

  @override
  String get payableInstallmentsHelper => 'Dividir em N parcelas mensais';

  @override
  String get payableRevertPaymentTooltip => 'Estornar este pagamento';

  @override
  String get cameraStarting => 'Iniciando leitor de câmera...';

  @override
  String get settingsPairDeviceSection => 'Conexão com o Servidor Local';

  @override
  String get settingsPairDeviceDesc =>
      'Escaneie o QR Code gerado na tela de Configurações do computador ou informe o PIN manualmente para conectar este celular.';

  @override
  String get settingsPairDeviceButton =>
      'Parear Dispositivo (Escanear QR / PIN)';

  @override
  String get settingsServerNetworkSection => 'Rede e Conexão';

  @override
  String get settingsGenerateQrDesc =>
      'Gere um QR Code neste computador para que celulares Android possam escanear e parear automaticamente sem digitar IP, PIN ou Fingerprint.';

  @override
  String get settingsStatusConnectedPaired => 'Conectado e Pareado com Sucesso';

  @override
  String get settingsStatusConnectedWaiting =>
      'Conectado (Aguardando Pareamento)';

  @override
  String get settingsStatusDisconnected => 'Servidor Local Desconectado';

  @override
  String get settingsStatusPairedSubtitle =>
      'Operações comerciais autenticadas ativas.';

  @override
  String get settingsStatusWaitingSubtitle =>
      'Pareie este dispositivo com o servidor para habilitar operações.';

  @override
  String get settingsQrManualTitle => 'Ou conecte manualmente no celular:';

  @override
  String get settingsQrServerUrlLabel => 'URL do Servidor:';

  @override
  String get settingsQrFingerprintLabel =>
      'Fingerprint TLS (Impressão Digital):';

  @override
  String get settingsQrPinLabel => 'PIN de Pareamento:';

  @override
  String get settingsCopiedToClipboard =>
      'Copiado para a área de transferência!';

  @override
  String get settingsFingerprintExplanation =>
      'O Fingerprint TLS é o código de segurança criptográfico gerado pelo servidor para garantir que seu celular está conectando diretamente no seu computador com HTTPS confiável.';

  @override
  String get settingsNetworkSectionDescWindows =>
      'Endereço local onde o servidor está operando neste computador.';

  @override
  String get settingsNetworkSectionDescAndroid =>
      'Endereço do servidor e certificado seguro para comunicação em rede local.';

  @override
  String get pairingCameraInitializeHint =>
      'Toque no botão abaixo para inicializar a captura da câmera:';

  @override
  String get purchasePaymentConditionsHeader => 'Condições de Pagamento';

  @override
  String get purchasePaymentStatusLabel => 'Situação do Pagamento';

  @override
  String get purchasePaymentStatusPaid => 'Pago / Liquidado';

  @override
  String get purchasePaymentStatusPending => 'Pendente / Em Aberto';

  @override
  String get purchasePaymentMethodLabel => 'Forma de Pagamento';

  @override
  String get purchasePaymentAmountDueLabel => 'Valor Devido / Total Financeiro';

  @override
  String get purchasePaymentDueDateLabel => 'Data de Vencimento';

  @override
  String get purchaseDueDateNotProvided => 'não informada';

  @override
  String get purchasePaymentDueDateRequired =>
      'A data de vencimento é obrigatória para compras pendentes.';

  @override
  String purchasePaymentPendingNotice(String date) {
    return 'Esta compra gerará uma obrigação em aberto no módulo de Contas a Pagar com vencimento em $date.';
  }

  @override
  String get purchasePaymentPaidNotice =>
      'O valor da compra será baixado imediatamente no livro-caixa da empresa.';

  @override
  String purchasePaymentDetailMethod(String method, String status) {
    return 'Pagamento: $method ($status)';
  }

  @override
  String purchasePaymentDetailDueDate(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get commonSelect => 'Selecionar';

  @override
  String get backupSectionTitle => 'Backup e Segurança do Banco de Dados';

  @override
  String get backupSectionDesc =>
      'Gere cópias de segurança consistentes e verificadas do banco de dados (SQLite) para prevenir perdas de dados comerciais.';

  @override
  String get backupCreateButton => 'Gerar Backup Agora';

  @override
  String get backupCreating => 'Gerando e verificando backup...';

  @override
  String backupSuccessMsg(String filename) {
    return 'Backup gerado com sucesso: $filename';
  }

  @override
  String backupErrorMsg(String error) {
    return 'Falha ao gerar backup: $error';
  }

  @override
  String get backupListTitle => 'Backups Disponíveis no Servidor';

  @override
  String get backupEmptyList => 'Nenhum backup encontrado no servidor.';

  @override
  String get backupIntegrityOk => 'Integridade Verificada';

  @override
  String get backupRestoreButton => 'Restaurar';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar este backup?';

  @override
  String backupRestoreConfirmBody(String filename) {
    return 'O banco de dados atual será substituído por $filename. Tudo o que foi lançado depois deste backup será perdido. Um backup de segurança do estado atual será criado automaticamente antes da restauração.';
  }

  @override
  String get backupRestoreConfirmAction => 'Sim, restaurar';

  @override
  String get backupRestoreCancel => 'Cancelar';

  @override
  String backupRestoreSuccessMsg(String safety) {
    return 'Backup restaurado. Backup de segurança criado: $safety. Reinicie o aplicativo para recarregar os dados.';
  }

  @override
  String backupRestoreErrorMsg(String error) {
    return 'Falha ao restaurar backup: $error';
  }

  @override
  String get companyFinanceTitle => 'Recebimentos, pagamentos e resultado';

  @override
  String get companyFinancialReportTitle =>
      'Resultado, recebimentos e pagamentos';

  @override
  String get companyPaymentsScope =>
      'Valores confirmados no período selecionado, incluindo os estornos registrados nesse período.';

  @override
  String get companyReceived => 'Recebimentos confirmados';

  @override
  String get companyPaid => 'Pagamentos confirmados';

  @override
  String get companyPaymentDifference => 'Diferença entre recebido e pago';

  @override
  String get companyDifferenceExplanation =>
      'Compara os movimentos do período. Não representa saldo bancário nem lucro.';

  @override
  String get companyResultTitle => 'Resultado das vendas no período';

  @override
  String get companyResultExplanation =>
      'As vendas a prazo entram no valor vendido, mesmo antes do recebimento. As outras despesas são consideradas quando pagas.';

  @override
  String get companySalesRevenue => 'Valor das vendas';

  @override
  String get companySoldCost => 'Custo das cestas vendidas';

  @override
  String get companyGrossProfit => 'Lucro bruto das vendas';

  @override
  String get companyOperatingExpenses => 'Outras despesas do negócio pagas';

  @override
  String get companyOperatingResult => 'Resultado gerencial do período';

  @override
  String get companyCostExplanation =>
      'O custo dos insumos vendidos já está no custo das cestas. As compras de estoque não são descontadas novamente do lucro bruto. Retiradas pessoais são mostradas separadamente.';

  @override
  String get companyPendingTitle => 'Contas ainda pendentes';

  @override
  String get companyPendingScope =>
      'Totais atuais de todas as contas em aberto. Os vencimentos no período aparecem abaixo.';

  @override
  String get companyPendingReceivable => 'Total pendente a receber';

  @override
  String get companyPendingPayable => 'Total pendente a pagar';

  @override
  String get companyReceivableDueInPeriod =>
      'A receber com vencimento no período';

  @override
  String get companyPayableDueInPeriod => 'A pagar com vencimento no período';

  @override
  String get companyReceivedDetails => 'Recebimentos confirmados no período';

  @override
  String get companyPaidDetails => 'Pagamentos confirmados no período';

  @override
  String get companyNoPayments => 'Nenhum registro confirmado neste período.';

  @override
  String get companyPaidStatus => 'Recebida';

  @override
  String get companyPartialStatus => 'Recebida parcialmente';

  @override
  String get companyPendingStatus => 'A receber';

  @override
  String get companyStockAvailable => 'Disponível';

  @override
  String companyMissingCost(int count) {
    return 'Há $count venda(s) com custo incompleto. O resultado gerencial precisa ser conferido.';
  }

  @override
  String companyStockPaid(String value) {
    return 'Compras de estoque pagas: $value';
  }

  @override
  String companyWithdrawalsPaid(String value) {
    return 'Retiradas pessoais pagas: $value';
  }

  @override
  String companyOverdueAmount(String value) {
    return 'Vencido: $value';
  }

  @override
  String companyPaymentDescription(String method, String date) {
    return '$method · $date';
  }

  @override
  String get companyPurchasesTitle => 'Compras registradas no período';

  @override
  String companyPurchaseCount(int count) {
    return '$count compra(s) confirmada(s)';
  }

  @override
  String get companyPurchasesExplanation =>
      'Inclui compras pagas e a prazo. Os pagamentos confirmados aparecem separadamente no financeiro.';

  @override
  String get productDeleteButton => 'Excluir produto';

  @override
  String get productDeleteTitle => 'Excluir produto do catálogo';

  @override
  String productDeleteConfirm(String name) {
    return 'Excluir “$name” do catálogo? Registros de operações anteriores serão preservados.';
  }

  @override
  String get productDeletedSuccess => 'Produto excluído do catálogo.';

  @override
  String get productDeleteBlockedTitle =>
      'Resolva estes vínculos antes de excluir';

  @override
  String productDeleteBlocked(String name, String reasons) {
    return '\"$name\" não pode ser excluído definitivamente porque possui registros em:\n\n$reasons\n\nPara deixar de utilizá-lo, você pode inativar o cadastro. Se ele estiver em uma receita ativa, retire-o dessa composição antes de inativar.';
  }

  @override
  String get productDeleteHistoryError =>
      'Resolva os vínculos indicados antes de excluir este produto.';

  @override
  String get productUsageRecipes =>
      '• Receitas de cestas, incluindo versões anteriores';

  @override
  String get productUsagePurchases =>
      '• Compras, incluindo rascunhos e compras canceladas';

  @override
  String get productUsageProduction =>
      '• Montagens ou composições já registradas';

  @override
  String get productUsageMovements =>
      '• Movimentações de estoque, mesmo com estoque zerado';

  @override
  String get productUsageHistory => '• Outros registros anteriores';

  @override
  String get packagingHelpExplanation =>
      'A embalagem comercial é a forma como você compra este produto: pacote, saco, fardo, caixa ou unidade. Ela informa quanto uma embalagem acrescenta ao estoque. Não é a embalagem vazia usada para montar a cesta.\n\nExemplo: se o arroz é controlado em gramas, um saco de 5 kg contém 5.000 g. Ao comprar 3 sacos, entram 15.000 g no estoque. Sem uma embalagem cadastrada, a compra é informada diretamente na unidade-base do produto.';

  @override
  String packagingContentHelp(String unit) {
    return 'Informe o conteúdo de uma única embalagem na unidade-base $unit. Exemplos: caixa com 12 unidades = 12 UNIT; saco de 5 kg = 5.000 G; frasco de 500 ml = 500 ML. Use o exemplo que corresponde à unidade deste produto.';
  }

  @override
  String get purchasePackagingHelpTitle => 'Como informar quantidade e preço?';

  @override
  String get purchasePackagingHelpExplanation =>
      'Escolha a forma como comprou o produto. A quantidade indica quantas embalagens você comprou, e o preço é o valor de uma delas.\n\nExemplo: 3 sacos de arroz de 5 kg a R\$ 25 por saco = 15 kg no estoque e R\$ 75 na compra. Caixa com 12 unidades: 2 caixas = 24 unidades.\n\nSe escolher \"Sem embalagem\", informe a quantidade e o preço na unidade-base exibida. Para comprar por kg ou litro com preço por kg/litro, cadastre essa forma de compra antes: 1 kg = 1.000 g; 1 litro = 1.000 ml.';

  @override
  String get purchaseQuantityPackages => 'Quantidade de embalagens';

  @override
  String purchaseQuantityBaseUnits(String unit) {
    return 'Quantidade em $unit';
  }

  @override
  String get purchasePricePerPackage => 'Preço de uma embalagem (R\$)';

  @override
  String purchasePricePerBaseUnit(String unit) {
    return 'Preço por $unit (R\$)';
  }

  @override
  String get purchasePackageCountHelp =>
      'Ex.: para 3 sacos ou 3 caixas, informe 3.';

  @override
  String get purchaseBaseCountHelp =>
      'Quantidade diretamente na unidade-base exibida.';

  @override
  String get purchasePackagePriceHelp =>
      'Valor de um saco, pacote ou caixa da forma de compra escolhida.';

  @override
  String get purchaseBasePriceHelp =>
      'Preço de uma única unidade-base. Para preço por kg/litro, cadastre a forma de compra.';

  @override
  String purchasePackagingContents(String name, String quantity) {
    return 'Cada \"$name\" acrescenta $quantity ao estoque.';
  }

  @override
  String get settingsHttpsUrlRequired =>
      'Informe uma URL HTTPS válida do servidor, sem usuário ou senha no endereço.';

  @override
  String get settingsTokenEntryHelp =>
      'Opcional: cole um token já emitido pelo servidor. Deixe vazio para manter a autenticação atual ou autenticar automaticamente no servidor deste computador (localhost).';

  @override
  String get settingsSaveAuthenticate => 'Salvar e autenticar este computador';

  @override
  String get settingsPairComputer => 'Parear este computador por PIN';

  @override
  String get settingsAuthenticatedSuccess =>
      'Computador autenticado no servidor.';

  @override
  String get settingsSavedNeedsAuthentication =>
      'Configurações salvas. O servidor ainda não confirmou a autenticação. Confira a conexão, informe um token válido ou faça o pareamento por PIN.';

  @override
  String get newDatabaseTitle => 'Criar e usar um novo banco';

  @override
  String get newDatabaseCreating => 'Criando e ativando o novo banco...';

  @override
  String get newDatabaseHelp =>
      'Gera um backup verificado do banco atual e começa com um banco vazio. Os pareamentos dos dispositivos são mantidos.';

  @override
  String get newDatabaseConfirmationBody =>
      'Esta ação troca o banco usado por toda a empresa, incluindo computadores, celulares e tablets. Produtos, receitas, clientes, compras, vendas, estoque e contas começarão vazios. Um backup obrigatório do banco atual será criado e verificado antes da troca. Os dispositivos continuam pareados. Para recuperar os dados anteriores, use Restaurar no backup de segurança. Para confirmar, digite NOVO BANCO.';

  @override
  String get newDatabaseConfirmationLabel => 'Digite NOVO BANCO';

  @override
  String get newDatabaseConfirmAction => 'Gerar backup e ativar banco novo';

  @override
  String newDatabaseSuccess(String filename) {
    return 'Novo banco ativado. Backup anterior: $filename. Recarregue as páginas nos demais dispositivos.';
  }

  @override
  String get newDatabaseFailed =>
      'Não foi possível concluir a criação do banco. Confira a conexão e tente novamente; a mesma operação será retomada com segurança.';

  @override
  String get newDatabaseAlreadyProcessed =>
      'Esta solicitação já foi concluída anteriormente. O banco atual foi mantido. Para criar outro banco, inicie uma nova solicitação.';

  @override
  String get payableFiltersTitle => 'Filtros';

  @override
  String get payableCreateShort => 'Criar conta a pagar';

  @override
  String get payableOpenShort => 'A pagar';

  @override
  String get payableDisplayedSummary => 'Resumo das contas exibidas';

  @override
  String get payableSearch => 'Buscar favorecido';

  @override
  String get saleCancelAssemblyHelp =>
      'Informe o que aconteceu fisicamente com cada item montado nesta venda. Cestas vendidas de estoque pronto voltam como cestas prontas.';

  @override
  String get saleCancelAssemblyQuestion => 'Situação da montagem';

  @override
  String get saleCancelKeepBaskets => 'As cestas continuam montadas';

  @override
  String get saleCancelReturnIngredients => 'A montagem não aconteceu';

  @override
  String get saleCancelAssemblyRequired =>
      'Informe a situação de todas as montagens antes de cancelar.';

  @override
  String get saleAssemblyStockHelp =>
      'Usa cestas já montadas e desconta do estoque de cestas prontas.';

  @override
  String get saleAssemblyDemandHelp =>
      'Consome os produtos da composição e registra a montagem ao confirmar a venda.';

  @override
  String get saleStockSelectBasket =>
      'Selecione uma cesta para consultar o saldo.';

  @override
  String get saleStockLoading => 'Consultando saldo…';

  @override
  String get saleStockQueryFailed =>
      'Não foi possível consultar o saldo. Tente novamente.';

  @override
  String get basketTypeFormNoStockSubtitle =>
      'As cestas são montadas na venda, com baixa dos produtos da composição.';

  @override
  String get saleAssemblyAutomatic => 'Montar na venda';

  @override
  String get basketStockDisabledError =>
      'Esta cesta está configurada para montagem na venda. Para usar cestas prontas, ative Estoque de cestas prontas no cadastro.';

  @override
  String get basketStockRemainsError =>
      'Ainda existem cestas prontas deste tipo em estoque. Resolva esse saldo antes de desativar a opção.';

  @override
  String get assemblyRegister => 'Registrar montagem';

  @override
  String get assemblyRegisterHelp =>
      'Informe a quantidade e quando as cestas foram fabricadas. Revise a composição antes de confirmar: os produtos serão consumidos e as cestas prontas entrarão no estoque.';

  @override
  String get assemblyHistory => 'Montagens';

  @override
  String assemblyHistoryTitle(String name) {
    return 'Montagens — $name';
  }

  @override
  String assemblyStandardStock(int qty) {
    return 'Cestas padrão prontas: $qty';
  }

  @override
  String get assemblyOccurredAt => 'Data e horário da fabricação';

  @override
  String get assemblyReview => 'Revisar montagem';

  @override
  String get assemblyConfirm => 'Confirmar montagem';

  @override
  String get assemblyRetry => 'Retomar confirmação';

  @override
  String get assemblySaved => 'Montagem registrada e estoque atualizado.';

  @override
  String get assemblyComposition => 'Produtos a consumir';

  @override
  String assemblyEstimatedCost(String value) {
    return 'Custo total estimado: $value';
  }

  @override
  String assemblyRecordedCost(String value) {
    return 'Custo total registrado: $value';
  }

  @override
  String assemblyRequiredAvailable(String required, String available) {
    return 'Necessário: $required · Disponível: $available';
  }

  @override
  String assemblyMissing(String qty) {
    return 'Faltam: $qty';
  }

  @override
  String get assemblyInsufficientHelp =>
      'Faltam produtos para esta montagem. Reponha o estoque ou altere a quantidade e revise novamente.';

  @override
  String get assemblyPendingHelp =>
      'Existe uma montagem aguardando confirmação do servidor. Retome a mesma solicitação para verificar o resultado sem registrar as cestas novamente.';

  @override
  String get assemblyRecipeChanged =>
      'A receita mudou desde a revisão. Confira a composição novamente antes de confirmar.';

  @override
  String get assemblyInactiveHelp =>
      'Este tipo de cesta está inativo. O histórico continua disponível.';

  @override
  String get assemblyNoStockHelp =>
      'Este tipo está configurado para montar na venda. Ative Estoque de cestas prontas no cadastro para registrar fabricação antecipada.';

  @override
  String get assemblyNoRecipeHelp =>
      'Cadastre uma receita ativa antes de registrar a montagem.';

  @override
  String get assemblyHistoryHelp =>
      'Inclui montagens antecipadas e realizadas na venda. A quantidade fabricada é histórica; não representa o saldo atual de cada lote.';

  @override
  String get assemblyHistoryEmpty =>
      'Nenhuma montagem registrada para este tipo de cesta.';

  @override
  String get assemblyOriginSale => 'Montada na venda';

  @override
  String get assemblyOriginAdvance => 'Montagem antecipada';

  @override
  String get assemblyRecorded => 'Montagem registrada';

  @override
  String get assemblyUndone => 'Montagem desfeita';

  @override
  String get assemblyCustom => 'Composição personalizada';

  @override
  String assemblyBatch(int number, int qty) {
    return 'Montagem #$number · $qty cestas';
  }

  @override
  String assemblyPage(int page, int total) {
    return 'Página $page de $total';
  }

  @override
  String get assemblyPreviousPage => 'Página anterior';

  @override
  String get assemblyNextPage => 'Próxima página';

  @override
  String get assemblyCustomize => 'Personalizar esta montagem';

  @override
  String get assemblyCustomizeHelp =>
      'Altere os produtos destas cestas sem mudar a receita cadastrada.';

  @override
  String get assemblyCustomDescription =>
      'Identificação da montagem personalizada';

  @override
  String get assemblyCustomDescriptionRequired =>
      'Informe uma identificação para diferenciar estas cestas.';

  @override
  String get assemblyCustomItemsHelp =>
      'Composição por cesta. Todas as cestas desta montagem terão os mesmos produtos e quantidades.';

  @override
  String get assemblyProduct => 'Produto';

  @override
  String get assemblyQuantityPerBasket => 'Quantidade por cesta';

  @override
  String get assemblyBaseUnitsHelp =>
      'Use números inteiros na unidade indicada: G = gramas, ML = mililitros e UN = unidades. Ao trocar o produto, informe a quantidade novamente.';

  @override
  String get assemblyAddProduct => 'Adicionar produto';

  @override
  String get assemblyRemoveProduct => 'Remover produto';

  @override
  String get assemblyCustomItemsRequired =>
      'Inclua ao menos um produto na montagem personalizada.';

  @override
  String get assemblyCustomizationDisabled =>
      'Este tipo de cesta não permite personalização. Confira seu cadastro.';

  @override
  String assemblyCustomStock(int quantity) {
    return 'Prontas desta montagem: $quantity';
  }

  @override
  String get basketDeleteButton => 'Excluir cesta';

  @override
  String get basketDeleteBlockedTitle => 'Cesta ainda em uso';

  @override
  String get basketDeleteBlockedHelp =>
      'A cesta tem vendas não canceladas, estoque ou operações pendentes. Confira esses registros antes de tentar excluir novamente.';

  @override
  String get basketDeleteActiveSales =>
      'Há venda não cancelada com esta cesta. Cancele a operação incorreta antes de excluir o cadastro.';

  @override
  String get basketDeleteStockRemains =>
      'Ainda há cestas em estoque. Cancelar uma venda pode devolver cestas prontas; confira o destino físico antes de excluir o cadastro.';

  @override
  String get basketDeleteActiveDispatches =>
      'Há uma saída/conferência ainda aberta vinculada a esta cesta.';

  @override
  String basketDeleteUnusedConfirm(String name) {
    return 'Excluir definitivamente “$name” e suas receitas nunca utilizadas? Os produtos da receita serão preservados.';
  }

  @override
  String basketDeleteCatalogConfirm(String name) {
    return 'Excluir “$name” do catálogo? A cesta deixará de aparecer na lista e nas novas operações. Seu cadastro e suas receitas permanecerão no banco para preservar vendas canceladas, montagens e movimentações. Essa ação não apaga o histórico.';
  }

  @override
  String get basketDeletedPermanently =>
      'Cesta nunca utilizada excluída definitivamente.';

  @override
  String get basketRemovedFromCatalog =>
      'Cesta excluída do catálogo. Histórico preservado.';

  @override
  String get basketRemovedError =>
      'Esta cesta foi excluída do catálogo e permanece somente no histórico.';

  @override
  String get formDocumentType => 'Documento';

  @override
  String get formSelectColumns => 'Campos do documento';

  @override
  String get formColumnsHelp =>
      'Marque as colunas que devem aparecer no PDF e na planilha. Mantenha pelo menos uma.';

  @override
  String get formAllColumns => 'Selecionar todas';

  @override
  String get printerDialogTitle => 'Impressão e impressoras';

  @override
  String get printerSettingsEntryHelp =>
      'Configurar a impressão e testar uma página A4, mesmo sem conexão com o servidor.';

  @override
  String get printerAndroidDiscovery =>
      'No Android, a procura e a seleção da impressora acontecem na janela de impressão do sistema, usando os serviços ativados no celular.';

  @override
  String get printerDesktopDiscovery =>
      'Use a janela de impressão do sistema ou uma impressora cadastrada abaixo. Impressoras de rede precisam estar instaladas no computador.';

  @override
  String get printerSystemPrint => 'Procurar impressora e imprimir';

  @override
  String get printerTestAction => 'Imprimir página de teste A4';

  @override
  String get printerOpenSettings => 'Configurar impressão no Android';

  @override
  String get printerSettingsHelp =>
      'Ative um serviço de impressão compatível nas configurações. Ao voltar ao app, tente imprimir novamente.';

  @override
  String get printerSettingsUnavailable =>
      'Não foi possível abrir as configurações. Procure Impressão nas configurações do Android.';

  @override
  String get printerInstalledTitle => 'Impressoras cadastradas no sistema';

  @override
  String get printerNoInstalled =>
      'Nenhuma impressora cadastrada foi retornada. Instale a impressora nas configurações do computador e atualize esta lista.';

  @override
  String get printerNotAvailable => 'Indisponível segundo o sistema';

  @override
  String get printerDiscoveryError =>
      'Não foi possível consultar as impressoras. Você ainda pode tentar a janela de impressão do sistema ou atualizar a consulta.';

  @override
  String get printerUnsupported =>
      'O serviço de impressão não está disponível neste dispositivo. Você pode salvar o PDF e imprimir em outro dispositivo.';

  @override
  String get printerWaiting =>
      'Aguardando retorno do sistema de impressão. Você pode fechar esta janela; acompanhe também a fila de impressão do sistema.';

  @override
  String get printerJobBusy =>
      'Já existe uma impressão em andamento nesta tela. Acompanhe a fila do sistema antes de tentar novamente.';

  @override
  String get printerJobSubmitted =>
      'O sistema retornou a conclusão do trabalho. Confira se a folha saiu corretamente; o app não verifica papel ou tinta.';

  @override
  String get printerJobCanceled => 'Impressão cancelada.';

  @override
  String get printerJobError =>
      'Não foi possível concluir a impressão. Confira a conexão, a impressora e a fila do sistema. Você também pode salvar o PDF.';

  @override
  String get printerPreviewError =>
      'Não foi possível carregar a prévia deste PDF. Tente gerar o documento novamente.';

  @override
  String get printerHelpTitle => 'A impressora não apareceu?';

  @override
  String get printerHelpNetwork =>
      'Confira se a impressora está ligada e acessível na mesma rede local do dispositivo. Redes de visitantes, isolamento entre aparelhos e VPN podem impedir a descoberta.';

  @override
  String get printerHelpAndroid =>
      'No Android, ative o serviço padrão de impressão, Mopria ou um serviço do fabricante compatível com o modelo. A busca de impressoras é feita por esse serviço na janela do sistema.';

  @override
  String get printerHelpWindows =>
      'No Windows, adicione a impressora em Configurações > Impressoras e scanners e confira o driver do modelo. Depois atualize esta lista.';

  @override
  String get printerHelpIp =>
      'Se a busca automática falhar, verifique se o serviço de impressão ou as configurações do sistema permitem adicionar a impressora pelo endereço IP.';

  @override
  String get printerHelpDirect =>
      'Wi-Fi Direct depende do suporte do celular e da impressora. Essa conexão pode interromper o acesso ao servidor da loja; carregue o documento antes de mudar de rede.';

  @override
  String get printerHelpQueue =>
      'Se houver trabalho bloqueado, confira papel, tinta, estado da impressora e fila de impressão. Evite reenviar sem verificar a fila para não duplicar folhas.';

  @override
  String get printerCompatibility =>
      'Ter Wi-Fi não garante compatibilidade. O modelo precisa ser atendido pelo serviço de impressão do Android ou pelo driver do Windows.';

  @override
  String get printerTestTitle => 'Página de teste de impressão A4';

  @override
  String get printerTestInstructions =>
      'Selecione papel A4 e escala de 100% quando disponível. Confira texto, bordas, proporções e alinhamento nesta folha antes de imprimir documentos da loja.';

  @override
  String get printerTestCharacters =>
      'Teste de acentos: ação, quitação, descrição, café, açúcar.';

  @override
  String get printerTestScale =>
      'A referência abaixo deve medir 100 mm de largura e 20 mm de altura, sem redimensionamento.';

  @override
  String printerTestLine(int height) {
    return 'Espaço para escrita: $height mm';
  }

  @override
  String get printerTestFooter =>
      'Documento de teste sem dados comerciais. Confira também orientação, escala e margens nas configurações da impressora.';

  @override
  String get formColumnOrder => 'Ordem das colunas';

  @override
  String get formColumnOrderHelp =>
      'Use as setas para mover os campos. A lista de cima para baixo define a ordem da esquerda para a direita no PDF e no XLSX.';

  @override
  String get formColumnMoveUp => 'Mover para cima';

  @override
  String get formColumnMoveDown => 'Mover para baixo';

  @override
  String get formColumnOrderReset => 'Restaurar ordem padrão';

  @override
  String get formPrintSettings => 'Configuração da impressão';

  @override
  String get formOrientation => 'Orientação da folha';

  @override
  String get formOrientationAuto => 'Automática';

  @override
  String get formPortrait => 'Vertical (retrato)';

  @override
  String get formLandscape => 'Horizontal (paisagem)';

  @override
  String get formRowHeight => 'Altura mínima da linha (mm)';

  @override
  String get formFontSize => 'Tamanho da fonte (pt)';

  @override
  String get formPageMargins => 'Margens da folha (mm)';

  @override
  String get formMarginTop => 'Superior (mm)';

  @override
  String get formMarginBottom => 'Inferior (mm)';

  @override
  String get formMarginLeft => 'Esquerda (mm)';

  @override
  String get formMarginRight => 'Direita (mm)';

  @override
  String get formMarginHelp =>
      'O padrão usa 15 mm. Margens menores dependem da área imprimível da sua impressora. Confira a prévia.';

  @override
  String get formAutoRows => 'Ajustar linhas em branco para uma página';

  @override
  String get formBlankRows => 'Total de linhas em branco';

  @override
  String get formShowSignatures => 'Incluir espaços de assinatura no rodapé';

  @override
  String get formColumnWidths => 'Ajustar larguras das colunas';

  @override
  String get formColumnWidthHelp =>
      'Larguras proporcionais: um valor maior reserva mais espaço para a coluna dentro da folha.';

  @override
  String get formResetDefaults => 'Restaurar padrão automático';

  @override
  String get formNoRecords => 'Nenhum registro encontrado para este documento.';

  @override
  String get formPaperOnly =>
      'Anotações no papel e alterações na planilha não atualizam os pagamentos ou o estoque do sistema.';

  @override
  String get formPreparing => 'Calculando páginas do documento…';

  @override
  String get formSavePdf => 'Salvar PDF';

  @override
  String get formSaveXlsx => 'Salvar planilha XLSX';

  @override
  String get formPreview => 'Prévia do documento';

  @override
  String get formInvalidNumber => 'Informe um número dentro do intervalo.';

  @override
  String get formFileSaved => 'Arquivo salvo no local escolhido.';

  @override
  String get formExportFailure =>
      'Não foi possível gerar ou salvar o documento. Confira as opções e tente novamente.';

  @override
  String get formPaymentsHelp =>
      'Conferência de fiados: valor original, total recebido, data do pagamento e saldo restante.';

  @override
  String get formPayablesHelp =>
      'Conferência de obrigações e pagamentos, com valor pago e saldo em colunas próprias.';

  @override
  String get formInventoryHelp =>
      'Contagem de produtos e cestas da loja, com espaços para quantidade física, diferença e conferência.';

  @override
  String formDocumentSummary(int columns, int rows, int pages) {
    return '$columns colunas · $rows linhas · $pages página(s) no PDF';
  }

  @override
  String get paymentFlowDetail => 'Conta a pagar';

  @override
  String get paymentFlowRegister => 'Registrar pagamento';

  @override
  String get paymentFlowBalance => 'Saldo em aberto';

  @override
  String paymentFlowTitleRef(int number) {
    return 'Conta #$number';
  }

  @override
  String get paymentFlowSituation => 'Situação';

  @override
  String get paymentFlowNoHistory => 'Nenhum pagamento registrado nesta conta.';

  @override
  String get paymentFlowNotOpen => 'Esta conta não está aberta para pagamento.';

  @override
  String get paymentFlowReversed => 'Estornado';

  @override
  String get paymentFlowKind => 'Tipo de pagamento';

  @override
  String get paymentFlowFull => 'Integral';

  @override
  String get paymentFlowPartial => 'Parcial';

  @override
  String get paymentFlowAmount => 'Quanto você pagou?';

  @override
  String paymentFlowAmountLimit(String amount) {
    return 'Informe um valor entre R\$ 0,01 e $amount.';
  }

  @override
  String get paymentFlowDate => 'Data do pagamento';

  @override
  String get paymentFlowMethod => 'Como você pagou?';

  @override
  String get paymentFlowSelectMethod => 'Selecione a forma de pagamento';

  @override
  String get paymentFlowRemaining => 'Restará em aberto após este registro';

  @override
  String get paymentFlowReview => 'Revisar pagamento';

  @override
  String get paymentFlowSending => 'Registrando…';

  @override
  String get paymentFlowRecordedOnly =>
      'Registre um pagamento que você já realizou. A confirmação lança o registro no aplicativo.';

  @override
  String get paymentFlowBalanceChanged =>
      'O saldo mudou. Confira o valor atualizado e revise novamente.';

  @override
  String get paymentFlowUncertain => 'Esta tentativa aguarda confirmação.';

  @override
  String get paymentFlowResumeHelp =>
      'Retomar usa os mesmos dados e pode concluir o pagamento original. Aguarde a confirmação desta tentativa antes de criar outro registro.';

  @override
  String get paymentFlowResume => 'Retomar registro';

  @override
  String get paymentFlowConfirmed => 'Pagamento registrado';

  @override
  String get paymentFlowReference => 'Referência do registro';

  @override
  String get paymentFlowRefreshing =>
      'Pagamento registrado. Atualizando a conta…';

  @override
  String get paymentFlowConfirmedRefreshFailed =>
      'O pagamento está registrado. Falta atualizar a consulta da conta.';

  @override
  String get paymentFlowCurrentBalance => 'Saldo atual consultado';

  @override
  String get paymentFlowFinish => 'Voltar às contas';

  @override
  String get paymentFlowUnexpected =>
      'Não foi possível concluir esta etapa. Tente atualizar a consulta.';

  @override
  String get paymentFlowLocalStorage =>
      'Não foi possível conservar os dados da tentativa neste aparelho. Atualize antes de continuar.';

  @override
  String get paymentFlowConnectionChanged =>
      'A conexão foi alterada. Para retomar este registro, volte à conexão original.';

  @override
  String get paymentFlowInvalidConfirmation =>
      'A resposta não permitiu confirmar o registro. Retome a mesma tentativa.';

  @override
  String get paymentFlowServerUpdate =>
      'Atualize o servidor para usar o pagamento com revisão e recuperação.';

  @override
  String get paymentFlowPendingTitle => 'Registros para acompanhar';

  @override
  String paymentFlowPendingItem(String beneficiary, int number) {
    return '$beneficiary · conta #$number';
  }

  @override
  String get paymentFlowPendingReadError =>
      'Não foi possível consultar os registros pendentes deste aparelho.';

  @override
  String get paymentFlowMore => 'Carregar mais contas';

  @override
  String get paymentFlowMoreFailed =>
      'Não foi possível carregar as próximas contas.';

  @override
  String get paymentFlowValue => 'Valor deste registro';

  @override
  String get paymentFlowRecordedRemaining => 'Saldo após este registro';

  @override
  String get receiptFlowDetail => 'Conta a receber';

  @override
  String get receiptFlowRegister => 'Registrar recebimento';

  @override
  String get receiptFlowReview => 'Revisar recebimento';

  @override
  String get receiptFlowConfirmed => 'Recebimento registrado';

  @override
  String get receiptFlowNoHistory =>
      'Nenhum recebimento registrado nesta conta.';

  @override
  String get receiptFlowNotOpen =>
      'Esta conta não está aberta para recebimento.';

  @override
  String get receiptFlowKind => 'Tipo de recebimento';

  @override
  String get receiptFlowAmount => 'Quanto você recebeu?';

  @override
  String get receiptFlowDate => 'Data do recebimento';

  @override
  String get receiptFlowMethod => 'Como você recebeu?';

  @override
  String get receiptFlowSelectMethod => 'Selecione a forma de recebimento';

  @override
  String get receiptFlowRecordedOnly =>
      'Registre um valor que você já recebeu. A confirmação lança o registro no aplicativo.';

  @override
  String get receiptFlowResumeHelp =>
      'Retomar usa os mesmos dados e pode concluir o recebimento original. Aguarde a confirmação desta tentativa antes de criar outro registro.';

  @override
  String get receiptFlowRefreshing =>
      'Recebimento registrado. Atualizando a conta…';

  @override
  String get receiptFlowConfirmedRefreshFailed =>
      'O recebimento está registrado. Falta atualizar a consulta da conta.';

  @override
  String get receiptFlowServerUpdate =>
      'Atualize o servidor para usar o recebimento com revisão e recuperação.';

  @override
  String get receiptFlowCash => 'Dinheiro';

  @override
  String get receiptFlowReceived => 'Já recebido';

  @override
  String receiptFlowSaleRef(int number) {
    return 'Venda #$number';
  }

  @override
  String receiptFlowPendingItem(String customer, int number) {
    return '$customer · venda #$number';
  }

  @override
  String get receiptFlowOrigin => 'Ver venda de origem';

  @override
  String get receiptFlowOriginHelp =>
      'O recebimento reduz ou quita a dívida desta venda.';

  @override
  String get receiptFlowSaleTotal => 'Valor original da venda';

  @override
  String receiptFlowSaleItem(int quantity, String name) {
    return '$quantity × $name';
  }

  @override
  String receiptFlowBasketFallback(String id) {
    return 'Tipo de cesta $id';
  }

  @override
  String get receiptFlowOriginUnavailable =>
      'Não foi possível conferir a venda de origem. Atualize a consulta.';

  @override
  String get receiptFlowSummary => 'Resumo das contas exibidas';

  @override
  String get receiptFlowFilters => 'Filtros';

  @override
  String get receiptFlowFilterAll => 'Todas as situações';

  @override
  String get receiptFlowFilterOpen => 'Em aberto, incluindo parciais';

  @override
  String receiptFlowFilterScope(String status, String overdue) {
    return '$status · $overdue';
  }

  @override
  String get receiptFlowFilterAnyDue => 'Todos os vencimentos';

  @override
  String get receiptFlowFilterApplied => 'Filtros adicionais aplicados';

  @override
  String receiptFlowSaleDate(String date) {
    return 'Venda em $date';
  }

  @override
  String receiptFlowReversalReason(String reason) {
    return 'Motivo do estorno: $reason';
  }

  @override
  String get appBrand => 'ZM Cesta Básica';

  @override
  String get appOverview => 'Visão geral';

  @override
  String get appHome => 'Início';

  @override
  String get appFinance => 'Financeiro';

  @override
  String get appBusiness => 'Negócio';

  @override
  String get appInventory => 'Estoque';

  @override
  String get appMore => 'Mais';

  @override
  String get appDay => 'Dia';

  @override
  String get appWeek => 'Semana';

  @override
  String get appMonth => 'Mês';

  @override
  String get appTodayWhen => 'hoje';

  @override
  String get appWeekWhen => 'nesta semana';

  @override
  String get appMonthWhen => 'neste mês';

  @override
  String get appSummary => 'Resumo';

  @override
  String get appPay => 'A pagar';

  @override
  String get appReceive => 'A receber';

  @override
  String get appPayTab => 'Pagar';

  @override
  String get appReceiveTab => 'Receber';

  @override
  String get appFilter => 'Filtrar';

  @override
  String get appThisWeek => 'Nesta semana';

  @override
  String get appThisMonth => 'Neste mês';

  @override
  String get appDueToday => 'Vencem hoje';

  @override
  String get appOverdue => 'Vencidas';

  @override
  String get appNextThree => 'Próximos 3 dias';

  @override
  String get appAllOpen => 'Todas em aberto';

  @override
  String get appCurrentPosition => 'Posição atual';

  @override
  String appBeforeDate(String date) {
    return 'Vencidas · antes de $date';
  }

  @override
  String get appDueScope => 'Vencimento das contas';

  @override
  String get appBalancePay => 'Saldo a pagar';

  @override
  String get appBalanceReceive => 'Saldo a receber';

  @override
  String appOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas em aberto',
      one: '1 conta em aberto',
    );
    return '$_temp0';
  }

  @override
  String appPartialCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parciais',
      one: '1 parcial',
    );
    return '$_temp0';
  }

  @override
  String appOriginDue(String origin, String date) {
    return '$origin · Vence $date';
  }

  @override
  String get appPurchaseOrigin => 'Compra de produtos';

  @override
  String get appSaleOrigin => 'Venda de cestas';

  @override
  String get appPartial => 'Parcial';

  @override
  String get appOpen => 'Em aberto';

  @override
  String get appDueTodayShort => 'Vence hoje';

  @override
  String get appPaid => 'Pago';

  @override
  String get appReceived => 'Recebido';

  @override
  String appOriginalPaid(String original, String kind, String paid) {
    return 'Original $original · $kind $paid';
  }

  @override
  String get appFinanceContext => 'Pagar, receber e acompanhar vencimentos';

  @override
  String get appOpenInPeriod => 'Em aberto · vencimentos do período';

  @override
  String get appCurrentDeadlines => 'Vencimentos atuais';

  @override
  String appAccountAmount(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas',
      one: '1 conta',
    );
    return '$_temp0 · $amount';
  }

  @override
  String get appPendingNotBank =>
      'Pendências cadastradas não são saldo bancário. Próximos três dias são separados de hoje.';

  @override
  String get appOrganizeFinance => 'Organizar seu financeiro';

  @override
  String get appAccountsCards => 'Contas e cartões';

  @override
  String get appStatements => 'Extratos e faturas';

  @override
  String get appFutureFeature =>
      'Proposta futura. Esta função ainda não está disponível no aplicativo.';

  @override
  String get appAccounts => 'Contas';

  @override
  String appResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
    );
    return '$_temp0';
  }

  @override
  String get appNoOpenAccounts =>
      'Nenhuma conta em aberto neste recorte. Você pode consultar outros vencimentos.';

  @override
  String get appHistoryAndRecords => 'Histórico e cadastros';

  @override
  String appYourFinance(String when) {
    return 'Seu financeiro $when';
  }

  @override
  String appYourBusiness(String when) {
    return 'Seu negócio $when';
  }

  @override
  String get appOpenDueInPeriod => 'Em aberto · vencimentos do período';

  @override
  String get appOpenFinance => 'Abrir Financeiro';

  @override
  String get appBasketsSold => 'Cestas vendidas';

  @override
  String get appSalesValue => 'Valor das vendas';

  @override
  String get appAttention => 'Precisa da sua atenção';

  @override
  String get appNow => 'Agora';

  @override
  String appLateAccounts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contas atrasadas',
      one: '1 conta atrasada',
    );
    return '$_temp0';
  }

  @override
  String appTodayPay(String amount) {
    return 'Hoje: $amount a pagar';
  }

  @override
  String appTodayAmounts(String pay, String receive) {
    return 'Hoje: pagar $pay · receber $receive';
  }

  @override
  String get appNoLowStock => 'Nenhum produto abaixo do mínimo';

  @override
  String get appCheckInventory => 'Conferir produtos e reposição';

  @override
  String appLowStockProduct(String name) {
    return '$name abaixo do mínimo';
  }

  @override
  String appStockMinimum(String current, String minimum) {
    return '$current disponíveis · mínimo cadastrado $minimum';
  }

  @override
  String appBusinessContext(String range) {
    return 'Vendas, clientes e resultado · $range';
  }

  @override
  String appSalesWhen(String when) {
    return 'Vendas $when';
  }

  @override
  String appBasketsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cestas vendidas',
      one: '1 cesta vendida',
    );
    return '$_temp0';
  }

  @override
  String appBusinessResult(String range) {
    return 'Resultado do negócio · $range';
  }

  @override
  String get appResultExplanation =>
      'Vendas menos custos registrados e outras despesas pagas no período.';

  @override
  String appIncompleteCost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendas com custo incompleto',
      one: '1 venda com custo incompleto',
    );
    return '$_temp0';
  }

  @override
  String get appUnderstandResult => 'Entender o resultado';

  @override
  String appSaleRow(String amount) {
    return '$amount · Conferir itens, cliente e pagamento';
  }

  @override
  String get appSales => 'Vendas';

  @override
  String get appSalesDescription => 'Registrar e consultar vendas';

  @override
  String get appCustomers => 'Clientes';

  @override
  String get appCustomersDescription => 'Cadastros e histórico';

  @override
  String get appInventoryContext => 'Produtos, compras e cestas';

  @override
  String get appProducts => 'Produtos';

  @override
  String get appProductsDescription => 'Cadastros e posição de estoque';

  @override
  String get appPurchases => 'Compras';

  @override
  String get appPurchasesDescription => 'Entradas e fornecedores';

  @override
  String get appBasketsAssembly => 'Cestas e montagens';

  @override
  String get appBasketsDescription =>
      'Tipos, composição e histórico de montagem';

  @override
  String get appMovements => 'Movimentações';

  @override
  String get appMovementsDescription => 'O que entrou e saiu do estoque';

  @override
  String get appStockPosition => 'Posição do estoque';

  @override
  String get appMoreContext => 'Documentos e ferramentas do aplicativo';

  @override
  String get appReports => 'Relatórios';

  @override
  String get appReportsDescription => 'Consultar e exportar os dados';

  @override
  String get appPrinting => 'Impressão e formulários';

  @override
  String get appPrintingDescription => 'PDF e folhas para preencher à caneta';

  @override
  String get appSettingsConnection => 'Configurações e conexão';

  @override
  String get appSettingsDescription => 'Aparência, servidor e pareamento';

  @override
  String get appBackup => 'Backup';

  @override
  String get appBackupDescription => 'Cópias de segurança e recuperação';

  @override
  String get appConfirmedSales => 'Vendas confirmadas';

  @override
  String get appSoldCosts => 'Custos registrados nas vendas';

  @override
  String get appGrossProfit => 'Lucro bruto calculado';

  @override
  String get appPaidExpenses => 'Outras despesas pagas';

  @override
  String get appResult => 'Resultado do negócio';

  @override
  String get appResultHow => 'Como este valor é calculado';

  @override
  String get appResultNotBank =>
      'As vendas podem ainda não ter sido recebidas. Este resultado não representa saldo bancário.';

  @override
  String get appReviewType => 'Tipo';

  @override
  String get appReviewFull => 'Integral do saldo atual';

  @override
  String get appReviewNoNote => 'Não informada';

  @override
  String get appReviewExpectedBalance => 'Saldo esperado após o registro';

  @override
  String get appReviewHelp =>
      'O saldo esperado será confirmado depois do registro.';

  @override
  String get appAppearance => 'Aparência';

  @override
  String get appAppearanceDescription => 'Tema, cores e acessibilidade';

  @override
  String get appAppearanceContext => 'Preferências de aparência neste aparelho';

  @override
  String get appFollowDevice => 'Seguir o aparelho';

  @override
  String get appLight => 'Claro';

  @override
  String get appDark => 'Escuro';

  @override
  String get appAccent => 'Cor de destaque';

  @override
  String get appChooseColor => 'Escolher cor';

  @override
  String get appAccentHelp =>
      'Azul original por padrão. A cor é ajustada para manter a leitura.';

  @override
  String get appColorRed => 'Vermelho';

  @override
  String get appColorGreen => 'Verde';

  @override
  String get appColorBlue => 'Azul';

  @override
  String get appBackground => 'Fundo';

  @override
  String get appSoftBackground => 'Superfície suave';

  @override
  String get appPureBackground => 'Branco / preto';

  @override
  String get appAppearanceSaveError =>
      'Não foi possível salvar a preferência. Tente novamente.';

  @override
  String get appServerConnection => 'Conexão com o servidor';

  @override
  String get appServerDescription => 'Disponibilidade e pareamento';

  @override
  String appRangeSameMonth(String first, String last, String month) {
    return '$first a $last de $month';
  }

  @override
  String appRangeDifferentMonth(String first, String last) {
    return '$first a $last';
  }

  @override
  String get pdfImportTitle => 'Extratos e faturas';

  @override
  String get pdfImportEntry => 'Importar PDF e conferir documentos';

  @override
  String get pdfImportAction => 'Importar PDF';

  @override
  String get pdfImportChoose => 'Selecionar PDF';

  @override
  String get pdfImportRead => 'Ler documento';

  @override
  String get pdfImportHelp =>
      'Selecione um PDF ou CSV de até 10 MiB. O aplicativo lê os dados disponíveis e avisa se precisar de alguma informação. PDFs que são fotos ou imagens ainda não podem ser lidos automaticamente.';

  @override
  String get pdfImportEffect =>
      'O arquivo fica disponível para consulta. Para uma fatura aparecer no financeiro, escolha Adicionar a Contas a Pagar e salve. O pagamento é registrado separadamente.';

  @override
  String get pdfImportSource => 'Conta ou cartão do documento';

  @override
  String get pdfImportSourceCheck =>
      'Escolha a conta ou cartão de onde saiu o documento. Confira essa escolha antes de salvar a fatura.';

  @override
  String get pdfImportNewSource => 'Cadastrar conta ou cartão';

  @override
  String get pdfImportSourceName => 'Nome para identificar a conta ou cartão';

  @override
  String get pdfImportInstitution => 'Instituição financeira';

  @override
  String get pdfImportBank => 'Conta bancária';

  @override
  String get pdfImportCard => 'Cartão de crédito';

  @override
  String get pdfImportHolder => 'Titularidade';

  @override
  String get pdfImportPF => 'Pessoa física';

  @override
  String get pdfImportPJ => 'Pessoa jurídica';

  @override
  String get pdfImportBankLink => 'Vincular conta bancária cadastrada';

  @override
  String get pdfImportNewBank => 'Criar cadastro bancário para esta origem';

  @override
  String get pdfImportBankHelp =>
      'O vínculo identifica a conta do extrato. Um novo cadastro é criado sem saldo de abertura e sem movimentação de dinheiro.';

  @override
  String get pdfImportNoSources =>
      'Cadastre a conta ou cartão antes de importar. Use um nome que permita distinguir banco e titularidade.';

  @override
  String get pdfImportHistory => 'Documentos enviados';

  @override
  String get pdfImportEmpty => 'Nenhum PDF enviado nesta consulta.';

  @override
  String get pdfImportMore => 'Carregar mais';

  @override
  String get pdfImportReady => 'Leitura concluída · conferir antes de guardar';

  @override
  String get pdfImportBlocked => 'Leitura bloqueada · confirmação indisponível';

  @override
  String get pdfImportConfirmed => 'Documento guardado · revisão pendente';

  @override
  String get pdfImportConfirm => 'Guardar para revisão';

  @override
  String get pdfImportAcknowledged =>
      'Conferi a origem, os dados extraídos e os avisos.';

  @override
  String get pdfImportSuccess =>
      'Documento guardado. Os lançamentos continuam pendentes de revisão, sem criar dívidas ou pagamentos.';

  @override
  String get pdfImportRetry => 'Consultar novamente';

  @override
  String get pdfImportBusy => 'Enviando e lendo o PDF…';

  @override
  String get pdfImportReading => 'Conferência do documento';

  @override
  String get pdfImportItems => 'Lançamentos extraídos';

  @override
  String get pdfImportPages => 'Texto das páginas';

  @override
  String get pdfImportOriginal => 'Visualizar PDF original';

  @override
  String get pdfImportOriginalTitle => 'Documento original';

  @override
  String get pdfImportWarnings => 'O que precisa de atenção';

  @override
  String get pdfImportControls => 'Conferências de totais do documento';

  @override
  String get pdfImportControlOk => 'Valores correspondentes';

  @override
  String get pdfImportControlFail => 'Valores divergentes';

  @override
  String pdfImportPage(int number) {
    return 'Página $number';
  }

  @override
  String pdfImportCounts(int items, int pages) {
    return '$items lançamentos · $pages páginas';
  }

  @override
  String pdfImportCoverage(int loaded, int total) {
    return 'Exibindo $loaded de $total lançamentos extraídos.';
  }

  @override
  String pdfImportInstallments(int current, int total) {
    return 'Parcela $current de $total';
  }

  @override
  String get pdfImportPartialYear =>
      'Algumas datas não trazem o ano. O leitor usou o ciclo da fatura para completá-las; confira no original.';

  @override
  String get pdfImportSignBank =>
      'Entradas positivas e saídas negativas, conforme o extrato.';

  @override
  String get pdfImportSignCard =>
      'Compras positivas e créditos/pagamentos negativos. Pagamento de fatura anterior não quita a atual.';

  @override
  String get pdfImportPeriodStart => 'Início do período';

  @override
  String get pdfImportPeriodEnd => 'Fim do período';

  @override
  String get pdfImportIssued => 'Emissão';

  @override
  String get pdfImportClosing => 'Fechamento';

  @override
  String get pdfImportDue => 'Vencimento';

  @override
  String get pdfImportTotal => 'Total declarado';

  @override
  String get pdfImportMinimum => 'Pagamento mínimo';

  @override
  String get pdfImportOpeningBalance => 'Saldo inicial declarado';

  @override
  String get pdfImportClosingBalance => 'Saldo final declarado';

  @override
  String get pdfImportInflows => 'Entradas declaradas';

  @override
  String get pdfImportOutflows => 'Saídas declaradas';

  @override
  String get pdfImportBillEquation => 'Composição do total da fatura';

  @override
  String get pdfImportDetailsCheck => 'Detalhes e resumo da fatura';

  @override
  String get pdfImportSectionCheck => 'Subtotal da seção';

  @override
  String get pdfImportBalanceCheck => 'Equação dos saldos';

  @override
  String get pdfImportInflowsCheck => 'Total de entradas';

  @override
  String get pdfImportOutflowsCheck => 'Total de saídas';

  @override
  String get pdfImportCandidate =>
      'Há registros semelhantes no sistema. Essa semelhança não comprova duplicidade; a revisão é separada.';

  @override
  String get pdfImportServerUpdate =>
      'O servidor precisa da atualização e da migração financeira antes de receber documentos. Solicite a preparação da instalação.';

  @override
  String get pdfImportRuntime =>
      'O leitor de PDF não está disponível nesta instalação do servidor. É necessário preparar o runtime antes de importar.';

  @override
  String get pdfImportProcessing =>
      'Não foi possível concluir a leitura agora. Tente novamente com o mesmo arquivo e a mesma origem.';

  @override
  String get pdfImportSize => 'Selecione um PDF não vazio, com até 10 MiB.';

  @override
  String get pdfImportInvalidFile =>
      'Não foi possível ler este PDF. Confira se o arquivo está íntegro e é um PDF válido.';

  @override
  String get pdfImportPassword =>
      'Informe ou confira a senha do PDF e tente novamente. A senha é usada somente durante a leitura.';

  @override
  String get pdfImportOcr =>
      'Há página sem texto extraível. A leitura de PDFs escaneados ainda não está disponível.';

  @override
  String get pdfImportUnsupported =>
      'O formato deste documento ainda não tem um leitor confirmado. Use um layout testado ou solicite ampliação do leitor.';

  @override
  String get pdfImportMismatch =>
      'Os totais do documento não correspondem aos detalhes. A confirmação está bloqueada; confira o original.';

  @override
  String get pdfImportUnknownRow =>
      'Há linha monetária ou data que não pôde ser interpretada com segurança. Confira a página indicada; a confirmação está bloqueada.';

  @override
  String get pdfImportWrongSource =>
      'O tipo do documento não corresponde à conta ou cartão escolhido. Importe novamente com a origem correta.';

  @override
  String get pdfImportLimit =>
      'O PDF ultrapassa os limites de páginas ou conteúdo do leitor. A confirmação está bloqueada.';

  @override
  String get pdfImportHeader =>
      'O cabeçalho, os controles ou os lançamentos estão incompletos ou conflitantes. Confira o original; a confirmação está bloqueada.';

  @override
  String get pdfImportBlockedHelp =>
      'Este documento não pode ser confirmado. Confira os impedimentos e o original.';

  @override
  String get pdfImportSourceExists =>
      'Esta conta já possui uma origem de importação. Atualize a lista e selecione a origem existente.';

  @override
  String get pdfImportInvalidSource =>
      'Confira os dados da origem. O extrato exige uma conta bancária ativa e o leitor atual exige reais.';

  @override
  String get pdfImportUnknownIssue =>
      'A leitura identificou um impedimento. Confira o original e solicite análise do formato.';

  @override
  String get pdfImportUncertain =>
      'A resposta não foi recebida. Consulte os documentos ou repita com o mesmo PDF e a mesma origem para recuperar o resultado.';

  @override
  String get pdfImportNoText => 'Esta página não contém texto extraível.';

  @override
  String get pdfImportDocument => 'Documento financeiro';

  @override
  String get pdfImportSourceRequired =>
      'Selecione a conta ou cartão do documento.';

  @override
  String get pdfImportRequired => 'Preencha de 2 a 100 caracteres.';

  @override
  String get importReviewBank => 'Comparar com registros do aplicativo';

  @override
  String get importReviewBill => 'Revisar fatura';

  @override
  String get importHeaderTitle => 'Conferir dados do documento';

  @override
  String get importHeaderHelp =>
      'Confira os controles disponíveis e complete somente o que faltar, usando o documento ou banco. Valores calculados das linhas não substituem saldos e total declarados.';

  @override
  String get importHeaderSignedMoney =>
      'Informe o valor em reais, com vírgula para centavos. Use sinal negativo somente para crédito a seu favor.';

  @override
  String get importHeaderDateRequired =>
      'Selecione a data declarada no documento.';

  @override
  String get importHeaderMoneyRequired => 'Informe um valor válido em reais.';

  @override
  String get importHeaderPeriodInvalid =>
      'O fim do período deve ser igual ou posterior ao início.';

  @override
  String get importHeaderAck =>
      'Conferi estes dados na fonte; não foram inferidos das transações.';

  @override
  String get importHeaderContinue => 'Usar dados conferidos';

  @override
  String get importOptional => 'Opcional · deixe vazio se não informado';

  @override
  String get importUnclassified => 'Selecionar classificação';

  @override
  String get importClassifyHelp =>
      'Classifique cada linha conforme sua finalidade real. Descrição e sinal não determinam se um gasto pertence à empresa ou ao sócio.';

  @override
  String get importClassifyRequired =>
      'Classifique todas as linhas antes de salvar ou gerar títulos.';

  @override
  String get importExactRequired =>
      'A equação precisa fechar exatamente, sem ajuste de centavos.';

  @override
  String get importAllocationRequired =>
      'Créditos, pagamentos ou saldo anterior ainda precisam ser alocados às obrigações. Nenhum título novo foi criado.';

  @override
  String get importReimportRequired =>
      'O leitor foi atualizado. Reimporte o original para conferir a nova interpretação; o histórico anterior será preservado.';

  @override
  String get importCycleRepresented =>
      'Este ciclo já possui obrigações em outro documento. Confira os vínculos antes de criar títulos.';

  @override
  String get importPurchaseAllocation =>
      'Confira o título e o saldo da compra vinculada. Compras pagas, canceladas ou com parcelas ambíguas exigem alocação específica.';

  @override
  String get importCashReviewRequired =>
      'A criação automática de movimentos pelo extrato foi suspensa. Revise e vincule a movimentos existentes, sem duplicar pagamentos ou recebimentos.';

  @override
  String get importCsvDirection =>
      'Este CSV contém colunas de crédito/débito ou moeda que precisam de mapeamento explícito. A leitura foi bloqueada para não inverter valores.';

  @override
  String get importPdfCompilation =>
      'O PDF reúne referências, resumos ou ciclos diferentes. Separe os documentos originais para evitar misturar compras e faturas.';

  @override
  String get importBankHelp =>
      'Aqui você pode verificar se um movimento deste extrato corresponde a algo já registrado no aplicativo, evitando repetições. Essa comparação não registra pagamentos nem cria contas. É opcional para consultar o arquivo.';

  @override
  String get importBankItem => 'Ver movimento do extrato';

  @override
  String get importReason => 'Motivo da decisão ou correspondência';

  @override
  String get importReasonRequired =>
      'Explique a conferência em pelo menos 3 caracteres.';

  @override
  String get importIgnore => 'Não usar este movimento';

  @override
  String get importNewEvidence => 'Guardar como movimento diferente';

  @override
  String get importNewEvidenceAck =>
      'Conferi os registros e este movimento não é uma repetição.';

  @override
  String get importCandidates =>
      'Possíveis correspondências com outras importações';

  @override
  String get importLinkEvidence => 'Usar um movimento já registrado';

  @override
  String get importChooseCash => 'Movimento financeiro já registrado';

  @override
  String get importReconcile => 'Vincular evidência ao movimento';

  @override
  String get importReconciled =>
      'Correspondência registrada. Nenhum dinheiro foi movimentado.';

  @override
  String get importIgnored => 'Movimento não utilizado';

  @override
  String get importEvidenceReviewed => 'Identidade revisada';

  @override
  String get importEvidencePending => 'Identidade pendente de revisão';

  @override
  String get importNoCash =>
      'Não há registros correspondentes nesta conta do aplicativo. Se precisar registrar um pagamento ou recebimento, use a função correspondente no Financeiro.';

  @override
  String get importRemaining => 'Valor ainda não conciliado';

  @override
  String get importBankPartialHelp =>
      'Informe somente a parcela correspondente a este movimento. O servidor verifica os saldos e a conta antes de salvar.';

  @override
  String get importDecisionSaved => 'Decisão registrada no histórico.';

  @override
  String get importInvalidSign =>
      'A classificação não corresponde ao sinal do valor no documento. Confira pagamento, crédito, compra e encargo.';

  @override
  String get importReviewLatest =>
      'A revisão foi alterada. Atualize e confira a versão vigente.';

  @override
  String get importEvidenceInvalid =>
      'O documento exige conferência ou nova interpretação antes de gerar efeitos financeiros.';

  @override
  String get importPasswordTitle => 'Ler PDF protegido';

  @override
  String get importPasswordLabel => 'Senha do documento';

  @override
  String get importControlMismatch =>
      'Os controles informados não correspondem aos lançamentos. Confira o documento; nenhum ajuste automático será feito.';

  @override
  String get importPreviousBalanceConflict =>
      'O saldo anterior classificado diverge do resumo do documento. Confira sua origem antes de aprovar.';

  @override
  String get importClassification => 'Finalidade do lançamento';

  @override
  String get importReadyReview => 'Leitura pronta para conferência';

  @override
  String get importBillConfirmedReview =>
      'Documento já guardado; veja a situação da fatura';

  @override
  String get importBankConfirmedReview =>
      'Confirmado · revisão e conciliação pendentes';

  @override
  String get importBankIdentitiesReviewed =>
      'Há identidades revisadas · confira a conciliação';

  @override
  String get importBankIdentityNote =>
      'Conferir o movimento do documento não registra pagamento. A comparação abaixo só relaciona registros que já existem no aplicativo.';

  @override
  String get importConfirmReview => 'Confirmar documento e revisar';

  @override
  String get importReassignCard =>
      'Selecione o cartão correspondente ao documento para conferir a nova leitura.';

  @override
  String get importReassignBank =>
      'Selecione a conta bancária correspondente ao documento para conferir a nova leitura.';

  @override
  String get financialDocumentDueReview =>
      'Documento lido · confira o vencimento para continuar';

  @override
  String get financialDocumentPending =>
      'Documento lido · confira as pendências para continuar';

  @override
  String get financialSegmentsTitle => 'Conferir ciclos do documento';

  @override
  String get financialSegmentsHelp =>
      'O documento reúne vários períodos ou tipos. Confira somente os ciclos que deseja usar. Nenhum saldo histórico será considerado aberto automaticamente.';

  @override
  String get financialSegmentReview => 'Conferir este ciclo';

  @override
  String get financialSegmentSaved =>
      'Evidência deste ciclo guardada. A cobrança depende da confirmação do saldo em aberto.';

  @override
  String get financialStatementIndexHelp =>
      'Relação de extratos: conserva as referências dos documentos, sem movimentos ou contas a pagar.';

  @override
  String get financialRenegotiationHelp =>
      'Documento de renegociação: guardado como evidência. Uma oferta não cria dívida ou parcelas automaticamente.';

  @override
  String get financialSummaryOnlyHelp =>
      'Resumo sem compras individuais. Você pode conferir o total e a situação do saldo; os detalhes continuam pendentes.';

  @override
  String get financialCompiledControlsHelp =>
      'Controles de uma compilação fornecida. Confira no documento original; este resumo não comprova todas as compras.';

  @override
  String get financialContentConflict =>
      'Este documento diverge da conferência anterior. Compare os itens abaixo com os novos itens, inclusive repetições, total e vencimento.';

  @override
  String get financialContentChangeAck =>
      'Conferi as diferenças e autorizo esta revisão, preservando a versão anterior.';

  @override
  String get financialControlChoose =>
      'Usar controles de um documento já lido deste cartão. Escolha o ciclo correspondente:';

  @override
  String get financialCreditSaved =>
      'Esta fatura informa crédito no cartão. Ela foi guardada para consulta e não criou uma conta a pagar.';

  @override
  String get payableBankCardFilter => 'Banco ou cartão';

  @override
  String get payableMerchantFilter => 'Estabelecimento da fatura';

  @override
  String get payableToday => 'Hoje';

  @override
  String get payableThisWeek => 'Esta semana';

  @override
  String get payableThisMonth => 'Este mês';

  @override
  String get payableNextMonth => 'Próximo mês';

  @override
  String get payableFilteredSummary => 'Total de todo o filtro';

  @override
  String get payableSummaryUnavailable =>
      'Resumo completo indisponível · valores dos registros carregados';

  @override
  String get financialImportSourceRequiredEmpty =>
      'Cadastre uma conta ou cartão para vincular este documento.';

  @override
  String get financialImportSourceRequired =>
      'Selecione a conta ou cartão deste documento para continuar.';

  @override
  String get financialDueResolutionHelp =>
      'Escolha o vencimento conferido no original. As duas datas e suas páginas permanecerão no histórico.';

  @override
  String get financialContentConflictError =>
      'O documento diverge da revisão anterior. Compare os detalhes e confirme a revisão para continuar.';

  @override
  String get financialReplacementReason =>
      'Vínculo com obrigação existente conferido na importação';

  @override
  String get financialExistingObligations => 'Já existe alguma destas contas?';

  @override
  String get financialExistingObligationsHelp =>
      'Se uma destas contas já representa uma compra desta fatura, selecione-a para evitar cobrar o mesmo gasto duas vezes. Registros e pagamentos anteriores serão preservados.';

  @override
  String get financialPreviousObligation => 'Saldo ou título anterior';

  @override
  String get financialPurchaseObligation => 'Compra já cadastrada';

  @override
  String get financialPurposeOptional => 'Informar finalidade (opcional)';

  @override
  String get financialDocumentReviewAction => 'Conferir documento';

  @override
  String get financialEvidenceOnlySaved =>
      'Evidência guardada para consulta. Nenhuma conta a pagar foi gerada.';

  @override
  String get installmentAgendaTitle => 'Parcelas dos próximos meses';

  @override
  String get installmentEstimated => 'Estimativas livres';

  @override
  String get installmentPending => 'Estimativas aguardando vínculo';

  @override
  String get installmentEstimateHelp =>
      'Previsões separadas das cobranças confirmadas. Não permitem pagamento; valores e dias podem mudar na próxima fatura.';

  @override
  String get installmentOpenAgenda => 'Consultar agenda e vínculos';

  @override
  String get installmentMonthOnly => 'Dia desconhecido · somente mês previsto';

  @override
  String get installmentEstimatedState => 'Prevista';

  @override
  String get installmentPendingState => 'Pendente de vínculo';

  @override
  String get installmentReplacedState => 'Substituída pela cobrança real';

  @override
  String get installmentCanceledState => 'Cancelada com evidência';

  @override
  String get installmentLinkHelp =>
      'Confira a compra de origem, o valor e o vencimento. Semelhança não comprova que seja a mesma série. As séries candidatas ficam fora da soma livre até a decisão.';

  @override
  String get installmentLink => 'Vincular à série';

  @override
  String get installmentDistinct => 'É outra compra';

  @override
  String get installmentReason => 'Motivo e evidência da decisão';

  @override
  String get installmentConfirm => 'Confirmar decisão';

  @override
  String get installmentCancelSeries => 'Registrar cancelamento comprovado';

  @override
  String get installmentCancelHelp =>
      'Use apenas se o documento comprovar quais parcelas foram canceladas. A ausência na fatura não comprova cancelamento. A cobrança atual e os pagamentos permanecem.';

  @override
  String get installmentCancelFrom => 'Primeira parcela futura cancelada';

  @override
  String get installmentCancelEvidence => 'Estorno que comprova o cancelamento';

  @override
  String get installmentRetry => 'Reenviar a mesma decisão';

  @override
  String get installmentDecisionUncertain =>
      'A decisão não foi confirmada nesta tela. Reenvie a mesma tentativa ou atualize para consultar o estado.';

  @override
  String get installmentEmpty => 'Nenhuma previsão neste filtro.';

  @override
  String get installmentConfirmed => 'Decisão registrada. Agenda atualizada.';

  @override
  String get installmentOrigin => 'Item de origem';

  @override
  String get installmentUseDay =>
      'Estimar os próximos vencimentos pelo dia desta fatura';

  @override
  String get installmentUseDayHelp =>
      'O dia será limitado ao fim de cada mês, sem presumir feriados. Desmarque para manter somente o mês previsto.';

  @override
  String get financialPayablesToolsHelp =>
      'Pesquisar banco ou cartão, consultar outros períodos e próximas parcelas.';

  @override
  String get financialReceivablesToolsHelp =>
      'Consultar registros e outros períodos de recebimento.';

  @override
  String get financialReadingDetails => 'Consultar leitura original';

  @override
  String get financialReadSummary => 'O que foi lido';

  @override
  String get financialReviewQuestions => 'O que falta conferir';

  @override
  String get financialDueQuestion => 'Qual é o vencimento correto?';

  @override
  String get financialDueQuestionHelp =>
      'O próprio documento informa datas diferentes. Confira o PDF original e selecione a data correta abaixo. Ler todas as compras não resolve essa dúvida.';

  @override
  String get financialDifferenceHelp =>
      'Os lançamentos foram lidos, mas a soma deles difere do total da fatura. Você pode guardar os detalhes como pendentes e usar o total conferido para registrar a cobrança. A diferença continuará visível.';

  @override
  String get financialDestinationHelp =>
      'Adicionar a Contas a Pagar cria uma conta pelo total da fatura. Guardar deixa o documento só para consulta. Nenhuma dessas ações marca a conta como paga.';

  @override
  String get financialHeaderMissingHelp =>
      'Falta o total ou o vencimento. Informe os dados do original no botão abaixo ou escolha um documento complementar deste mesmo cartão e mês.';

  @override
  String get financialConfirmHelp =>
      'Para confirmar, confira total e vencimento, resolva as perguntas abaixo e marque a conferência final.';

  @override
  String get financialSavedReview =>
      'Esta conferência já está salva. A situação registrada aparece abaixo.';

  @override
  String get financialEditSavedReview => 'Alterar conferência salva';

  @override
  String get financialReadSnapshotHelp =>
      'Esta é a leitura original, preservada para consulta. As decisões atuais ficam em Conferir fatura.';

  @override
  String get financialItemsHelp =>
      'As compras, parcelas e créditos abaixo são detalhes de uma única fatura. Não geram uma conta a pagar por linha. A classificação é opcional.';

  @override
  String get financialPages => 'Páginas';

  @override
  String get financialRecordedResult => 'Resultado registrado';

  @override
  String get financialDueChosen => 'Vencimento escolhido';

  @override
  String get financialDueChosenHelp =>
      'A escolha está feita. Para corrigir, selecione outra data abaixo. As datas e suas páginas serão conservadas no histórico.';

  @override
  String get financialDetailsDecisionHelp =>
      'Se quiser continuar com o total conferido, marque abaixo a opção de manter os detalhes pendentes.';

  @override
  String get financialFinalDecisionHelp =>
      'Confira a situação desta fatura e marque a conferência final abaixo para confirmar.';

  @override
  String financialReadCount(int count) {
    return '$count lançamentos lidos.';
  }

  @override
  String get financialImportHowItWorks => 'Como funciona a importação';

  @override
  String get financialAddSavedBill => 'Adicionar esta fatura a Contas a Pagar';

  @override
  String get financialPendingSaved =>
      'Documento guardado. Você ainda não escolheu adicioná-lo a Contas a Pagar.';

  @override
  String get financialRestoredReview =>
      'Você importou este arquivo novamente. Confira os dados e salve para incluí-lo no financeiro outra vez.';

  @override
  String get financialOpenDocument => 'Ver documento';

  @override
  String get financialOtherDocumentOptions => 'Outras opções deste documento';

  @override
  String get financialLegacyOptionsHelp =>
      'Estes acessos conservam registros feitos no fluxo anterior. Para consultar ou importar uma fatura, use Ver documento.';

  @override
  String get financialBankDocumentHelp =>
      'Este arquivo é um extrato de conta bancária, com entradas e saídas. Ele não é uma fatura de cartão e não cria uma conta a pagar. A comparação com registros existentes abaixo é opcional.';

  @override
  String financialImportSourceMismatch(String documentType, String sourceType) {
    return 'Origem incompatível ($documentType vs $sourceType)';
  }

  @override
  String get financialImportOpenPayables => 'Abrir Contas a Pagar';

  @override
  String get importRemovalTitle => 'Excluir importação';

  @override
  String get importRemovalHelp =>
      'Esta importação sairá da lista. As contas a pagar e previsões criadas por ela serão retiradas. Compras, pagamentos e registros independentes serão preservados.';

  @override
  String get importRemovalConfirm => 'Excluir esta importação';

  @override
  String get importRemovalRetry => 'Retomar exclusão';

  @override
  String get importRemovalNoBills => 'Este documento não criou contas a pagar.';

  @override
  String get importRemovalBills => 'Contas a pagar que serão retiradas';

  @override
  String get importRemovalForecasts =>
      'As próximas parcelas desta importação também sairão da agenda.';

  @override
  String get importRemovalBlocked => 'Resolva o item indicado antes de excluir';

  @override
  String get importRemovalOpenPayable => 'Ver conta e pagamentos';

  @override
  String get importRemovalOtherDocument => 'Ver importação relacionada';

  @override
  String get importRemovalDone => 'Importação excluída.';

  @override
  String get importRemovalChanged =>
      'Esta importação mudou. Atualize a conferência da exclusão antes de continuar.';

  @override
  String get importRemovalRemoved =>
      'Esta importação foi excluída. Se quiser usá-la novamente, selecione o arquivo e importe outra vez.';

  @override
  String get importRemovalBlockedError =>
      'A importação ainda tem pagamento ou vínculo com outro registro. Abra Excluir importação para ver o motivo e a ação disponível.';

  @override
  String get financialRegisteredBill => 'Fatura em Contas a Pagar';

  @override
  String financialBillOpenObligations(int count) {
    return 'Obrigações abertas: $count';
  }

  @override
  String get financialSavedOnly =>
      'Guardado para consulta; ainda não está em Contas a Pagar';

  @override
  String get financialStatementSaved => 'Extrato guardado para consulta';

  @override
  String get financialReadProblem =>
      'Não foi possível concluir a leitura deste arquivo';

  @override
  String get financialReadProblemHelp =>
      'Veja o motivo abaixo. Você pode voltar à lista e excluir esta importação se escolheu o arquivo errado.';

  @override
  String get importRemovalRestoreBills =>
      'Estas contas voltam a aparecer separadamente, com seus pagamentos preservados';

  @override
  String get catalogResolveLinks =>
      'Estes registros impedem a operação. Toque para conferir e resolver.';

  @override
  String get catalogViewReceipts => 'Ver recebimentos desta venda';

  @override
  String get catalogReceiptHelp =>
      'Há recebimentos nesta venda. Confira e estorne os recebimentos antes de cancelar.';

  @override
  String get catalogDelete => 'Excluir do catálogo';

  @override
  String get catalogDeleteConfirm =>
      'Excluir este cadastro? Ele sairá do catálogo; operações anteriores continuarão disponíveis no histórico.';

  @override
  String get catalogDeleted => 'Cadastro excluído do catálogo.';

  @override
  String get catalogRecipePrice => 'Preço sugerido (R\$)';

  @override
  String get catalogRecipePriceHelp =>
      'Opcional. Sem valor, usa o preço padrão do tipo de cesta. Na venda você pode negociar outro preço.';

  @override
  String get catalogEditRecipe => 'Editar receita';

  @override
  String get catalogDeleteRecipe => 'Excluir receita';

  @override
  String get catalogActivateRecipe =>
      'Usar esta receita nas próximas montagens';

  @override
  String get catalogDeactivateRecipe => 'Inativar receita';

  @override
  String get catalogRecipeProtected =>
      'Esta receita está ligada aos registros abaixo. Para mudar a composição agora, crie outra receita no mesmo tipo de cesta.';

  @override
  String get catalogDisassemble => 'Desmontar cestas';

  @override
  String get catalogDisassemblyHelp =>
      'Informe quantas cestas serão desmontadas. Os produtos da composição original voltarão ao estoque e as cestas prontas serão retiradas do saldo.';

  @override
  String get catalogDisassemblyQuantity => 'Quantidade de cestas a desmontar';

  @override
  String get catalogDisassemblyIntact =>
      'Confirmei que todos os produtos estão intactos e voltarão ao estoque.';

  @override
  String get catalogDisassemblyReason => 'Motivo da desmontagem';

  @override
  String get catalogDisassemblyDone =>
      'Cestas desmontadas. Produtos devolvidos ao estoque.';

  @override
  String get catalogRetryAction => 'Retomar confirmação pendente';

  @override
  String get catalogInvalidQuantity =>
      'Informe uma quantidade válida e confirme a devolução dos produtos intactos.';

  @override
  String get catalogReviewDisassembly => 'Revisar desmontagem';

  @override
  String get catalogDisassemblyReturns => 'Produtos que voltarão ao estoque';

  @override
  String get catalogReasonRequired =>
      'Informe um motivo com pelo menos 3 caracteres.';

  @override
  String get catalogInvalidPrice =>
      'Informe um preço válido, igual ou maior que zero.';

  @override
  String get catalogRestoreRecipeDraft => 'Rever dados da receita';

  @override
  String get catalogInactiveIngredient => 'Produto inativo';

  @override
  String get catalogInactiveRecipeHelp =>
      'Substitua ou remova os produtos inativos indicados antes de salvar. Nenhum ingrediente foi removido automaticamente.';

  @override
  String get financialImportReadersQueryFailed =>
      'Não foi possível consultar os formatos de leitura. A seleção anterior foi mantida.';

  @override
  String get financialImportStatementsQueryFailed =>
      'Não foi possível atualizar os documentos confirmados. Os dados da consulta anterior foram mantidos.';

  @override
  String get financialImportObligationsQueryFailed =>
      'Não foi possível atualizar as contas de um documento. Isso não significa que ele esteja sem contas ou pago.';

  @override
  String get financialImportRefreshQuery => 'Atualizar consulta';

  @override
  String get financialImportUpdateRead => 'Atualizar leitura';

  @override
  String get financialImportLegacyReadHelp =>
      'Este documento usa uma leitura anterior. Você pode abri-lo para consultar o que já foi guardado. Para usar a conferência atual, escolha Atualizar leitura. A atualização precisa preservar as informações já confirmadas.';

  @override
  String get financialImportPendingNoAccount =>
      'Conferência pendente. A leitura deste arquivo foi guardada; nenhuma conta foi criada nesta importação. Abra o documento para conferir e escolher como salvar.';

  @override
  String get financialImportPartialStatus =>
      'A situação das contas precisa de nova consulta. Use Atualizar consulta antes de concluir que não há valores em aberto.';

  @override
  String get financialImportGenerationConflict =>
      'Esta conferência pertence a uma importação que foi retirada ou alterada. Volte à lista de documentos e use Atualizar para abrir a entrada atual. Esta tentativa não gravou novas alterações.';

  @override
  String get financialImportAlreadyActive =>
      'Este arquivo já tem uma importação em andamento. Volte à lista, atualize os documentos e abra a entrada existente para continuar a conferência.';

  @override
  String get financialImportConfirmedRead =>
      'Esta importação já tem informações confirmadas. Abra o documento existente para conferir o que foi salvo; trocar a leitura não pode substituir essas informações automaticamente.';

  @override
  String get financialImportLegacyReviewRequired =>
      'Há registros antigos cuja relação com esta importação precisa ser conferida. A alteração foi bloqueada para preservar contas e pagamentos. A correção precisa de revisão dos registros pelo suporte.';

  @override
  String get financialImportReinstatementConflict =>
      'Uma conta ou vínculo mudou desde a retirada desta importação. A restauração foi bloqueada para preservar essa mudança. Atualize a conferência e consulte os registros indicados antes de tentar novamente.';
}
