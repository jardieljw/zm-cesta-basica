// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get commonFilter => 'Filtrar';

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
  String get commonNo => 'Não';

  @override
  String get commonSuccess => 'Operação realizada com sucesso';

  @override
  String get commonError => 'Ocorreu um erro';

  @override
  String get commonWarning => 'Atenção';

  @override
  String get commonUnit => 'un';

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
  String get productCostPrice => 'Preço de Custo';

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
  String get recipesTitle => 'Ficha Técnica / Receita';

  @override
  String get recipeVersionLabel => 'Versão da Receita';

  @override
  String get recipeAddIngredient => 'Adicionar Insumo';

  @override
  String get recipeQuantityPerBasket => 'Quantidade por Cesta';

  @override
  String get recipeSection => 'Seção do Insumo';

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
  String get productionBatchNew => 'Nova Montagem de Cestas';

  @override
  String productionBatchNumber(int number) {
    return 'Lote #$number';
  }

  @override
  String get productionQuantityProduced => 'Qtd. Produzida';

  @override
  String get productionQuantityDisassembled => 'Qtd. Desmontada';

  @override
  String get productionCurrentStock => 'Saldo em Estoque';

  @override
  String get productionUnitCost => 'Custo Unitário';

  @override
  String get productionTotalCost => 'Custo Total do Lote';

  @override
  String get productionStatusConfirmed => 'Confirmado';

  @override
  String get productionStatusDisassembled => 'Desmontado';

  @override
  String get productionStatusCanceled => 'Cancelado';

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
  String get productionDisassembleReasonHint =>
      'Ex: Avaria em embalagem, readequação';

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
  String get productionLossReasonLabel => 'Motivo da Perda';

  @override
  String get productionDisassembleDescription =>
      'A desmontagem realiza triagem física: itens intactos retornam ao estoque e avarias são registradas como perda sem inflar o estoque fisicamente.';

  @override
  String get productionDisassembledSuccess => 'Lote desmontado com sucesso!';

  @override
  String get productionBatchSearchHint =>
      'Buscar por lote (#1), tipo ou observações...';

  @override
  String get productionBatchFilterAllStatus => 'Todos os Status';

  @override
  String get productionBatchFilterConfirmed => 'Confirmados';

  @override
  String get productionBatchFilterDisassembled => 'Desmontados';

  @override
  String get productionBatchFilterAllTypes => 'Todos os Tipos';

  @override
  String get productionBatchFilterStandard => 'Cesta Padrão';

  @override
  String get productionBatchFilterCustom => 'Personalizada';

  @override
  String get productionBatchEmpty => 'Nenhum lote de produção encontrado.';

  @override
  String get productionBatchMountFirst => 'Montar Primeira Cesta';

  @override
  String productionBatchCancelTitle(int number) {
    return 'Estorno Total do Lote #$number';
  }

  @override
  String get productionBatchCancelDescription =>
      'Esta operação cancela a ordem de produção, deduz o saldo das cestas acabadas e retorna 100% dos insumos consumidos ao estoque fisicamente.\\n\\nRequer que todas as cestas acabadas estejam disponíveis em estoque.';

  @override
  String get productionBatchCancelReasonLabel => 'Motivo do Estorno';

  @override
  String get productionBatchCancelReasonHint =>
      'Ex: Ordem gerada em duplicidade';

  @override
  String get productionBatchCancelConfirm => 'Confirmar Estorno';

  @override
  String get productionBatchCancelSuccess => 'Lote estornado com sucesso!';

  @override
  String get productionBatchSnapshotTitle =>
      'Snapshot Imutável de Insumos Consumidos';

  @override
  String productionBatchSectionLabel(String section, String cost) {
    return 'Seção: $section | Custo un: $cost';
  }

  @override
  String productionBatchTotalItemCost(String cost) {
    return 'Total: $cost';
  }

  @override
  String get productionBatchDisassembleButton => 'Desmontar Lote';

  @override
  String get productionBatchCancelButton => 'Estorno Total';

  @override
  String get productionBatchDetailProduced => 'Quantidade Produzida';

  @override
  String get productionBatchDetailStock => 'Saldo Disponível';

  @override
  String get productionBatchDetailDisassembled => 'Quantidade Desmontada';

  @override
  String get productionBatchDetailUnitCost => 'Custo Unitário';

  @override
  String get productionBatchDetailTotalCost => 'Custo Total';

  @override
  String productionBatchDetailDate(String date) {
    return 'Data: $date';
  }

  @override
  String productionBatchDetailNotes(String notes) {
    return 'Observações: $notes';
  }

  @override
  String productionBatchDetailDisassembledAt(String date, String reason) {
    return 'Desmontado em: $date ($reason)';
  }

  @override
  String productionBatchDescriptionLabel(String description) {
    return 'Descrição: $description';
  }

  @override
  String productionBatchConsumedTotal(String quantity) {
    return 'Consumido total: $quantity';
  }

  @override
  String get validationInvalid => 'Inválido';

  @override
  String validationMinChars(int min) {
    return 'Mínimo de $min caracteres';
  }

  @override
  String get validationMustBePositive =>
      'A quantidade a desmontar deve ser maior que zero.';

  @override
  String validationInsufficientStockForDisassembly(int max) {
    return 'Saldo insuficiente para desmontagem: máximo permitido é de $max unidade(s).';
  }

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
  String get homePhase4Header => 'Produção e Desmontagem';

  @override
  String get homeProductionBatchesDescription =>
      'Histórico de ordens, desmontagem com triagem e estorno total.';

  @override
  String get homeProductionAssemblyDescription =>
      'Simulação de viabilidade com CMPM e baixa atômica.';

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
    return 'Deseja inativar o produto \"$name\"?\n\nA exclusão física é proibida para preservar a integridade das transações anteriores. O produto deixará de aparecer em novas composições.';
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
    return 'Embalagens ($count)';
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
  String get packagingsTitle => 'Embalagens Comerciais';

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
    return 'Quantidade na Unidade Base * ($unit)';
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
  String get basketTypeFormTracksStock => 'Controla Estoque de Cesta Acabada';

  @override
  String get basketTypeFormTracksStockSubtitle =>
      'Mantém saldo da cesta como produto acabado no inventário.';

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
      'Versionamento Imutável: As receitas gravadas nunca são sobrescritas. Para alterar componentes, clique em \"Nova Versão\". Montagens antigas mantêm fidelidade exata à composição da época.';

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
      'Ao salvar, a composição atual será arquivada permanentemente e uma nova versão ativa será criada.';

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
  String get purchaseFormPackagingLabel => 'Embalagem';

  @override
  String purchaseFormBaseUnitPackaging(String unit) {
    return 'Unidade Base ($unit)';
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
  String get assemblyHeaderTitle => 'Montagem de Cestas (Ordem de Produção)';

  @override
  String get assemblyTabStandard => 'Cesta Padrão';

  @override
  String get assemblyTabCustom => 'Cesta Personalizada';

  @override
  String get assemblyStandardBasketLabel => 'Tipo de Cesta *';

  @override
  String get assemblyStandardQtyLabel => 'Quantidade a Montar *';

  @override
  String get assemblyStandardQtyValidation =>
      'Informe uma quantidade válida maior que zero';

  @override
  String get assemblyStandardDirectSale =>
      'Venda Direta (Não adiciona ao estoque acabado)';

  @override
  String get assemblyStandardDirectSaleSubtitle =>
      'Baixa os insumos consumidos sem criar saldo da cesta montada no inventário.';

  @override
  String get assemblyStandardNotesLabel => 'Observações da Ordem';

  @override
  String get assemblyStandardNotesHint => 'Ex: Pedido especial cliente XPTO';

  @override
  String get assemblyFeasibilityTitle =>
      'Simulação de Viabilidade e Custo Médio (CMPM)';

  @override
  String get assemblyFeasibleOk => 'Estoque Suficiente para Montagem';

  @override
  String get assemblyFeasibleFail => 'Estoque Insuficiente para Montagem';

  @override
  String assemblyTotalCostPreview(String cost) {
    return 'Custo Total do Lote: $cost';
  }

  @override
  String assemblyUnitCostPreview(String cost) {
    return 'Custo Unitário da Cesta: $cost';
  }

  @override
  String get assemblyConfirmDialogTitle => 'Confirmar Montagem de Cestas';

  @override
  String assemblyConfirmDialogContent(int qty, String name) {
    return 'Deseja confirmar a montagem de $qty cesta(s) \"$name\"?\n\nOs insumos serão baixados e o lote de cestas acabadas será adicionado ao estoque imediatamente.';
  }

  @override
  String assemblyConfirmSuccess(int number, String cost) {
    return 'Lote #$number montado com sucesso! Custo unitário: $cost';
  }

  @override
  String get assemblySubmitStandard => 'Confirmar Montagem da Cesta Padrão';

  @override
  String get assemblySubmitCustom =>
      'Confirmar Montagem da Cesta Personalizada';

  @override
  String get assemblyCustomBaseBasket => 'Modelo Base da Cesta';

  @override
  String get assemblyCustomDescLabel => 'Descrição da Cesta Personalizada *';

  @override
  String get assemblyCustomDescHint =>
      'Ex: Cesta Natalina Especial para Empresa Alpha';

  @override
  String get assemblyCustomDescRequired =>
      'Informe a descrição da cesta personalizada';

  @override
  String assemblyCustomItemsHeader(int count) {
    return 'Composição Customizada de Insumos ($count)';
  }

  @override
  String get assemblyCustomAddItem => 'Adicionar Insumo';

  @override
  String get assemblyCustomQtyValidation => 'Quantidade inválida';

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
  String get categoryHygiene => 'Higiene';

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
  String get productionDisassemble => 'Desmontar';

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
  String get saleAssemblyModeStock => 'Estoque Acabado';

  @override
  String get saleAssemblyModeDemand => 'Montar Imediatamente';

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
    return 'Deseja realmente estornar a venda #$number?';
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
    return 'Saldo disponível: $qty';
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
}
